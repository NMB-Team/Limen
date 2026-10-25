#define HL_NAME(n) limen_fsr_##n
#include <hl.h>
#undef _GUID

#include <windows.h>
#include <d3d12.h>
#include <cstdio>
#include <cstring>
#include <string>
#include <mutex>
#include <dxgi1_6.h>
#include "native_window.h"
#include <ffx_provider_fsr3framegeneration.h>
#include <ffx_provider_fsr3framegenerationswapchain.h>
#include <ffx_framegeneration.h>
#include <dx12/ffx_api_framegeneration_dx12.h>
#include <ffx_antilag2_dx12.h>

#include <ffx_provider_fsr3upscale.h>
#include <ffx_message.h>

#include <ffx_api.h>
#include <ffx_api_types.h>
#include <dx12/ffx_api_dx12.h>
#include <ffx_upscale.h>

#define _DEVICE _ABSTRACT(dx_device)
#define _RES _ABSTRACT(dx_resource)
#define _CONTEXT _ABSTRACT(fsr_context)
#define _SWAPCHAIN _ABSTRACT(dx_swapchain)
#define _WINDOW _ABSTRACT(limen_window)
#define _FACTORY _ABSTRACT(dx_factory)

#define FSR_ERROR_NOT_LOADED -1
#define FSR_ERROR_NOT_CREATED -2
#define FSR_ERROR_INVALID_STATE -3

#define CHECK_FFX_LOADED() \
	if (!ffxInitialized) return FSR_ERROR_NOT_LOADED

static bool ffxInitialized = false;
static uint32_t ffxDebugLevel = FFX_API_CONFIGURE_GLOBALDEBUG_LEVEL_ERRORS;
static int liveContexts = 0;
static std::mutex fgMutex;

namespace ffxFuncs {
static ffxReturnCode_t CreateContext(ffxContext* context, ffxCreateContextDescHeader* desc, const ffxAllocationCallbacks*) {
	Allocator alloc{nullptr};
	ffxProvider* provider = nullptr;
	if (ffxProvider_Fsr3FrameGeneration::GetInstance().CanProvide(desc->type))
		provider = &ffxProvider_Fsr3FrameGeneration::GetInstance();
	else if (ffxProvider_Fsr3FrameGenerationSwapChain::GetInstance().CanProvide(desc->type))
		provider = &ffxProvider_Fsr3FrameGenerationSwapChain::GetInstance();
	if (provider == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;
	return provider->CreateContext(context, desc, alloc);
}
static ffxReturnCode_t DestroyContext(ffxContext* context, const ffxAllocationCallbacks*) {
	Allocator alloc{nullptr};
	return GetAssociatedProvider(*context)->DestroyContext(context, alloc);
}
static ffxReturnCode_t Configure(ffxContext* context, const ffxConfigureDescHeader* desc) {
	return GetAssociatedProvider(*context)->Configure(context, desc);
}
static ffxReturnCode_t Query(ffxContext* context, ffxQueryDescHeader* desc) {
	return GetAssociatedProvider(*context)->Query(context, desc);
}
static ffxReturnCode_t Dispatch(ffxContext* context, const ffxDispatchDescHeader* desc) {
	return GetAssociatedProvider(*context)->Dispatch(context, desc);
}
}


static void onFfxMessage(uint32_t type, const wchar_t* message) {
	int len = WideCharToMultiByte(CP_UTF8, 0, message, -1, nullptr, 0, nullptr, nullptr);
	if (len <= 0)
		return;

	std::string utf8(len, '\0');
	WideCharToMultiByte(CP_UTF8, 0, message, -1, utf8.data(), len, nullptr, nullptr);
	printf("[FSR] %s: %s\n", type == FFX_API_MESSAGE_TYPE_ERROR ? "error" : "warning", utf8.c_str());
	fflush(stdout);
}

static ffxCreateBackendDX12Desc makeBackendDesc(ID3D12Device* device) {
	ffxCreateBackendDX12Desc backendDesc{};
	backendDesc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_BACKEND_DX12;
	backendDesc.device = device;
	return backendDesc;
}

HL_PRIM int HL_NAME(init)(ID3D12Device* device, int debugLevel) {
	if (device == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;
	ffxDebugLevel = (uint32_t)debugLevel;
	ffxSetPrintMessageCallback(onFfxMessage, ffxDebugLevel);
	ffxInitialized = true;
	return FFX_API_RETURN_OK;
}

HL_PRIM int HL_NAME(shutdown)() {
	if (liveContexts > 0)
		return FFX_API_RETURN_ERROR;
	ffxSetPrintMessageCallback(nullptr, FFX_API_CONFIGURE_GLOBALDEBUG_LEVEL_SILENCE);
	ffxInitialized = false;
	return FFX_API_RETURN_OK;
}

HL_PRIM int HL_NAME(get_render_resolution)(ID3D12Device* device, int quality, int displayWidth, int displayHeight, int* outRenderWidth, int* outRenderHeight) {
	CHECK_FFX_LOADED();

	if (device == nullptr || outRenderWidth == nullptr || outRenderHeight == nullptr
		|| displayWidth <= 0 || displayHeight <= 0 || quality < 0 || quality > 4)
		return FFX_API_RETURN_ERROR_PARAMETER;

	uint32_t renderWidth = 0;
	uint32_t renderHeight = 0;

	ffxCreateBackendDX12Desc backendDesc = makeBackendDesc(device);

	ffxQueryDescUpscaleGetRenderResolutionFromQualityMode desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_UPSCALE_GETRENDERRESOLUTIONFROMQUALITYMODE;
	desc.header.pNext = &backendDesc.header;
	desc.displayWidth = (uint32_t)displayWidth;
	desc.displayHeight = (uint32_t)displayHeight;
	desc.qualityMode = (uint32_t)quality;
	desc.pOutRenderWidth = &renderWidth;
	desc.pOutRenderHeight = &renderHeight;

	ffxReturnCode_t res = ffxProvider_FSR3Upscale::GetInstance().Query(nullptr, &desc.header);
	*outRenderWidth = (int)renderWidth;
	*outRenderHeight = (int)renderHeight;
	return (int)res;
}

HL_PRIM ffxContext HL_NAME(create_context)(ID3D12Device* device, int flags, int maxRenderWidth, int maxRenderHeight, int maxUpscaleWidth, int maxUpscaleHeight, int* outResult) {
	if (outResult == nullptr)
		return nullptr;
	if (!ffxInitialized) {
		*outResult = FSR_ERROR_NOT_LOADED;
		return nullptr;
	}

	if (device == nullptr || maxRenderWidth <= 0 || maxRenderHeight <= 0
		|| maxUpscaleWidth <= 0 || maxUpscaleHeight <= 0 || (flags & ~1023) != 0) {
		*outResult = FFX_API_RETURN_ERROR_PARAMETER;
		return nullptr;
	}

	ffxCreateBackendDX12Desc backendDesc = makeBackendDesc(device);

	ffxCreateContextDescUpscaleVersion versionDesc{};
	versionDesc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE_VERSION;
	versionDesc.header.pNext = &backendDesc.header;
	versionDesc.version = FFX_UPSCALER_VERSION;

	ffxCreateContextDescUpscale desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE;
	desc.header.pNext = &versionDesc.header;
	desc.flags = (uint32_t)flags;
	desc.maxRenderSize = { (uint32_t)maxRenderWidth, (uint32_t)maxRenderHeight };
	desc.maxUpscaleSize = { (uint32_t)maxUpscaleWidth, (uint32_t)maxUpscaleHeight };
	desc.fpMessage = onFfxMessage;

	Allocator alloc{nullptr};
	ffxContext context = nullptr;
	ffxReturnCode_t res = ffxProvider_FSR3Upscale::GetInstance().CreateContext(&context, &desc.header, alloc);
	*outResult = (int)res;
	if (res != FFX_API_RETURN_OK)
		return nullptr;

	ffxConfigureDescGlobalDebug1 debugDesc{};
	debugDesc.header.type = FFX_API_CONFIGURE_DESC_TYPE_GLOBALDEBUG1;
	debugDesc.fpMessage = onFfxMessage;
	debugDesc.debugLevel = ffxDebugLevel;
	res = ffxProvider_FSR3Upscale::GetInstance().Configure(&context, &debugDesc.header);
	if (res != FFX_API_RETURN_OK) {
		GetAssociatedProvider(context)->DestroyContext(&context, alloc);
		*outResult = (int)res;
		return nullptr;
	}

	liveContexts++;
	return context;
}

HL_PRIM int HL_NAME(destroy_context)(ffxContext context) {
	std::lock_guard<std::mutex> lock(fgMutex);
	CHECK_FFX_LOADED();
	if (context == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;

	Allocator alloc{nullptr};
	ffxReturnCode_t res = GetAssociatedProvider(context)->DestroyContext(&context, alloc);
	if (res == FFX_API_RETURN_OK)
		liveContexts--;
	return (int)res;
}

HL_PRIM vbyte* HL_NAME(get_version_name)(ffxContext context) {
	if (!ffxInitialized || context == nullptr)
		return nullptr;

	const char* name = GetAssociatedProvider(context)->GetVersionName();
	return hl_copy_bytes((const vbyte*)name, (int)strlen(name) + 1);
}

struct FsrDispatchParams {
	ID3D12Resource* color;
	ID3D12Resource* depth;
	ID3D12Resource* motionVectors;
	ID3D12Resource* exposure;
	ID3D12Resource* reactive;
	ID3D12Resource* transparencyAndComposition;
	ID3D12Resource* output;
	D3D12_RESOURCE_STATES colorState;
	D3D12_RESOURCE_STATES depthState;
	D3D12_RESOURCE_STATES motionVectorsState;
	D3D12_RESOURCE_STATES exposureState;
	D3D12_RESOURCE_STATES reactiveState;
	D3D12_RESOURCE_STATES transparencyAndCompositionState;
	D3D12_RESOURCE_STATES outputState;
	float jitterOffsetX;
	float jitterOffsetY;
	float motionVectorScaleX;
	float motionVectorScaleY;
	int renderWidth;
	int renderHeight;
	int upscaleWidth;
	int upscaleHeight;
	float sharpness;
	float frameTimeDelta;
	float preExposure;
	float cameraNear;
	float cameraFar;
	float cameraFovAngleVertical;
	float viewSpaceToMetersFactor;
	int flags;
	bool enableSharpening;
	bool reset;
};

static uint32_t toFfxState(D3D12_RESOURCE_STATES state) {
	switch (state) {
	case D3D12_RESOURCE_STATE_COMMON: return FFX_API_RESOURCE_STATE_COMMON;
	case D3D12_RESOURCE_STATE_UNORDERED_ACCESS: return FFX_API_RESOURCE_STATE_UNORDERED_ACCESS;
	case D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE: return FFX_API_RESOURCE_STATE_COMPUTE_READ;
	case D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE: return FFX_API_RESOURCE_STATE_PIXEL_READ;
	case D3D12_RESOURCE_STATE_ALL_SHADER_RESOURCE: return FFX_API_RESOURCE_STATE_PIXEL_COMPUTE_READ;
	case D3D12_RESOURCE_STATE_COPY_SOURCE: return FFX_API_RESOURCE_STATE_COPY_SRC;
	case D3D12_RESOURCE_STATE_COPY_DEST: return FFX_API_RESOURCE_STATE_COPY_DEST;
	case D3D12_RESOURCE_STATE_GENERIC_READ: return FFX_API_RESOURCE_STATE_GENERIC_READ;
	case D3D12_RESOURCE_STATE_RENDER_TARGET: return FFX_API_RESOURCE_STATE_RENDER_TARGET;
	case D3D12_RESOURCE_STATE_DEPTH_WRITE: return FFX_API_RESOURCE_STATE_DEPTH_ATTACHMENT;
	default: return 0;
	}
}

static bool toFfxResource(ID3D12Resource* res, D3D12_RESOURCE_STATES state, FfxApiResource& out) {
	if (res == nullptr) {
		out = ffxApiGetResourceDX12(nullptr);
		return true;
	}

	uint32_t ffxState = toFfxState(state);
	if (ffxState == 0) {
		printf("[FSR] error: unsupported resource state 0x%x\n", (unsigned int)state);
		fflush(stdout);
		return false;
	}

	out = ffxApiGetResourceDX12(res, ffxState);
	return true;
}

HL_PRIM int HL_NAME(dispatch)(ffxContext context, ID3D12GraphicsCommandList* cmdList, FsrDispatchParams* params) {
	CHECK_FFX_LOADED();
	if (context == nullptr || cmdList == nullptr || params == nullptr
		|| params->color == nullptr || params->depth == nullptr || params->motionVectors == nullptr || params->output == nullptr
		|| params->renderWidth <= 0 || params->renderHeight <= 0 || params->upscaleWidth <= 0 || params->upscaleHeight <= 0
		|| (params->flags & ~7) != 0)
		return FFX_API_RETURN_ERROR_PARAMETER;

	ffxDispatchDescUpscale desc{};
	desc.header.type = FFX_API_DISPATCH_DESC_TYPE_UPSCALE;
	desc.commandList = cmdList;

	if (!toFfxResource(params->color, params->colorState, desc.color)
		|| !toFfxResource(params->depth, params->depthState, desc.depth)
		|| !toFfxResource(params->motionVectors, params->motionVectorsState, desc.motionVectors)
		|| !toFfxResource(params->exposure, params->exposureState, desc.exposure)
		|| !toFfxResource(params->reactive, params->reactiveState, desc.reactive)
		|| !toFfxResource(params->transparencyAndComposition, params->transparencyAndCompositionState, desc.transparencyAndComposition)
		|| !toFfxResource(params->output, params->outputState, desc.output))
		return FFX_API_RETURN_ERROR_PARAMETER;

	desc.jitterOffset = { params->jitterOffsetX, params->jitterOffsetY };
	desc.motionVectorScale = { params->motionVectorScaleX, params->motionVectorScaleY };
	desc.renderSize = { (uint32_t)params->renderWidth, (uint32_t)params->renderHeight };
	desc.upscaleSize = { (uint32_t)params->upscaleWidth, (uint32_t)params->upscaleHeight };
	desc.enableSharpening = params->enableSharpening;
	desc.sharpness = params->sharpness;
	desc.frameTimeDelta = params->frameTimeDelta;
	desc.preExposure = params->preExposure;
	desc.reset = params->reset;
	desc.cameraNear = params->cameraNear;
	desc.cameraFar = params->cameraFar;
	desc.cameraFovAngleVertical = params->cameraFovAngleVertical;
	desc.viewSpaceToMetersFactor = params->viewSpaceToMetersFactor;
	desc.flags = (uint32_t)params->flags;

	return (int)ffxProvider_FSR3Upscale::GetInstance().Dispatch(&context, &desc.header);
}

static ffxProvider* effectProvider(int effect) {
	switch (effect) {
	case 0: return &ffxProvider_FSR3Upscale::GetInstance();
	case 1: return &ffxProvider_Fsr3FrameGeneration::GetInstance();
	default: return nullptr;
	}
}

HL_PRIM int HL_NAME(get_effect_version_count)(ID3D12Device* device, int effect, int* outCount) {
	if (outCount == nullptr) return FFX_API_RETURN_ERROR_PARAMETER;
	*outCount = 0;
	CHECK_FFX_LOADED();
	auto provider = effectProvider(effect);
	if (device == nullptr || provider == nullptr) return FFX_API_RETURN_ERROR_PARAMETER;
	*outCount = provider->IsSupported(device) ? 1 : 0;
	return FFX_API_RETURN_OK;
}

HL_PRIM vbyte* HL_NAME(get_effect_version_name)(ID3D12Device* device, int effect, int index) {
	int count = 0;
	if (HL_NAME(get_effect_version_count)(device, effect, &count) != FFX_API_RETURN_OK || index != 0 || count == 0)
		return nullptr;
	const char* name = effectProvider(effect)->GetVersionName();
	return hl_copy_bytes((const vbyte*)name, (int)strlen(name) + 1);
}

static ffxContext swapChainContext = nullptr;
static IDXGISwapChain4* swapChainProxy = nullptr;

HL_PRIM IDXGISwapChain4* HL_NAME(create_swap_chain)(void* platformWindow, IDXGIFactory* factory, ID3D12CommandQueue* queue, int width, int height, int bufferCount, DXGI_FORMAT format, int* outResult) {
	if (outResult == nullptr)
		return nullptr;
	limen_native_window native{};
	HWND window = limen_get_native_window(platformWindow, &native) && native.type == LIMEN_NATIVE_WIN32 ? (HWND)native.win32.window : nullptr;
	if (window == nullptr || factory == nullptr || queue == nullptr || width <= 0 || height <= 0 || bufferCount < 2) {
		*outResult = FFX_API_RETURN_ERROR_PARAMETER;
		return nullptr;
	}
	if (!ffxInitialized) {
		*outResult = FSR_ERROR_NOT_LOADED;
		return nullptr;
	}
	if (swapChainContext != nullptr || swapChainProxy != nullptr) {
		*outResult = FSR_ERROR_INVALID_STATE;
		return nullptr;
	}

	DXGI_SWAP_CHAIN_DESC1 swapChainDesc{};
	swapChainDesc.Width = (UINT)width;
	swapChainDesc.Height = (UINT)height;
	swapChainDesc.Format = format;
	swapChainDesc.BufferCount = (UINT)bufferCount;
	swapChainDesc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
	swapChainDesc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
	swapChainDesc.SampleDesc.Count = 1;
	swapChainDesc.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_TEARING;

	IDXGISwapChain4* swapChain = nullptr;

	ffxCreateContextDescFrameGenerationSwapChainVersionDX12 versionDesc{};
	versionDesc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_VERSION_DX12;
	versionDesc.version = FFX_FRAMEGENERATION_SWAPCHAIN_DX12_VERSION;

	ffxCreateContextDescFrameGenerationSwapChainForHwndDX12 desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_FOR_HWND_DX12;
	desc.header.pNext = &versionDesc.header;
	desc.swapchain = &swapChain;
	desc.hwnd = window;
	desc.desc = &swapChainDesc;
	desc.fullscreenDesc = nullptr;
	desc.dxgiFactory = factory;
	desc.gameQueue = queue;

	ffxContext context = nullptr;
	ffxReturnCode_t res = ffxFuncs::CreateContext(&context, &desc.header, nullptr);
	if (res != FFX_API_RETURN_OK || swapChain == nullptr) {
		if (context != nullptr)
			ffxFuncs::DestroyContext(&context, nullptr);
		if (swapChain != nullptr)
			swapChain->Release();
		*outResult = res == FFX_API_RETURN_OK ? FFX_API_RETURN_ERROR : (int)res;
		return nullptr;
	}

	factory->MakeWindowAssociation(window, DXGI_MWA_NO_ALT_ENTER);
	swapChainContext = context;
	swapChainProxy = swapChain;
	liveContexts += 2;
	*outResult = FFX_API_RETURN_OK;
	return swapChain;
}

HL_PRIM int HL_NAME(destroy_swap_chain_context)() {
	if (swapChainContext == nullptr)
		return FFX_API_RETURN_OK;
	CHECK_FFX_LOADED();

	std::lock_guard<std::mutex> lock(fgMutex);
	ffxReturnCode_t res = ffxFuncs::DestroyContext(&swapChainContext, nullptr);
	if (res == FFX_API_RETURN_OK) {
		swapChainContext = nullptr;
		liveContexts--;
	}
	return (int)res;
}

HL_PRIM int HL_NAME(release_swap_chain)(IDXGISwapChain4* swapChain) {
	if (swapChainProxy == nullptr || swapChain == nullptr)
		return FSR_ERROR_NOT_CREATED;
	if (swapChainContext != nullptr)
		return FSR_ERROR_INVALID_STATE;

	IDXGISwapChain4* proxy = swapChainProxy;
	swapChainProxy = nullptr;
	proxy->AddRef();
	swapChain->Release();
	liveContexts--;
	return (int)proxy->Release();
}

HL_PRIM int HL_NAME(wait_for_presents)() {
	CHECK_FFX_LOADED();
	if (swapChainContext == nullptr)
		return FSR_ERROR_NOT_CREATED;

	ffxDispatchDescFrameGenerationSwapChainWaitForPresentsDX12 desc{};
	desc.header.type = FFX_API_DISPATCH_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_WAIT_FOR_PRESENTS_DX12;
	hl_blocking(true);
	ffxReturnCode_t res = ffxFuncs::Dispatch(&swapChainContext, &desc.header);
	hl_blocking(false);
	return (int)res;
}

HL_PRIM int HL_NAME(register_ui_resource)(ID3D12Resource* res, D3D12_RESOURCE_STATES state, int flags) {
	CHECK_FFX_LOADED();
	if (swapChainContext == nullptr)
		return FSR_ERROR_NOT_CREATED;

	ffxConfigureDescFrameGenerationSwapChainRegisterUiResourceDX12 desc{};
	desc.header.type = FFX_API_CONFIGURE_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_REGISTERUIRESOURCE_DX12;
	if (!toFfxResource(res, state, desc.uiResource))
		return FFX_API_RETURN_ERROR_PARAMETER;
	desc.flags = (uint32_t)flags;
	return (int)ffxFuncs::Configure(&swapChainContext, &desc.header);
}

HL_PRIM int HL_NAME(set_frame_pacing_tuning)(float safetyMarginInMs, float varianceFactor, bool allowHybridSpin, int hybridSpinTime, bool allowWaitForSingleObjectOnFence) {
	CHECK_FFX_LOADED();
	if (swapChainContext == nullptr)
		return FSR_ERROR_NOT_CREATED;

	FfxApiSwapchainFramePacingTuning tuning{};
	tuning.safetyMarginInMs = safetyMarginInMs;
	tuning.varianceFactor = varianceFactor;
	tuning.allowHybridSpin = allowHybridSpin;
	tuning.hybridSpinTime = (uint32_t)hybridSpinTime;
	tuning.allowWaitForSingleObjectOnFence = allowWaitForSingleObjectOnFence;

	ffxConfigureDescFrameGenerationSwapChainKeyValueDX12 desc{};
	desc.header.type = FFX_API_CONFIGURE_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_KEYVALUE_DX12;
	desc.key = FFX_API_CONFIGURE_FG_SWAPCHAIN_KEY_FRAMEPACINGTUNING;
	desc.ptr = &tuning;
	return (int)ffxFuncs::Configure(&swapChainContext, &desc.header);
}

HL_PRIM int HL_NAME(query_swap_chain_memory)(double* outTotal, double* outAliasable) {
	if (outTotal == nullptr || outAliasable == nullptr) return FFX_API_RETURN_ERROR_PARAMETER;
	*outTotal = 0;
	*outAliasable = 0;
	CHECK_FFX_LOADED();
	if (swapChainContext == nullptr)
		return FSR_ERROR_NOT_CREATED;

	FfxApiEffectMemoryUsage usage{};
	ffxQueryFrameGenerationSwapChainGetGPUMemoryUsageDX12 desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_FRAMEGENERATIONSWAPCHAIN_GPU_MEMORY_USAGE_DX12;
	desc.gpuMemoryUsageFrameGenerationSwapchain = &usage;

	ffxReturnCode_t res = ffxFuncs::Query(&swapChainContext, &desc.header);
	*outTotal = (double)usage.totalUsageInBytes;
	*outAliasable = (double)usage.aliasableUsageInBytes;
	return (int)res;
}

static ffxReturnCode_t fgDispatchCallback(ffxDispatchDescFrameGeneration* params, void* userContext) {
	std::lock_guard<std::mutex> lock(fgMutex);
	ffxContext context = (ffxContext)userContext;
	return ffxFuncs::Dispatch(&context, &params->header);
}

HL_PRIM ffxContext HL_NAME(create_frame_gen_context)(ID3D12Device* device, int flags, int displayWidth, int displayHeight, int maxRenderWidth, int maxRenderHeight, DXGI_FORMAT backBufferFormat, DXGI_FORMAT hudlessFormat, int* outResult) {
	if (outResult == nullptr)
		return nullptr;
	if (device == nullptr || displayWidth <= 0 || displayHeight <= 0 || maxRenderWidth <= 0 || maxRenderHeight <= 0 || (flags & ~127) != 0) {
		*outResult = FFX_API_RETURN_ERROR_PARAMETER;
		return nullptr;
	}
	if (!ffxInitialized) {
		*outResult = FSR_ERROR_NOT_LOADED;
		return nullptr;
	}

	ffxCreateBackendDX12Desc backendDesc = makeBackendDesc(device);

	ffxCreateContextDescFrameGenerationVersion versionDesc{};
	versionDesc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATION_VERSION;
	versionDesc.header.pNext = &backendDesc.header;
	versionDesc.version = FFX_FRAMEGENERATION_VERSION;

	ffxCreateContextDescFrameGenerationHudless hudlessDesc{};
	hudlessDesc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATION_HUDLESS;
	hudlessDesc.header.pNext = &versionDesc.header;
	hudlessDesc.hudlessBackBufferFormat = ffxApiGetSurfaceFormatDX12(hudlessFormat);

	ffxCreateContextDescFrameGeneration desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATION;
	desc.header.pNext = (hudlessFormat != DXGI_FORMAT_UNKNOWN && hudlessFormat != backBufferFormat) ? &hudlessDesc.header : &versionDesc.header;
	desc.flags = (uint32_t)flags;
	desc.displaySize = { (uint32_t)displayWidth, (uint32_t)displayHeight };
	desc.maxRenderSize = { (uint32_t)maxRenderWidth, (uint32_t)maxRenderHeight };
	desc.backBufferFormat = ffxApiGetSurfaceFormatDX12(backBufferFormat);

	ffxContext context = nullptr;
	ffxReturnCode_t res = ffxFuncs::CreateContext(&context, &desc.header, nullptr);
	*outResult = (int)res;
	if (res != FFX_API_RETURN_OK)
		return nullptr;

	ffxConfigureDescGlobalDebug1 debugDesc{};
	debugDesc.header.type = FFX_API_CONFIGURE_DESC_TYPE_GLOBALDEBUG1;
	debugDesc.fpMessage = onFfxMessage;
	debugDesc.debugLevel = ffxDebugLevel;
	ffxFuncs::Configure(&context, &debugDesc.header);

	liveContexts++;
	return context;
}

struct FsrFrameGenConfig {
	IDXGISwapChain4* swapChain;
	ID3D12Resource* hudless;
	D3D12_RESOURCE_STATES hudlessState;
	int flags;
	int rectX;
	int rectY;
	int rectWidth;
	int rectHeight;
	int frameID;
	bool enabled;
	bool allowAsyncWorkloads;
	bool onlyPresentGenerated;
};

HL_PRIM int HL_NAME(configure_frame_gen)(ffxContext context, FsrFrameGenConfig* config) {
	CHECK_FFX_LOADED();
	if (context == nullptr || config == nullptr || config->swapChain == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;

	ffxConfigureDescFrameGeneration desc{};
	desc.header.type = FFX_API_CONFIGURE_DESC_TYPE_FRAMEGENERATION;
	desc.swapChain = config->swapChain;
	desc.presentCallback = nullptr;
	desc.presentCallbackUserContext = nullptr;
	desc.frameGenerationCallback = fgDispatchCallback;
	desc.frameGenerationCallbackUserContext = context;
	desc.frameGenerationEnabled = config->enabled;
	desc.allowAsyncWorkloads = config->allowAsyncWorkloads;
	if (!toFfxResource(config->hudless, config->hudlessState, desc.HUDLessColor))
		return FFX_API_RETURN_ERROR_PARAMETER;
	desc.flags = (uint32_t)config->flags;
	desc.onlyPresentGenerated = config->onlyPresentGenerated;
	desc.generationRect = { config->rectX, config->rectY, config->rectWidth, config->rectHeight };
	desc.frameID = (uint64_t)(uint32_t)config->frameID;

	return (int)ffxFuncs::Configure(&context, &desc.header);
}

struct FsrFrameGenPrepareParams {
	ID3D12Resource* depth;
	ID3D12Resource* motionVectors;
	D3D12_RESOURCE_STATES depthState;
	D3D12_RESOURCE_STATES motionVectorsState;
	int renderWidth;
	int renderHeight;
	float jitterOffsetX;
	float jitterOffsetY;
	float motionVectorScaleX;
	float motionVectorScaleY;
	float frameTimeDelta;
	float cameraNear;
	float cameraFar;
	float cameraFovAngleVertical;
	float viewSpaceToMetersFactor;
	float cameraPositionX;
	float cameraPositionY;
	float cameraPositionZ;
	float cameraUpX;
	float cameraUpY;
	float cameraUpZ;
	float cameraRightX;
	float cameraRightY;
	float cameraRightZ;
	float cameraForwardX;
	float cameraForwardY;
	float cameraForwardZ;
	int frameID;
	int flags;
	bool reset;
};

HL_PRIM int HL_NAME(dispatch_frame_gen_prepare)(ffxContext context, ID3D12GraphicsCommandList* cmdList, FsrFrameGenPrepareParams* params) {
	CHECK_FFX_LOADED();
	if (context == nullptr || cmdList == nullptr || params == nullptr
		|| params->depth == nullptr || params->motionVectors == nullptr
		|| params->renderWidth <= 0 || params->renderHeight <= 0 || (params->flags & ~31) != 0)
		return FFX_API_RETURN_ERROR_PARAMETER;

	ffxDispatchDescFrameGenerationPrepareV2 desc{};
	desc.header.type = FFX_API_DISPATCH_DESC_TYPE_FRAMEGENERATION_PREPARE_V2;
	desc.frameID = (uint64_t)(uint32_t)params->frameID;
	desc.flags = (uint32_t)params->flags;
	desc.commandList = cmdList;
	desc.renderSize = { (uint32_t)params->renderWidth, (uint32_t)params->renderHeight };
	desc.jitterOffset = { params->jitterOffsetX, params->jitterOffsetY };
	desc.motionVectorScale = { params->motionVectorScaleX, params->motionVectorScaleY };
	desc.frameTimeDelta = params->frameTimeDelta;
	desc.reset = params->reset;
	desc.cameraNear = params->cameraNear;
	desc.cameraFar = params->cameraFar;
	desc.cameraFovAngleVertical = params->cameraFovAngleVertical;
	desc.viewSpaceToMetersFactor = params->viewSpaceToMetersFactor;
	if (!toFfxResource(params->depth, params->depthState, desc.depth)
		|| !toFfxResource(params->motionVectors, params->motionVectorsState, desc.motionVectors))
		return FFX_API_RETURN_ERROR_PARAMETER;
	desc.cameraPosition[0] = params->cameraPositionX;
	desc.cameraPosition[1] = params->cameraPositionY;
	desc.cameraPosition[2] = params->cameraPositionZ;
	desc.cameraUp[0] = params->cameraUpX;
	desc.cameraUp[1] = params->cameraUpY;
	desc.cameraUp[2] = params->cameraUpZ;
	desc.cameraRight[0] = params->cameraRightX;
	desc.cameraRight[1] = params->cameraRightY;
	desc.cameraRight[2] = params->cameraRightZ;
	desc.cameraForward[0] = params->cameraForwardX;
	desc.cameraForward[1] = params->cameraForwardY;
	desc.cameraForward[2] = params->cameraForwardZ;

	std::lock_guard<std::mutex> lock(fgMutex);
	return (int)ffxFuncs::Dispatch(&context, &desc.header);
}

HL_PRIM int HL_NAME(query_frame_gen_memory)(ffxContext context, double* outTotal, double* outAliasable) {
	if (outTotal == nullptr || outAliasable == nullptr) return FFX_API_RETURN_ERROR_PARAMETER;
	*outTotal = 0;
	*outAliasable = 0;
	CHECK_FFX_LOADED();
	if (context == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;

	FfxApiEffectMemoryUsage usage{};
	ffxQueryDescFrameGenerationGetGPUMemoryUsage desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_FRAMEGENERATION_GPU_MEMORY_USAGE;
	desc.gpuMemoryUsageFrameGeneration = &usage;

	ffxReturnCode_t res = ffxFuncs::Query(&context, &desc.header);
	*outTotal = (double)usage.totalUsageInBytes;
	*outAliasable = (double)usage.aliasableUsageInBytes;
	return (int)res;
}

static AMD::AntiLag2DX12::Context antiLag2Context{};

struct FfxAntiLag2Data {
	AMD::AntiLag2DX12::Context* context;
	bool enabled;
};

static const GUID IID_IFfxAntiLag2Data = { 0x5083ae5b, 0x8070, 0x4fca, { 0x8e, 0xe5, 0x35, 0x82, 0xdd, 0x36, 0x7d, 0x13 } };

HL_PRIM int HL_NAME(antilag2_init)(ID3D12Device* device) {
	return (int)AMD::AntiLag2DX12::Initialize(&antiLag2Context, device);
}

HL_PRIM int HL_NAME(antilag2_deinit)() {
	return (int)AMD::AntiLag2DX12::DeInitialize(&antiLag2Context);
}

HL_PRIM int HL_NAME(antilag2_update)(bool enable, int maxFps) {
	hl_blocking(true);
	HRESULT hr = AMD::AntiLag2DX12::Update(&antiLag2Context, enable, (unsigned int)(maxFps < 0 ? 0 : maxFps));
	hl_blocking(false);
	return (int)hr;
}

HL_PRIM int HL_NAME(antilag2_present)(IDXGISwapChain4* swapChain, bool enabled) {
	if (swapChain != nullptr) {
		FfxAntiLag2Data data{ &antiLag2Context, enabled && antiLag2Context.m_pAntiLagAPI != nullptr };
		HRESULT hr = swapChain->SetPrivateData(IID_IFfxAntiLag2Data, sizeof(data), &data);
		if (FAILED(hr))
			return (int)hr;
	}
	if (!enabled)
		return S_OK;
	return (int)AMD::AntiLag2DX12::MarkEndOfFrameRendering(&antiLag2Context);
}


DEFINE_PRIM(_I32, init, _DEVICE _I32);
DEFINE_PRIM(_I32, shutdown, _NO_ARG);
DEFINE_PRIM(_I32, get_render_resolution, _DEVICE _I32 _I32 _I32 _REF(_I32) _REF(_I32));
DEFINE_PRIM(_CONTEXT, create_context, _DEVICE _I32 _I32 _I32 _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, destroy_context, _CONTEXT);
DEFINE_PRIM(_BYTES, get_version_name, _CONTEXT);
DEFINE_PRIM(_I32, dispatch, _CONTEXT _RES _STRUCT);
DEFINE_PRIM(_SWAPCHAIN, create_swap_chain, _WINDOW _FACTORY _RES _I32 _I32 _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, destroy_swap_chain_context, _NO_ARG);
DEFINE_PRIM(_I32, release_swap_chain, _SWAPCHAIN);
DEFINE_PRIM(_I32, wait_for_presents, _NO_ARG);
DEFINE_PRIM(_I32, register_ui_resource, _RES _I32 _I32);
DEFINE_PRIM(_I32, set_frame_pacing_tuning, _F32 _F32 _BOOL _I32 _BOOL);
DEFINE_PRIM(_I32, query_swap_chain_memory, _REF(_F64) _REF(_F64));
DEFINE_PRIM(_CONTEXT, create_frame_gen_context, _DEVICE _I32 _I32 _I32 _I32 _I32 _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, configure_frame_gen, _CONTEXT _STRUCT);
DEFINE_PRIM(_I32, dispatch_frame_gen_prepare, _CONTEXT _RES _STRUCT);
DEFINE_PRIM(_I32, query_frame_gen_memory, _CONTEXT _REF(_F64) _REF(_F64));
DEFINE_PRIM(_I32, antilag2_init, _DEVICE);
DEFINE_PRIM(_I32, antilag2_deinit, _NO_ARG);
DEFINE_PRIM(_I32, antilag2_update, _BOOL _I32);
DEFINE_PRIM(_I32, antilag2_present, _SWAPCHAIN _BOOL);

DEFINE_PRIM(_I32, get_effect_version_count, _DEVICE _I32 _REF(_I32));
DEFINE_PRIM(_BYTES, get_effect_version_name, _DEVICE _I32 _I32);
