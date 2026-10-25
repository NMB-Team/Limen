#include "backend.h"
#undef _GUID
#include <windows.h>
#include <filesystem>
#include <cstring>
#include <vector>
#include <ffx_api/ffx_upscale.h>
#include <ffx_api/vk/ffx_api_vk.h>

namespace {
uint32_t debugLevel;

void onMessage(uint32_t type, const wchar_t* message) {
	if ((type == FFX_API_MESSAGE_TYPE_ERROR && (debugLevel & FFX_API_CONFIGURE_GLOBALDEBUG_LEVEL_ERRORS))
		|| (type == FFX_API_MESSAGE_TYPE_WARNING && (debugLevel & FFX_API_CONFIGURE_GLOBALDEBUG_LEVEL_WARNINGS)))
		OutputDebugStringW(message);
}

HMODULE module;
HMODULE vulkanLoader;
PFN_vkGetDeviceProcAddr getDeviceProcAddr;
PfnFfxCreateContext createContext;
PfnFfxDestroyContext destroyContext;
PfnFfxDispatch dispatch;
PfnFfxQuery query;

ffxCreateBackendVKDesc backendDesc(PostProcessDevice* device) {
	ffxCreateBackendVKDesc desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_BACKEND_VK;
	desc.vkDevice = static_cast<VkDevice>(device->device);
	desc.vkPhysicalDevice = static_cast<VkPhysicalDevice>(device->physicalDevice);
	desc.vkDeviceProcAddr = getDeviceProcAddr;
	return desc;
}

int init(PostProcessDevice*, int debug) {
	debugLevel = uint32_t(debug);
	HMODULE self;
	if (!GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		reinterpret_cast<LPCWSTR>(&init), &self)) return FsrNotLoaded;
	wchar_t path[32768];
	const DWORD length = GetModuleFileNameW(self, path, 32768);
	if (length == 0 || length == 32768) return FsrNotLoaded;
	const auto runtime = std::filesystem::path(path).parent_path() / L"amd_fidelityfx_vk.dll";
	module = LoadLibraryExW(runtime.c_str(), nullptr, LOAD_LIBRARY_SEARCH_DLL_LOAD_DIR | LOAD_LIBRARY_SEARCH_DEFAULT_DIRS);
	if (module == nullptr) return FsrNotLoaded;
	createContext = reinterpret_cast<PfnFfxCreateContext>(GetProcAddress(module, "ffxCreateContext"));
	destroyContext = reinterpret_cast<PfnFfxDestroyContext>(GetProcAddress(module, "ffxDestroyContext"));
	dispatch = reinterpret_cast<PfnFfxDispatch>(GetProcAddress(module, "ffxDispatch"));
	query = reinterpret_cast<PfnFfxQuery>(GetProcAddress(module, "ffxQuery"));
	if (createContext == nullptr || destroyContext == nullptr || dispatch == nullptr || query == nullptr) {
		FreeLibrary(module);
		module = nullptr;
		return FsrNotLoaded;
	}
	vulkanLoader = LoadLibraryExW(L"vulkan-1.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
	getDeviceProcAddr = vulkanLoader == nullptr ? nullptr
		: reinterpret_cast<PFN_vkGetDeviceProcAddr>(GetProcAddress(vulkanLoader, "vkGetDeviceProcAddr"));
	if (getDeviceProcAddr == nullptr) {
		if (vulkanLoader != nullptr) FreeLibrary(vulkanLoader);
		FreeLibrary(module);
		module = nullptr;
		vulkanLoader = nullptr;
		return FsrNotLoaded;
	}
	return 0;
}

int shutdown() {
	FreeLibrary(module);
	FreeLibrary(vulkanLoader);
	module = nullptr;
	vulkanLoader = nullptr;
	getDeviceProcAddr = nullptr;
	createContext = nullptr;
	destroyContext = nullptr;
	dispatch = nullptr;
	query = nullptr;
	return 0;
}

int renderResolution(PostProcessDevice* device, int quality, int width, int height, int* rw, int* rh) {
	if (quality < 0 || quality > 4 || width <= 0 || height <= 0 || rw == nullptr || rh == nullptr) return FFX_API_RETURN_ERROR_PARAMETER;
	auto backend = backendDesc(device);
	uint32_t renderWidth = 0, renderHeight = 0;
	ffxQueryDescUpscaleGetRenderResolutionFromQualityMode desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_UPSCALE_GETRENDERRESOLUTIONFROMQUALITYMODE;
	desc.header.pNext = &backend.header;
	desc.displayWidth = width;
	desc.displayHeight = height;
	desc.qualityMode = quality;
	desc.pOutRenderWidth = &renderWidth;
	desc.pOutRenderHeight = &renderHeight;
	const int result = query(nullptr, &desc.header);
	*rw = renderWidth;
	*rh = renderHeight;
	return result;
}

void* create(PostProcessDevice* device, int flags, int rw, int rh, int ow, int oh, int* result) {
	if (rw <= 0 || rh <= 0 || ow <= 0 || oh <= 0 || (flags & ~511) != 0) {
		*result = FFX_API_RETURN_ERROR_PARAMETER;
		return nullptr;
	}
	auto backend = backendDesc(device);
	ffxCreateContextDescUpscale desc{};
	desc.header.type = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE;
	desc.header.pNext = &backend.header;
	desc.flags = flags;
	desc.fpMessage = onMessage;
	desc.maxRenderSize = {uint32_t(rw), uint32_t(rh)};
	desc.maxUpscaleSize = {uint32_t(ow), uint32_t(oh)};
	ffxContext context = nullptr;
	*result = createContext(&context, &desc.header, nullptr);
	return *result == 0 ? context : nullptr;
}

bool resource(TextureResource* texture, FfxApiResource& out) {
	out = {};
	if (texture == nullptr) return true;
	if (texture->native == nullptr || texture->width == 0 || texture->height == 0 || texture->format == 0
		|| texture->mipLevels == 0 || texture->arrayLayers == 0) return false;
	uint32_t state;
	switch (texture->state) {
	case VK_IMAGE_LAYOUT_GENERAL:
		state = (texture->usage & VK_IMAGE_USAGE_STORAGE_BIT) ? FFX_API_RESOURCE_STATE_UNORDERED_ACCESS : FFX_API_RESOURCE_STATE_GENERIC_READ;
		break;
	case VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL: state = FFX_API_RESOURCE_STATE_COMPUTE_READ; break;
	case VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL: state = FFX_API_RESOURCE_STATE_COPY_SRC; break;
	case VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL: state = FFX_API_RESOURCE_STATE_COPY_DEST; break;
	default: return false;
	}
	VkImageCreateInfo info{VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO};
	info.imageType = VK_IMAGE_TYPE_2D;
	info.format = static_cast<VkFormat>(texture->format);
	info.extent = {texture->width, texture->height, 1};
	info.mipLevels = texture->mipLevels;
	info.arrayLayers = texture->arrayLayers;
	info.usage = texture->usage;
	info.flags = texture->flags;
	const auto description = ffxApiGetImageResourceDescriptionVK(reinterpret_cast<VkImage>(texture->native), info, 0);
	if (description.format == FFX_API_SURFACE_FORMAT_UNKNOWN) return false;
	out = ffxApiGetResourceVK(texture->native, description, state);
	return true;
}

int evaluate(void* context, void* commands, FsrDispatchParams* params) {
	if (params->output->state != VK_IMAGE_LAYOUT_GENERAL || !(params->output->usage & VK_IMAGE_USAGE_STORAGE_BIT)) return FFX_API_RETURN_ERROR_PARAMETER;
	ffxDispatchDescUpscale desc{};
	desc.header.type = FFX_API_DISPATCH_DESC_TYPE_UPSCALE;
	desc.commandList = commands;
	if (!resource(params->color, desc.color) || !resource(params->depth, desc.depth)
		|| !resource(params->motionVectors, desc.motionVectors) || !resource(params->output, desc.output)
		|| !resource(params->exposure, desc.exposure) || !resource(params->reactive, desc.reactive)
		|| !resource(params->transparencyAndComposition, desc.transparencyAndComposition)) return FFX_API_RETURN_ERROR_PARAMETER;
	desc.jitterOffset = {params->jitterOffsetX, params->jitterOffsetY};
	desc.motionVectorScale = {params->motionVectorScaleX, params->motionVectorScaleY};
	desc.renderSize = {uint32_t(params->renderWidth), uint32_t(params->renderHeight)};
	desc.upscaleSize = {uint32_t(params->upscaleWidth), uint32_t(params->upscaleHeight)};
	desc.enableSharpening = params->enableSharpening;
	desc.sharpness = params->sharpness;
	desc.frameTimeDelta = params->frameTimeDelta;
	desc.preExposure = params->preExposure;
	desc.reset = params->reset;
	desc.cameraNear = params->cameraNear;
	desc.cameraFar = params->cameraFar;
	desc.cameraFovAngleVertical = params->cameraFovAngleVertical;
	desc.viewSpaceToMetersFactor = params->viewSpaceToMetersFactor;
	desc.flags = params->flags;
	return dispatch(&context, &desc.header);
}

vbyte* version(void* context) {
	ffxQueryGetProviderVersion desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_GET_PROVIDER_VERSION;
	if (query(&context, &desc.header) != 0 || desc.versionName == nullptr) return nullptr;
	return hl_copy_bytes(reinterpret_cast<const vbyte*>(desc.versionName), int(std::strlen(desc.versionName)) + 1);
}

int versionCount(PostProcessDevice* device, int effect, int* count) {
	*count = 0;
	if (effect != 0) return effect == 1 ? FFX_API_RETURN_OK : FFX_API_RETURN_ERROR_PARAMETER;
	auto backend = backendDesc(device);
	uint64_t size = 0;
	ffxQueryDescGetVersions desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_GET_VERSIONS;
	desc.header.pNext = &backend.header;
	desc.createDescType = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE;
	desc.device = device->device;
	desc.outputCount = &size;
	const int result = query(nullptr, &desc.header);
	*count = int(size);
	return result;
}

vbyte* versionName(PostProcessDevice* device, int effect, int index) {
	int count;
	if (versionCount(device, effect, &count) != 0 || index < 0 || index >= count) return nullptr;
	auto backend = backendDesc(device);
	uint64_t capacity = uint64_t(index) + 1;
	std::vector<const char*> names(capacity);
	ffxQueryDescGetVersions desc{};
	desc.header.type = FFX_API_QUERY_DESC_TYPE_GET_VERSIONS;
	desc.header.pNext = &backend.header;
	desc.createDescType = FFX_API_CREATE_CONTEXT_DESC_TYPE_UPSCALE;
	desc.device = device->device;
	desc.outputCount = &capacity;
	desc.versionNames = names.data();
	if (query(nullptr, &desc.header) != 0 || capacity <= uint64_t(index) || names[index] == nullptr) return nullptr;
	return hl_copy_bytes(reinterpret_cast<const vbyte*>(names[index]), int(std::strlen(names[index])) + 1);
}
}

const FsrBackend fsrVulkan{
	init, shutdown, renderResolution, create,
	[](void* context) { return int(destroyContext(&context, nullptr)); },
	version, evaluate, versionCount, versionName
};
