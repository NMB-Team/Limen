#define HL_NAME(n)  limen_dlss_##n
#include <hl.h>
#undef _GUID

#include <vector>
#include <algorithm>
#include <cstring>
#include <cstddef>
#include "../../vulkan/requirements.h"
#include "../types.h"
#ifdef LIMEN_POSTPROCESS_VULKAN
#include <vulkan/vulkan.h>
#include <sl_helpers_vk.h>
#endif

#include <sl.h>
#include <sl_consts.h>
#include <sl_dlss.h>
#include <sl_dlss_g.h>
#include <sl_hooks.h>
#include <sl_pcl.h>
#include <sl_reflex.h>
#include <sl_security.h>

#ifdef HL_WIN_DESKTOP
#include <filesystem>
#include <dxgi.h>
#include <dxgi1_5.h>
#include <d3d12.h>
#include <d3d11.h>
#endif

#define _DEVICE _ABSTRACT(dx_device)
#define _FACTORY _ABSTRACT(dx_factory)
#define _COMMAND_BUFFER _ABSTRACT(postprocess_command_buffer)
#define _SWAPCHAIN _ABSTRACT(dx_swapchain)
#define _RES _ABSTRACT(dx_resource)

namespace slFuncs {
SL_FUN_DECL(slInit);
SL_FUN_DECL(slShutdown);
SL_FUN_DECL(slIsFeatureSupported);
SL_FUN_DECL(slIsFeatureLoaded);
SL_FUN_DECL(slSetFeatureLoaded);
SL_FUN_DECL(slEvaluateFeature);
SL_FUN_DECL(slAllocateResources);
SL_FUN_DECL(slFreeResources);
SL_FUN_DECL(slSetTagForFrame);
SL_FUN_DECL(slGetFeatureRequirements);
SL_FUN_DECL(slGetFeatureVersion);
SL_FUN_DECL(slUpgradeInterface);
SL_FUN_DECL(slSetConstants);
SL_FUN_DECL(slGetNativeInterface);
SL_FUN_DECL(slGetFeatureFunction);
SL_FUN_DECL(slGetNewFrameToken);
SL_FUN_DECL(slSetD3DDevice);
#ifdef LIMEN_POSTPROCESS_VULKAN
static PFun_slSetVulkanInfo* slSetVulkanInfo{};
#endif
static PFun_slDLSSGetOptimalSettings* slDLSSGetOptimalSettings{};
static PFun_slDLSSSetOptions* slDLSSSetOptions{};
static PFun_slDLSSGGetState* slDLSSGGetState{};
static PFun_slDLSSGSetOptions* slDLSSGSetOptions{};
static PFun_slPCLGetState* slPCLGetState{};
static PFun_slPCLSetMarker* slPCLSetMarker{};
static PFun_slReflexGetState* slReflexGetState{};
static PFun_slReflexSetOptions* slReflexSetOptions{};
static PFun_slReflexSleep* slReflexSleep{};
}

#define LOAD_SL_FUNC(name) \
slFuncs::name = reinterpret_cast<PFun_##name*>(GetProcAddress(mod, #name))

#define CHECK_SL_FUNC(name) \
if (slFuncs::name == nullptr) return static_cast<int>(sl::Result::eErrorFeatureMissing)

enum DLSSFeature {
	DLSS,
	FrameGen,
	PCL,
	Reflex
};

sl::Feature toSlFeature(DLSSFeature feature) {
	sl::Feature featureId = 0;
	switch (feature) {
		case DLSSFeature::DLSS: {
			featureId = sl::kFeatureDLSS;
			break;
		}
		case DLSSFeature::FrameGen: {
			featureId = sl::kFeatureDLSS_G;
			break;
		}
		case DLSSFeature::PCL: {
			featureId = sl::kFeaturePCL;
			break;
		}
		case DLSSFeature::Reflex: {
			featureId = sl::kFeatureReflex;
			break;
		}
	}
	return featureId;
}

// Streamline proxy interfaces can outlive a feature session. Keep their code resident.
static HMODULE streamlineModule;
static bool streamlineInitialized;

static void clearCoreFuncs() {
	slFuncs::slInit = nullptr;
	slFuncs::slShutdown = nullptr;
	slFuncs::slIsFeatureSupported = nullptr;
	slFuncs::slIsFeatureLoaded = nullptr;
	slFuncs::slSetFeatureLoaded = nullptr;
	slFuncs::slEvaluateFeature = nullptr;
	slFuncs::slAllocateResources = nullptr;
	slFuncs::slFreeResources = nullptr;
	slFuncs::slSetTagForFrame = nullptr;
	slFuncs::slGetFeatureRequirements = nullptr;
	slFuncs::slGetFeatureVersion = nullptr;
	slFuncs::slUpgradeInterface = nullptr;
	slFuncs::slSetConstants = nullptr;
	slFuncs::slGetNativeInterface = nullptr;
	slFuncs::slGetFeatureFunction = nullptr;
	slFuncs::slGetNewFrameToken = nullptr;
	slFuncs::slSetD3DDevice = nullptr;
#ifdef LIMEN_POSTPROCESS_VULKAN
	slFuncs::slSetVulkanInfo = nullptr;
#endif
}

static PostProcessBackend activeBackend;

HL_PRIM int HL_NAME(init)(bool showConsole, varray* features, bool checkSignature, PostProcessBackend backend) {
	if (streamlineInitialized) return static_cast<int>(sl::Result::eErrorInvalidIntegration);
	if (features == nullptr) return static_cast<int>(sl::Result::eErrorInvalidParameter);
	if (backend != PostProcessBackend::D3D11 && backend != PostProcessBackend::D3D12
#ifdef LIMEN_POSTPROCESS_VULKAN
		&& backend != PostProcessBackend::Vulkan
#endif
	)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	wchar_t path[32768] = {};
	DWORD len = GetModuleFileNameW(nullptr, path, 32768);
	if (len == 0 || len == 32768)
		return -1;

	std::filesystem::path basePath = std::filesystem::path(path).parent_path();
	std::filesystem::path dllPath = basePath / L"sl.interposer.dll";
	if (checkSignature && !sl::security::verifyEmbeddedSignature(dllPath.c_str()))
		return -1;

	HMODULE mod = streamlineModule != nullptr ? streamlineModule : LoadLibraryW(dllPath.c_str());
	if (mod == nullptr)
		return -1;
	streamlineModule = mod;

	LOAD_SL_FUNC(slInit);
	LOAD_SL_FUNC(slShutdown);
	LOAD_SL_FUNC(slIsFeatureSupported);
	LOAD_SL_FUNC(slIsFeatureLoaded);
	LOAD_SL_FUNC(slSetFeatureLoaded);
	LOAD_SL_FUNC(slEvaluateFeature);
	LOAD_SL_FUNC(slAllocateResources);
	LOAD_SL_FUNC(slFreeResources);
	LOAD_SL_FUNC(slSetTagForFrame);
	LOAD_SL_FUNC(slGetFeatureRequirements);
	LOAD_SL_FUNC(slGetFeatureVersion);
	LOAD_SL_FUNC(slUpgradeInterface);
	LOAD_SL_FUNC(slSetConstants);
	LOAD_SL_FUNC(slGetNativeInterface);
	LOAD_SL_FUNC(slGetFeatureFunction);
	LOAD_SL_FUNC(slGetNewFrameToken);
	LOAD_SL_FUNC(slSetD3DDevice);
#ifdef LIMEN_POSTPROCESS_VULKAN
	LOAD_SL_FUNC(slSetVulkanInfo);
#endif

	if (slFuncs::slInit == nullptr
		|| slFuncs::slShutdown == nullptr
		|| slFuncs::slGetFeatureFunction == nullptr
		|| slFuncs::slIsFeatureSupported == nullptr
		|| slFuncs::slSetConstants == nullptr
		|| slFuncs::slSetTagForFrame == nullptr
		|| slFuncs::slEvaluateFeature == nullptr
		|| slFuncs::slGetNewFrameToken == nullptr
		|| slFuncs::slGetFeatureRequirements == nullptr
		|| (backend != PostProcessBackend::Vulkan && slFuncs::slSetD3DDevice == nullptr)
#ifdef LIMEN_POSTPROCESS_VULKAN
		|| (backend == PostProcessBackend::Vulkan && slFuncs::slSetVulkanInfo == nullptr)
#endif
	) {
		clearCoreFuncs();
		return -1;
	}

	sl::Preferences pref{};
	pref.renderAPI = backend == PostProcessBackend::Vulkan ? sl::RenderAPI::eVulkan
		: backend == PostProcessBackend::D3D11 ? sl::RenderAPI::eD3D11 : sl::RenderAPI::eD3D12;
	pref.showConsole = showConsole;
	pref.logLevel = showConsole ? sl::LogLevel::eVerbose : sl::LogLevel::eOff;
	pref.engine = sl::EngineType::eCustom;
	pref.projectId = "5346cce9-f379-43da-b490-74f1194b1e8f";
	pref.engineVersion = "2.1.1";
	std::vector<sl::Feature> featureList;
	for (int i = 0; i < features->size; i++)
		featureList.push_back(toSlFeature((DLSSFeature)hl_aptr(features, int)[i]));
	pref.featuresToLoad = featureList.data();
	pref.numFeaturesToLoad = (uint32_t)featureList.size();
	pref.flags |= sl::PreferenceFlags::eUseFrameBasedResourceTagging | sl::PreferenceFlags::eUseManualHooking;

	sl::Result res = slFuncs::slInit(pref, sl::kSDKVersion);
	if (res == sl::Result::eOk) {
		activeBackend = backend;
		streamlineInitialized = true;
	} else {
		clearCoreFuncs();
	}
	return static_cast<int>(res);
}

static UINT pclStatsWindowMessage = 0;

static void clearFeatureFuncs() {
	slFuncs::slDLSSGetOptimalSettings = nullptr;
	slFuncs::slDLSSSetOptions = nullptr;
	slFuncs::slDLSSGGetState = nullptr;
	slFuncs::slDLSSGSetOptions = nullptr;
	slFuncs::slPCLGetState = nullptr;
	slFuncs::slPCLSetMarker = nullptr;
	slFuncs::slReflexGetState = nullptr;
	slFuncs::slReflexSetOptions = nullptr;
	slFuncs::slReflexSleep = nullptr;
	pclStatsWindowMessage = 0;
}

HL_PRIM int HL_NAME(shutdown)() {
	CHECK_SL_FUNC(slShutdown);
	const auto res = slFuncs::slShutdown();
	if (res == sl::Result::eOk) {
		clearFeatureFuncs();
		clearCoreFuncs();
		streamlineInitialized = false;
		activeBackend = {};
	}
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(set_device)(PostProcessDevice* device) {
	CHECK_SL_FUNC(slGetFeatureFunction);
	if (device == nullptr || device->device == nullptr || device->backend != activeBackend)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	clearFeatureFuncs();
	sl::Result res;
	if (device->backend == PostProcessBackend::Vulkan) {
#ifdef LIMEN_POSTPROCESS_VULKAN
		CHECK_SL_FUNC(slSetVulkanInfo);
		if (device->instance == nullptr || device->physicalDevice == nullptr)
			return static_cast<int>(sl::Result::eErrorInvalidParameter);
		sl::VulkanInfo info{};
		info.device = static_cast<VkDevice>(device->device);
		info.instance = static_cast<VkInstance>(device->instance);
		info.physicalDevice = static_cast<VkPhysicalDevice>(device->physicalDevice);
		info.graphicsQueueFamily = device->graphicsQueueFamily;
		info.graphicsQueueIndex = device->graphicsQueueIndex;
		info.computeQueueFamily = device->computeQueueFamily;
		info.computeQueueIndex = device->computeQueueIndex;
		res = slFuncs::slSetVulkanInfo(info);
#else
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
#endif
	} else {
		CHECK_SL_FUNC(slSetD3DDevice);
		res = slFuncs::slSetD3DDevice(device->device);
	}
	if (res != sl::Result::eOk)
		return static_cast<int>(res);

	slFuncs::slGetFeatureFunction(sl::kFeatureDLSS, "slDLSSGetOptimalSettings", (void*&)slFuncs::slDLSSGetOptimalSettings);
	slFuncs::slGetFeatureFunction(sl::kFeatureDLSS, "slDLSSSetOptions", (void*&)slFuncs::slDLSSSetOptions);
	slFuncs::slGetFeatureFunction(sl::kFeatureDLSS_G, "slDLSSGGetState", (void*&)slFuncs::slDLSSGGetState);
	slFuncs::slGetFeatureFunction(sl::kFeatureDLSS_G, "slDLSSGSetOptions", (void*&)slFuncs::slDLSSGSetOptions);
	slFuncs::slGetFeatureFunction(sl::kFeaturePCL, "slPCLGetState", (void*&)slFuncs::slPCLGetState);
	slFuncs::slGetFeatureFunction(sl::kFeaturePCL, "slPCLSetMarker", (void*&)slFuncs::slPCLSetMarker);
	slFuncs::slGetFeatureFunction(sl::kFeatureReflex, "slReflexGetState", (void*&)slFuncs::slReflexGetState);
	slFuncs::slGetFeatureFunction(sl::kFeatureReflex, "slReflexSetOptions", (void*&)slFuncs::slReflexSetOptions);
	slFuncs::slGetFeatureFunction(sl::kFeatureReflex, "slReflexSleep", (void*&)slFuncs::slReflexSleep);
	return static_cast<int>(res);
}

void* upgradeInterface(void* dxInterface) {
	if (dxInterface == nullptr || slFuncs::slUpgradeInterface == nullptr || activeBackend == PostProcessBackend::Vulkan)
		return dxInterface;
	IUnknown* base = (IUnknown*)dxInterface;
	sl::Result res = slFuncs::slUpgradeInterface(&dxInterface);
	if (res == sl::Result::eOk && dxInterface != base)
		base->Release();
	return dxInterface;
}

HL_PRIM void* HL_NAME(upgrade_device)(void* nativeDevice) {
	return upgradeInterface(nativeDevice);
}

HL_PRIM void* HL_NAME(upgrade_factory)(void* nativeFactory) {
	return upgradeInterface(nativeFactory);
}

HL_PRIM void* HL_NAME(upgrade_swap_chain)(void* nativeSwapChain) {
	return upgradeInterface(nativeSwapChain);
}

void* getNativeInterface(void* proxyInterface) {
	if (proxyInterface == nullptr || slFuncs::slGetNativeInterface == nullptr)
		return proxyInterface;

	void* nativeInterface = nullptr;
	sl::Result res = slFuncs::slGetNativeInterface(proxyInterface, &nativeInterface);
	if (res != sl::Result::eOk || nativeInterface == nullptr)
		return proxyInterface;
	return nativeInterface;
}

HL_PRIM void* HL_NAME(get_native_device)(void* device) {
	return getNativeInterface(device);
}

HL_PRIM void* HL_NAME(get_native_factory)(void* factory) {
	return getNativeInterface(factory);
}

HL_PRIM void* HL_NAME(get_native_queue)(void* queue) {
	return getNativeInterface(queue);
}

HL_PRIM int HL_NAME(is_feature_supported)(PostProcessDevice* device, DLSSFeature feature) {
	CHECK_SL_FUNC(slIsFeatureSupported);
	if (device == nullptr || device->device == nullptr || device->backend != activeBackend)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	sl::AdapterInfo adapterInfo;
	LUID luid{};
	if (activeBackend == PostProcessBackend::Vulkan) {
		if (device->physicalDevice == nullptr)
			return static_cast<int>(sl::Result::eErrorInvalidParameter);
		adapterInfo.vkPhysicalDevice = device->physicalDevice;
	} else {
		if (activeBackend == PostProcessBackend::D3D12) {
			luid = static_cast<ID3D12Device*>(device->device)->GetAdapterLuid();
		} else {
			IDXGIDevice* dxgiDevice = nullptr;
			if (FAILED(static_cast<ID3D11Device*>(device->device)->QueryInterface(IID_PPV_ARGS(&dxgiDevice))))
				return static_cast<int>(sl::Result::eErrorInvalidParameter);
			IDXGIAdapter* adapter = nullptr;
			HRESULT result = dxgiDevice->GetAdapter(&adapter);
			dxgiDevice->Release();
			if (FAILED(result)) return static_cast<int>(sl::Result::eErrorInvalidParameter);
			DXGI_ADAPTER_DESC desc{};
			result = adapter->GetDesc(&desc);
			adapter->Release();
			if (FAILED(result)) return static_cast<int>(sl::Result::eErrorInvalidParameter);
			luid = desc.AdapterLuid;
		}
		adapterInfo.deviceLUID = reinterpret_cast<uint8_t*>(&luid);
		adapterInfo.deviceLUIDSizeInBytes = sizeof(luid);
	}
	return static_cast<int>(slFuncs::slIsFeatureSupported(toSlFeature(feature), adapterInfo));
}

struct DLSSOptions {
	sl::DLSSMode mode;
	uint32_t outputWidth;
	uint32_t outputHeight;
	sl::DLSSPreset preset;
	int colorBufferHDR;
	int autoExposure;
};

struct DLSSOptimalSettings {
	uint32_t optimalRenderWidth;
	uint32_t optimalRenderHeight;
	double optimalSharpness;
};

HL_PRIM int HL_NAME(get_optimal_settings)(DLSSOptions* options, DLSSOptimalSettings* outOptimalSettings) {
	CHECK_SL_FUNC(slDLSSGetOptimalSettings);

	sl::DLSSOptions dlssOptions;
	dlssOptions.mode = options->mode;
	dlssOptions.outputWidth = options->outputWidth;
	dlssOptions.outputHeight = options->outputHeight;

	sl::DLSSOptimalSettings optimalSettings;
	sl::Result res = slFuncs::slDLSSGetOptimalSettings(dlssOptions, optimalSettings);

	outOptimalSettings->optimalRenderWidth = optimalSettings.optimalRenderWidth;
	outOptimalSettings->optimalRenderHeight = optimalSettings.optimalRenderHeight;
	outOptimalSettings->optimalSharpness = (double)optimalSettings.optimalSharpness;

	return static_cast<int>(res);
}

using dlss_frametoken = sl::FrameToken;

#define _FRAMETOKEN _ABSTRACT(dlss_frametoken)

HL_PRIM sl::FrameToken* HL_NAME(get_new_frame_token)(int frameIndex) {
	if (slFuncs::slGetNewFrameToken == nullptr) return nullptr;
	sl::FrameToken* frameToken = nullptr;
	uint32_t frameId = (uint32_t)frameIndex;
	slFuncs::slGetNewFrameToken(frameToken, &frameId);
	return frameToken;
}


HL_PRIM int HL_NAME(pcl_init_stats)() {
	CHECK_SL_FUNC(slPCLGetState);

	sl::PCLState state{};
	sl::Result res = slFuncs::slPCLGetState(state);
	if (res == sl::Result::eOk)
		pclStatsWindowMessage = (UINT)state.statsWindowMessage;
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(pcl_set_marker)(sl::FrameToken* frameToken, int marker) {
	CHECK_SL_FUNC(slPCLSetMarker);
	sl::Result res = slFuncs::slPCLSetMarker((sl::PCLMarker)marker, *frameToken);
	return static_cast<int>(res);
}

HL_PRIM bool HL_NAME(pcl_poll_ping)(sl::FrameToken* frameToken) {
	if (pclStatsWindowMessage == 0 || slFuncs::slPCLSetMarker == nullptr || frameToken == nullptr)
		return false;

	MSG msg;
	bool pinged = false;
	while (PeekMessageW(&msg, nullptr, pclStatsWindowMessage, pclStatsWindowMessage, PM_REMOVE))
		pinged = true;
	if (pinged)
		slFuncs::slPCLSetMarker(sl::PCLMarker::ePCLatencyPing, *frameToken);
	return pinged;
}

struct ReflexStateInfo {
	int lowLatencyAvailable;
	int latencyReportAvailable;
	int flashIndicatorDriverControlled;
	int statsWindowMessage;
};

struct ReflexFrameReport {
	double frameID;
	double inputSampleTime;
	double simStartTime;
	double simEndTime;
	double renderSubmitStartTime;
	double renderSubmitEndTime;
	double presentStartTime;
	double presentEndTime;
	double driverStartTime;
	double driverEndTime;
	double osRenderQueueStartTime;
	double osRenderQueueEndTime;
	double gpuRenderStartTime;
	double gpuRenderEndTime;
	double cameraConstructedTime;
	int gpuActiveRenderTimeUs;
	int gpuFrameTimeUs;
	int crossAdapterCopyTimeUs;
};

static sl::ReflexState reflexState{};

HL_PRIM int HL_NAME(reflex_set_options)(int mode, int frameLimitUs, bool useMarkersToOptimize, int virtualKey, int threadId) {
	CHECK_SL_FUNC(slReflexSetOptions);
	sl::ReflexOptions options{};
	options.mode = (sl::ReflexMode)mode;
	options.frameLimitUs = (uint32_t)frameLimitUs;
	options.useMarkersToOptimize = useMarkersToOptimize;
	options.virtualKey = (uint16_t)virtualKey;
	options.idThread = (uint32_t)threadId;
	sl::Result res = slFuncs::slReflexSetOptions(options);
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(reflex_sleep)(sl::FrameToken* frameToken) {
	CHECK_SL_FUNC(slReflexSleep);
	hl_blocking(true);
	sl::Result res = slFuncs::slReflexSleep(*frameToken);
	hl_blocking(false);
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(reflex_get_state)(ReflexStateInfo* outState) {
	CHECK_SL_FUNC(slReflexGetState);
	sl::Result res = slFuncs::slReflexGetState(reflexState);
	if (res != sl::Result::eOk)
		return static_cast<int>(res);
	outState->lowLatencyAvailable = reflexState.lowLatencyAvailable ? 1 : 0;
	outState->latencyReportAvailable = reflexState.latencyReportAvailable ? 1 : 0;
	outState->flashIndicatorDriverControlled = reflexState.flashIndicatorDriverControlled ? 1 : 0;
	outState->statsWindowMessage = (int)reflexState.statsWindowMessage;
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(reflex_get_frame_report)(int index, ReflexFrameReport* outReport) {
	if (index < 0 || index >= sl::kReflexFrameReportCount)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	if (!reflexState.latencyReportAvailable)
		return static_cast<int>(sl::Result::eErrorInvalidState);

	const sl::ReflexReport& report = reflexState.frameReport[index];
	const sl::ReflexReport2& report2 = reflexState.frameReport2[index];
	outReport->frameID = (double)report.frameID;
	outReport->inputSampleTime = (double)report.inputSampleTime;
	outReport->simStartTime = (double)report.simStartTime;
	outReport->simEndTime = (double)report.simEndTime;
	outReport->renderSubmitStartTime = (double)report.renderSubmitStartTime;
	outReport->renderSubmitEndTime = (double)report.renderSubmitEndTime;
	outReport->presentStartTime = (double)report.presentStartTime;
	outReport->presentEndTime = (double)report.presentEndTime;
	outReport->driverStartTime = (double)report.driverStartTime;
	outReport->driverEndTime = (double)report.driverEndTime;
	outReport->osRenderQueueStartTime = (double)report.osRenderQueueStartTime;
	outReport->osRenderQueueEndTime = (double)report.osRenderQueueEndTime;
	outReport->gpuRenderStartTime = (double)report.gpuRenderStartTime;
	outReport->gpuRenderEndTime = (double)report.gpuRenderEndTime;
	outReport->cameraConstructedTime = (double)report2.cameraConstructedTime;
	outReport->gpuActiveRenderTimeUs = (int)report.gpuActiveRenderTimeUs;
	outReport->gpuFrameTimeUs = (int)report.gpuFrameTimeUs;
	outReport->crossAdapterCopyTimeUs = (int)report2.crossAdapterCopyTimeUs;
	return static_cast<int>(sl::Result::eOk);
}

enum DLSSBufferType {
	Depth,
	MotionVectors,
	ColorIn,
	ColorOut,
	HUDLessColor,
	UIColorAndAlpha,
	UIAlpha,
	Backbuffer
};

struct DLSSResource {
	TextureResource* res;
	int width;
	int height;
	DLSSBufferType type;
	int lifecycle;
};

HL_PRIM int HL_NAME(set_tag_for_frame)(sl::FrameToken* frameToken, DLSSResource* res, int count, void* cmdList) {
	CHECK_SL_FUNC(slSetTagForFrame);
	if (frameToken == nullptr || res == nullptr || count < 0 || cmdList == nullptr)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	std::vector<sl::Resource> slResources(count);
	std::vector<sl::Extent> slExtents(count);
	std::vector<sl::ResourceTag> slTags(count);

	for (int i = 0; i < count; i++) {
		DLSSResource& r = res[i];

		if (r.res != nullptr) {
			auto& texture = *r.res;
			if (activeBackend == PostProcessBackend::Vulkan && (texture.native == nullptr || texture.view == nullptr
				|| texture.width == 0 || texture.height == 0 || texture.format == 0))
				return static_cast<int>(sl::Result::eErrorInvalidParameter);
			slResources[i] = { sl::ResourceType::eTex2d, texture.native, texture.memory, texture.view, texture.state };
			slResources[i].width = texture.width;
			slResources[i].height = texture.height;
			slResources[i].nativeFormat = texture.format;
			slResources[i].mipLevels = texture.mipLevels;
			slResources[i].arrayLayers = texture.arrayLayers;
			slResources[i].usage = texture.usage;
			slResources[i].flags = texture.flags;
		}
		slExtents[i] = { 0, 0, (uint32_t)r.width, (uint32_t)r.height };

		sl::BufferType type = {};
		switch (r.type) {
		case DLSSBufferType::Depth: type = sl::kBufferTypeDepth; break;
		case DLSSBufferType::MotionVectors: type = sl::kBufferTypeMotionVectors; break;
		case DLSSBufferType::ColorIn: type = sl::kBufferTypeScalingInputColor; break;
		case DLSSBufferType::ColorOut: type = sl::kBufferTypeScalingOutputColor; break;
		case DLSSBufferType::HUDLessColor: type = sl::kBufferTypeHUDLessColor; break;
		case DLSSBufferType::UIColorAndAlpha: type = sl::kBufferTypeUIColorAndAlpha; break;
		case DLSSBufferType::UIAlpha: type = sl::kBufferTypeUIAlpha; break;
		case DLSSBufferType::Backbuffer: type = sl::kBufferTypeBackbuffer; break;
		}

		slTags[i] = { r.res == nullptr || r.res->native == nullptr ? nullptr : &slResources[i], type, (sl::ResourceLifecycle)r.lifecycle, &slExtents[i] };
	}

	sl::Result result = slFuncs::slSetTagForFrame(*frameToken, sl::ViewportHandle(0), slTags.data(), (uint32_t)count, cmdList);

	return static_cast<int>(result);
}

HL_PRIM int HL_NAME(set_options)(DLSSOptions* options) {
	CHECK_SL_FUNC(slDLSSSetOptions);

	sl::DLSSOptions dlssOptions;
	dlssOptions.mode = options->mode;
	dlssOptions.outputWidth = options->outputWidth;
	dlssOptions.outputHeight = options->outputHeight;
	dlssOptions.dlaaPreset = options->preset;
	dlssOptions.qualityPreset = options->preset;
	dlssOptions.balancedPreset = options->preset;
	dlssOptions.performancePreset = options->preset;
	dlssOptions.ultraPerformancePreset = options->preset;
	dlssOptions.ultraQualityPreset = options->preset;
	dlssOptions.colorBuffersHDR = options->colorBufferHDR ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	dlssOptions.useAutoExposure = options->autoExposure ? sl::Boolean::eTrue : sl::Boolean::eFalse;

	sl::Result result = slFuncs::slDLSSSetOptions(sl::ViewportHandle(0), dlssOptions);

	return static_cast<int>(result);
}

struct DLSSConstants {
	float* cameraViewToClip;
	float* clipToCameraView;
	float* clipToLensClip;
	float* clipToPrevClip;
	float* prevClipToClip;
	float jitterOffsetX;
	float jitterOffsetY;
	float mvecScaleX;
	float mvecScaleY;
	float cameraPinholeOffsetX;
	float cameraPinholeOffsetY;
	float* cameraPos;
	float* cameraUp;
	float* cameraRight;
	float* cameraFwd;
	float cameraNear;
	float cameraFar;
	float cameraFOV;
	float cameraAspectRatio;
	float motionVectorsInvalidValue;
	int depthInverted;
	int cameraMotionIncluded;
	int motionVectors3D;
	int reset;
	int orthographicProjection;
	int motionVectorsDilated;
	int motionVectorsJittered;
	float minRelativeLinearDepthObjectSeparation;
};

HL_PRIM int HL_NAME(set_constants)(sl::FrameToken* frameToken, DLSSConstants* constants) {
	CHECK_SL_FUNC(slSetConstants);
	sl::Constants slConstants{};
	memcpy(&slConstants.cameraViewToClip, constants->cameraViewToClip, sizeof(float) * 16);
	memcpy(&slConstants.clipToCameraView, constants->clipToCameraView, sizeof(float) * 16);
	memcpy(&slConstants.clipToLensClip, constants->clipToLensClip, sizeof(float) * 16);
	memcpy(&slConstants.clipToPrevClip, constants->clipToPrevClip, sizeof(float) * 16);
	memcpy(&slConstants.prevClipToClip, constants->prevClipToClip, sizeof(float) * 16);
	slConstants.jitterOffset = { constants->jitterOffsetX, constants->jitterOffsetY };
	slConstants.mvecScale = { constants->mvecScaleX,    constants->mvecScaleY };
	slConstants.cameraPinholeOffset = { constants->cameraPinholeOffsetX, constants->cameraPinholeOffsetY };
	memcpy(&slConstants.cameraPos, constants->cameraPos, sizeof(float) * 3);
	memcpy(&slConstants.cameraUp, constants->cameraUp, sizeof(float) * 3);
	memcpy(&slConstants.cameraRight, constants->cameraRight, sizeof(float) * 3);
	memcpy(&slConstants.cameraFwd, constants->cameraFwd, sizeof(float) * 3);
	slConstants.cameraNear = constants->cameraNear;
	slConstants.cameraFar = constants->cameraFar;
	slConstants.cameraFOV = constants->cameraFOV;
	slConstants.cameraAspectRatio = constants->cameraAspectRatio;
	slConstants.motionVectorsInvalidValue = constants->motionVectorsInvalidValue;
	slConstants.depthInverted = constants->depthInverted ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.cameraMotionIncluded = constants->cameraMotionIncluded ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.motionVectors3D = constants->motionVectors3D ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.reset = constants->reset ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.orthographicProjection = constants->orthographicProjection ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.motionVectorsDilated = constants->motionVectorsDilated ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.motionVectorsJittered = constants->motionVectorsJittered ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	slConstants.minRelativeLinearDepthObjectSeparation = constants->minRelativeLinearDepthObjectSeparation;

	sl::Result result = slFuncs::slSetConstants(slConstants, *frameToken, sl::ViewportHandle(0));
	return static_cast<int>(result);
}

struct DLSSGOptions {
	uint32_t mode;
	uint32_t numFramesToGenerate;
	uint32_t flags;
	uint32_t dynamicResWidth;
	uint32_t dynamicResHeight;
	float dynamicTargetFrameRate;
	bool enableUserInterfaceRecomposition;
};

struct DLSSGStateInfo {
	int status;
	int minWidthOrHeight;
	int numFramesActuallyPresented;
	int numFramesToGenerateMax;
	int dynamicMFGSupported;
	int vsyncSupportAvailable;
};

HL_PRIM int HL_NAME(dlssg_set_options)(DLSSGOptions* options) {
	CHECK_SL_FUNC(slDLSSGSetOptions);
	sl::DLSSGOptions dlssgOptions{};
	dlssgOptions.mode = (sl::DLSSGMode)options->mode;
	dlssgOptions.numFramesToGenerate = options->numFramesToGenerate;
	dlssgOptions.flags = (sl::DLSSGFlags)options->flags;
	dlssgOptions.dynamicResWidth = options->dynamicResWidth;
	dlssgOptions.dynamicResHeight = options->dynamicResHeight;
	dlssgOptions.dynamicTargetFrameRate = options->dynamicTargetFrameRate;
	dlssgOptions.enableUserInterfaceRecomposition = options->enableUserInterfaceRecomposition ? sl::Boolean::eTrue : sl::Boolean::eFalse;
	sl::Result res = slFuncs::slDLSSGSetOptions(sl::ViewportHandle(0), dlssgOptions);
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(dlssg_get_state)(DLSSGStateInfo* outState) {
	CHECK_SL_FUNC(slDLSSGGetState);
	sl::DLSSGState state{};
	sl::Result res = slFuncs::slDLSSGGetState(sl::ViewportHandle(0), state, nullptr);
	if (res != sl::Result::eOk)
		return static_cast<int>(res);
	outState->status = (int)state.status;
	outState->minWidthOrHeight = (int)state.minWidthOrHeight;
	outState->numFramesActuallyPresented = (int)state.numFramesActuallyPresented;
	outState->numFramesToGenerateMax = (int)state.numFramesToGenerateMax;
	outState->dynamicMFGSupported = state.bIsDynamicMFGSupported == sl::Boolean::eTrue ? 1 : 0;
	outState->vsyncSupportAvailable = state.bIsVsyncSupportAvailable == sl::Boolean::eTrue ? 1 : 0;
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(set_feature_loaded)(DLSSFeature feature, bool loaded) {
	CHECK_SL_FUNC(slSetFeatureLoaded);
	sl::Result res = slFuncs::slSetFeatureLoaded(toSlFeature(feature), loaded);
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(free_resources)(DLSSFeature feature) {
	CHECK_SL_FUNC(slFreeResources);
	sl::Result res = slFuncs::slFreeResources(toSlFeature(feature), sl::ViewportHandle(0));
	return static_cast<int>(res);
}

HL_PRIM int HL_NAME(evaluate_feature)(sl::FrameToken* frameToken, void* cmdList, DLSSFeature feature) {
	CHECK_SL_FUNC(slEvaluateFeature);
	if (frameToken == nullptr || cmdList == nullptr) return static_cast<int>(sl::Result::eErrorInvalidParameter);
	sl::ViewportHandle vp = { sl::ViewportHandle(0) };
	const sl::BaseStructure* inputs[] = { &vp };

	sl::Result result = slFuncs::slEvaluateFeature(toSlFeature(feature), *frameToken, inputs, _countof(inputs), cmdList);
	return static_cast<int>(result);
}

HL_PRIM int HL_NAME(get_vulkan_requirements)(varray* features, VulkanRequirements* out) {
#ifdef LIMEN_POSTPROCESS_VULKAN
	CHECK_SL_FUNC(slGetFeatureRequirements);
	if (activeBackend != PostProcessBackend::Vulkan || features == nullptr || out == nullptr)
		return static_cast<int>(sl::Result::eErrorInvalidParameter);
	std::vector<const char*> instanceExtensions, deviceExtensions;
	VkPhysicalDeviceVulkan12Features features12{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES};
	VkPhysicalDeviceVulkan13Features features13{VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES};
	uint32_t graphicsQueues = 0, computeQueues = 0;
	for (int i = 0; i < features->size; i++) {
		sl::FeatureRequirements requirements{};
		const auto result = slFuncs::slGetFeatureRequirements(toSlFeature(static_cast<DLSSFeature>(hl_aptr(features, int)[i])), requirements);
		if (result != sl::Result::eOk) return static_cast<int>(result);
		if (requirements.vkNumOpticalFlowQueuesRequired != 0)
			return static_cast<int>(sl::Result::eErrorFeatureNotSupported);
		for (uint32_t j = 0; j < requirements.vkNumInstanceExtensions; j++) instanceExtensions.push_back(requirements.vkInstanceExtensions[j]);
		for (uint32_t j = 0; j < requirements.vkNumDeviceExtensions; j++) deviceExtensions.push_back(requirements.vkDeviceExtensions[j]);
		const auto f12 = sl::getVkPhysicalDeviceVulkan12Features(requirements.vkNumFeatures12, requirements.vkFeatures12);
		const auto f13 = sl::getVkPhysicalDeviceVulkan13Features(requirements.vkNumFeatures13, requirements.vkFeatures13);
		for (size_t offset = offsetof(VkPhysicalDeviceVulkan12Features, samplerMirrorClampToEdge); offset <= offsetof(VkPhysicalDeviceVulkan12Features, subgroupBroadcastDynamicId); offset += sizeof(VkBool32))
			*reinterpret_cast<VkBool32*>(reinterpret_cast<char*>(&features12) + offset) |= *reinterpret_cast<const VkBool32*>(reinterpret_cast<const char*>(&f12) + offset);
		for (size_t offset = offsetof(VkPhysicalDeviceVulkan13Features, robustImageAccess); offset <= offsetof(VkPhysicalDeviceVulkan13Features, maintenance4); offset += sizeof(VkBool32))
			*reinterpret_cast<VkBool32*>(reinterpret_cast<char*>(&features13) + offset) |= *reinterpret_cast<const VkBool32*>(reinterpret_cast<const char*>(&f13) + offset);
		graphicsQueues = (std::max)(graphicsQueues, requirements.vkNumGraphicsQueuesRequired);
		computeQueues = (std::max)(computeQueues, requirements.vkNumComputeQueuesRequired);
	}
	out->features12 = hl_copy_bytes(reinterpret_cast<const vbyte*>(&features12), sizeof(features12));
	out->features13 = hl_copy_bytes(reinterpret_cast<const vbyte*>(&features13), sizeof(features13));
	out->graphicsQueues = graphicsQueues;
	out->computeQueues = computeQueues;
	out->instanceExtensions = hl_alloc_array(&hlt_bytes, int(instanceExtensions.size()));
	for (int i = 0; i < out->instanceExtensions->size; i++)
		hl_aptr(out->instanceExtensions, vbyte*)[i] = hl_copy_bytes(reinterpret_cast<const vbyte*>(instanceExtensions[i]), int(std::strlen(instanceExtensions[i])) + 1);
	out->deviceExtensions = hl_alloc_array(&hlt_bytes, int(deviceExtensions.size()));
	for (int i = 0; i < out->deviceExtensions->size; i++)
		hl_aptr(out->deviceExtensions, vbyte*)[i] = hl_copy_bytes(reinterpret_cast<const vbyte*>(deviceExtensions[i]), int(std::strlen(deviceExtensions[i])) + 1);
	return 0;
#else
	return static_cast<int>(sl::Result::eErrorFeatureNotSupported);
#endif
}
DEFINE_PRIM(_I32, get_vulkan_requirements, _ARR _STRUCT);

DEFINE_PRIM(_I32, init, _BOOL _ARR _BOOL _I32);
DEFINE_PRIM(_I32, shutdown, _NO_ARG);
DEFINE_PRIM(_DEVICE, upgrade_device, _DEVICE);
DEFINE_PRIM(_FACTORY, upgrade_factory, _FACTORY);
DEFINE_PRIM(_I32, set_device, _STRUCT);
DEFINE_PRIM(_I32, is_feature_supported, _STRUCT _I32);
DEFINE_PRIM(_I32, get_optimal_settings, _STRUCT _STRUCT);
DEFINE_PRIM(_FRAMETOKEN, get_new_frame_token, _I32);
DEFINE_PRIM(_I32, pcl_init_stats, _NO_ARG);
DEFINE_PRIM(_I32, pcl_set_marker, _FRAMETOKEN _I32);
DEFINE_PRIM(_BOOL, pcl_poll_ping, _FRAMETOKEN);
DEFINE_PRIM(_I32, reflex_set_options, _I32 _I32 _BOOL _I32 _I32);
DEFINE_PRIM(_I32, reflex_sleep, _FRAMETOKEN);
DEFINE_PRIM(_I32, reflex_get_state, _STRUCT);
DEFINE_PRIM(_I32, reflex_get_frame_report, _I32 _STRUCT);
DEFINE_PRIM(_I32, set_tag_for_frame, _FRAMETOKEN _ABSTRACT(hl_carray) _I32 _COMMAND_BUFFER);
DEFINE_PRIM(_I32, set_options, _STRUCT);
DEFINE_PRIM(_I32, set_constants, _FRAMETOKEN _STRUCT);
DEFINE_PRIM(_I32, dlssg_set_options, _STRUCT);
DEFINE_PRIM(_I32, dlssg_get_state, _STRUCT);
DEFINE_PRIM(_I32, set_feature_loaded, _I32 _BOOL);
DEFINE_PRIM(_I32, free_resources, _I32);
DEFINE_PRIM(_I32, evaluate_feature, _FRAMETOKEN _COMMAND_BUFFER _I32);

DEFINE_PRIM(_SWAPCHAIN, upgrade_swap_chain, _SWAPCHAIN);
DEFINE_PRIM(_DEVICE, get_native_device, _DEVICE);
DEFINE_PRIM(_FACTORY, get_native_factory, _FACTORY);
DEFINE_PRIM(_RES, get_native_queue, _RES);

HL_PRIM bool HL_NAME(is_backend_supported)(PostProcessBackend backend) {
	return backend == PostProcessBackend::D3D11 || backend == PostProcessBackend::D3D12
#ifdef LIMEN_POSTPROCESS_VULKAN
		|| backend == PostProcessBackend::Vulkan
#endif
		;
}
DEFINE_PRIM(_BOOL, is_backend_supported, _I32);
