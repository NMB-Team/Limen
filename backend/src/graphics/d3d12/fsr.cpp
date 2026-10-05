#define HL_NAME(n) limen_fsr_##n
#include <hl.h>
#undef _GUID

#include <windows.h>
#include <d3d12.h>
#include <cstdio>
#include <cstring>
#include <string>

#include <ffx_provider_fsr3upscale.h>
#include <ffx_message.h>

#include <ffx_api.h>
#include <ffx_api_types.h>
#include <dx12/ffx_api_dx12.h>
#include <ffx_upscale.h>

#define _DEVICE _ABSTRACT(dx_device)
#define _RES _ABSTRACT(dx_resource)
#define _CONTEXT _ABSTRACT(fsr_context)

#define FSR_ERROR_NOT_LOADED -1

#define CHECK_FFX_LOADED() \
	if (!ffxInitialized) return FSR_ERROR_NOT_LOADED

static bool ffxInitialized = false;
static uint32_t ffxDebugLevel = FFX_API_CONFIGURE_GLOBALDEBUG_LEVEL_ERRORS;
static int liveContexts = 0;

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

	ffxCreateContextDescUpscale desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE;
	desc.header.pNext = &backendDesc.header;
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
		ffxProvider_FSR3Upscale::GetInstance().DestroyContext(&context, alloc);
		*outResult = (int)res;
		return nullptr;
	}

	liveContexts++;
	return context;
}

HL_PRIM int HL_NAME(destroy_context)(ffxContext context) {
	CHECK_FFX_LOADED();
	if (context == nullptr)
		return FFX_API_RETURN_ERROR_PARAMETER;

	Allocator alloc{nullptr};
	ffxReturnCode_t res = ffxProvider_FSR3Upscale::GetInstance().DestroyContext(&context, alloc);
	if (res == FFX_API_RETURN_OK)
		liveContexts--;
	return (int)res;
}

HL_PRIM vbyte* HL_NAME(get_version_name)(ffxContext context) {
	if (!ffxInitialized || context == nullptr)
		return nullptr;

	const char* name = ffxProvider_FSR3Upscale::GetInstance().GetVersionName();
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

DEFINE_PRIM(_I32, init, _DEVICE _I32);
DEFINE_PRIM(_I32, shutdown, _NO_ARG);
DEFINE_PRIM(_I32, get_render_resolution, _DEVICE _I32 _I32 _I32 _REF(_I32) _REF(_I32));
DEFINE_PRIM(_CONTEXT, create_context, _DEVICE _I32 _I32 _I32 _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, destroy_context, _CONTEXT);
DEFINE_PRIM(_BYTES, get_version_name, _CONTEXT);
DEFINE_PRIM(_I32, dispatch, _CONTEXT _RES _STRUCT);
