#if defined(_WIN32)
#define VK_USE_PLATFORM_WIN32_KHR
#elif defined(__APPLE__)
#define VK_USE_PLATFORM_METAL_EXT
#elif defined(__ANDROID__)
#define VK_USE_PLATFORM_ANDROID_KHR
#elif defined(__linux__)
#define VK_USE_PLATFORM_XLIB_KHR
#endif
#include <vulkan/vulkan.h>

#include <stdint.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <windows.h>
#endif

#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>

static VkInstance instance = nullptr;
static VkDebugUtilsMessengerEXT debug_messenger = nullptr;
static uint32_t instance_references = 0;
static uint32_t loader_api_version = VK_API_VERSION_1_0;
static uint32_t instance_api_version = 0;
static bool validation_enabled = false;
static bool surface_maintenance1_enabled = false;
static char last_error[2048];
static char instance_report[2048];

#if defined(_WIN32)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_WIN32_SURFACE_EXTENSION_NAME
#elif defined(__APPLE__)
#define HL_VK_PLATFORM_EXTENSION VK_EXT_METAL_SURFACE_EXTENSION_NAME
#elif defined(__ANDROID__)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_ANDROID_SURFACE_EXTENSION_NAME
#elif defined(__linux__)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_XLIB_SURFACE_EXTENSION_NAME
#else
#define HL_VK_PLATFORM_EXTENSION nullptr
#endif

VkInstance vk_get_instance() {
	return instance;
}

static const char* vk_result_name(VkResult result) {
	switch (result) {
	case VK_SUCCESS:
		return "VK_SUCCESS";
	case VK_NOT_READY:
		return "VK_NOT_READY";
	case VK_TIMEOUT:
		return "VK_TIMEOUT";
	case VK_INCOMPLETE:
		return "VK_INCOMPLETE";
	case VK_ERROR_OUT_OF_HOST_MEMORY:
		return "VK_ERROR_OUT_OF_HOST_MEMORY";
	case VK_ERROR_OUT_OF_DEVICE_MEMORY:
		return "VK_ERROR_OUT_OF_DEVICE_MEMORY";
	case VK_ERROR_INITIALIZATION_FAILED:
		return "VK_ERROR_INITIALIZATION_FAILED";
	case VK_ERROR_DEVICE_LOST:
		return "VK_ERROR_DEVICE_LOST";
	case VK_ERROR_LAYER_NOT_PRESENT:
		return "VK_ERROR_LAYER_NOT_PRESENT";
	case VK_ERROR_EXTENSION_NOT_PRESENT:
		return "VK_ERROR_EXTENSION_NOT_PRESENT";
	case VK_ERROR_FEATURE_NOT_PRESENT:
		return "VK_ERROR_FEATURE_NOT_PRESENT";
	case VK_ERROR_INCOMPATIBLE_DRIVER:
		return "VK_ERROR_INCOMPATIBLE_DRIVER";
	case VK_ERROR_SURFACE_LOST_KHR:
		return "VK_ERROR_SURFACE_LOST_KHR";
	case VK_ERROR_NATIVE_WINDOW_IN_USE_KHR:
		return "VK_ERROR_NATIVE_WINDOW_IN_USE_KHR";
	case VK_SUBOPTIMAL_KHR:
		return "VK_SUBOPTIMAL_KHR";
	case VK_ERROR_OUT_OF_DATE_KHR:
		return "VK_ERROR_OUT_OF_DATE_KHR";
	default:
		return "VK_ERROR_UNKNOWN";
	}
}

static void vk_clear_error() {
	last_error[0] = '\0';
}

static void vk_set_error(const char* format, ...) {
	va_list args;
	va_start(args, format);
	vsnprintf(last_error, sizeof(last_error), format, args);
	va_end(args);
}

static bool has_extension(const VkExtensionProperties* properties, uint32_t count, const char* name) {
	for (uint32_t i = 0; i < count; i++) {
		if (strcmp(properties[i].extensionName, name) == 0)
			return true;
	}
	return false;
}

static bool has_layer(const VkLayerProperties* properties, uint32_t count, const char* name) {
	for (uint32_t i = 0; i < count; i++) {
		if (strcmp(properties[i].layerName, name) == 0)
			return true;
	}
	return false;
}

static const char* validation_severity(VkDebugUtilsMessageSeverityFlagBitsEXT severity) {
	if (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT)
		return "ERROR";
	if (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT)
		return "WARNING";
	if (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT)
		return "INFO";
	return "VERBOSE";
}

static void validation_types(VkDebugUtilsMessageTypeFlagsEXT types, char* output, size_t capacity) {
	output[0] = '\0';
	if (types & VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT)
		strncat(output, "GENERAL|", capacity - strlen(output) - 1);
	if (types & VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT)
		strncat(output, "VALIDATION|", capacity - strlen(output) - 1);
	if (types & VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT)
		strncat(output, "PERFORMANCE|", capacity - strlen(output) - 1);
	if (strlen(output) > 0)
		output[strlen(output) - 1] = '\0';
}

static VKAPI_ATTR VkBool32 VKAPI_CALL validation_callback(
	VkDebugUtilsMessageSeverityFlagBitsEXT severity,
	VkDebugUtilsMessageTypeFlagsEXT types,
	const VkDebugUtilsMessengerCallbackDataEXT* callback_data,
	void* user_data
) {
	(void)user_data;
	char type_names[64];
	validation_types(types, type_names, sizeof(type_names));
	fprintf(
		stderr,
		"VULKAN_VALIDATION|%s|%s|%s|%s\n",
		validation_severity(severity),
		type_names,
		callback_data->pMessageIdName ? callback_data->pMessageIdName : "-",
		callback_data->pMessage ? callback_data->pMessage : ""
	);
	fflush(stderr);
	return VK_FALSE;
}

static VkDebugUtilsMessengerCreateInfoEXT debug_messenger_info() {
	return (VkDebugUtilsMessengerCreateInfoEXT) {
		.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
		.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
			VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
		.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
			VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
		.pfnUserCallback = validation_callback,
	};
}

HL_PRIM bool HL_NAME(vk_init)(bool enable_validation) {
	vk_clear_error();
	if (instance) {
		if (enable_validation && !validation_enabled) {
			vk_set_error("Vulkan was initialized without validation; recreate all Vulkan surfaces before enabling validation");
			return false;
		}
		instance_references++;
		return true;
	}
#if defined(_WIN32)
	if (GetEnvironmentVariableA("VK_LOADER_LAYERS_DISABLE", nullptr, 0) == 0 && GetLastError() == ERROR_ENVVAR_NOT_FOUND) {
		SetEnvironmentVariableA("VK_LOADER_LAYERS_DISABLE", "~implicit~");
	}
#endif

	PFN_vkEnumerateInstanceVersion enumerate_instance_version =
		(PFN_vkEnumerateInstanceVersion)vkGetInstanceProcAddr(nullptr, "vkEnumerateInstanceVersion");
	loader_api_version = VK_API_VERSION_1_0;
	if (enumerate_instance_version) {
		VkResult result = enumerate_instance_version(&loader_api_version);
		if (result != VK_SUCCESS) {
			vk_set_error("vkEnumerateInstanceVersion failed: %s (%d)", vk_result_name(result), result);
			return false;
		}
	}
	if (loader_api_version < VK_API_VERSION_1_3) {
		vk_set_error(
			"Vulkan 1.3 is required, but the loader provides %u.%u.%u",
			VK_API_VERSION_MAJOR(loader_api_version),
			VK_API_VERSION_MINOR(loader_api_version),
			VK_API_VERSION_PATCH(loader_api_version)
		);
		return false;
	}

	instance_api_version = VK_API_VERSION_1_3;
#ifdef VK_API_VERSION_1_4
	if (loader_api_version >= VK_API_VERSION_1_4)
		instance_api_version = VK_API_VERSION_1_4;
#endif

	uint32_t extension_count = 0;
	VkResult result = vkEnumerateInstanceExtensionProperties(nullptr, &extension_count, nullptr);
	if (result != VK_SUCCESS) {
		vk_set_error("Failed to enumerate Vulkan instance extensions: %s (%d)", vk_result_name(result), result);
		return false;
	}
	VkExtensionProperties* extension_properties = malloc(sizeof(VkExtensionProperties) * extension_count);
	result = vkEnumerateInstanceExtensionProperties(nullptr, &extension_count, extension_properties);
	if (result != VK_SUCCESS) {
		free(extension_properties);
		vk_set_error("Failed to read Vulkan instance extensions: %s (%d)", vk_result_name(result), result);
		return false;
	}

	const char* enabled_extensions[6];
	uint32_t enabled_extension_count = 0;
	const char* required_extensions[] = { VK_KHR_SURFACE_EXTENSION_NAME, HL_VK_PLATFORM_EXTENSION };
	for (uint32_t i = 0; i < 2; i++) {
		if (required_extensions[i] == nullptr || !has_extension(extension_properties, extension_count, required_extensions[i])) {
			vk_set_error("Required Vulkan instance extension is unavailable: %s", required_extensions[i] ? required_extensions[i] : "platform surface extension");
			free(extension_properties);
			return false;
		}
		enabled_extensions[enabled_extension_count++] = required_extensions[i];
	}
	surface_maintenance1_enabled =
		has_extension(extension_properties, extension_count, VK_KHR_GET_SURFACE_CAPABILITIES_2_EXTENSION_NAME) &&
		has_extension(extension_properties, extension_count, VK_KHR_SURFACE_MAINTENANCE_1_EXTENSION_NAME);
	if (surface_maintenance1_enabled) {
		enabled_extensions[enabled_extension_count++] = VK_KHR_GET_SURFACE_CAPABILITIES_2_EXTENSION_NAME;
		enabled_extensions[enabled_extension_count++] = VK_KHR_SURFACE_MAINTENANCE_1_EXTENSION_NAME;
	}
	if (enable_validation) {
		if (!has_extension(extension_properties, extension_count, VK_EXT_DEBUG_UTILS_EXTENSION_NAME)) {
			free(extension_properties);
			vk_set_error("Validation requested, but %s is unavailable", VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
			return false;
		}
		enabled_extensions[enabled_extension_count++] = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
	}
#if defined(__APPLE__)
	if (!has_extension(extension_properties, extension_count, VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME)) {
		free(extension_properties);
		vk_set_error("Required Vulkan instance extension is unavailable: %s", VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME);
		return false;
	}
	enabled_extensions[enabled_extension_count++] = VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME;
#endif
	free(extension_properties);

	const char* validation_layer = "VK_LAYER_KHRONOS_validation";
	if (enable_validation) {
		uint32_t layer_count = 0;
		result = vkEnumerateInstanceLayerProperties(&layer_count, nullptr);
		if (result != VK_SUCCESS) {
			vk_set_error("Failed to enumerate Vulkan instance layers: %s (%d)", vk_result_name(result), result);
			return false;
		}
		VkLayerProperties* layer_properties = malloc(sizeof(VkLayerProperties) * layer_count);
		result = vkEnumerateInstanceLayerProperties(&layer_count, layer_properties);
		if (result != VK_SUCCESS || !has_layer(layer_properties, layer_count, validation_layer)) {
			free(layer_properties);
			if (result != VK_SUCCESS)
				vk_set_error("Failed to read Vulkan instance layers: %s (%d)", vk_result_name(result), result);
			else
				vk_set_error("Validation requested, but %s is unavailable", validation_layer);
			return false;
		}
		free(layer_properties);
	}

	VkApplicationInfo appInfo = {
		.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
		.pApplicationName = "Limen Vulkan",
		.applicationVersion = VK_MAKE_VERSION(1, 0, 0),
		.pEngineName = "Heaps.io",
		.engineVersion = VK_MAKE_VERSION(1, 0, 0),
		.apiVersion = instance_api_version,
	};
	VkDebugUtilsMessengerCreateInfoEXT debug_info = debug_messenger_info();
	VkInstanceCreateInfo info = {
		.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
		.pNext = enable_validation ? &debug_info : nullptr,
#if defined(__APPLE__)
		.flags = VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
#endif
		.pApplicationInfo = &appInfo,
		.enabledLayerCount = enable_validation ? 1 : 0,
		.enabledExtensionCount = enabled_extension_count,
		.ppEnabledLayerNames = enable_validation ? &validation_layer : nullptr,
		.ppEnabledExtensionNames = enabled_extensions,
	};

	result = vkCreateInstance(&info, nullptr, &instance);
	if (result != VK_SUCCESS) {
		instance = nullptr;
		vk_set_error("vkCreateInstance failed: %s (%d)", vk_result_name(result), result);
		return false;
	}

	if (enable_validation) {
		PFN_vkCreateDebugUtilsMessengerEXT create_debug_messenger =
			(PFN_vkCreateDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
		if (!create_debug_messenger) {
			vkDestroyInstance(instance, nullptr);
			instance = nullptr;
			vk_set_error("%s was enabled, but vkCreateDebugUtilsMessengerEXT is unavailable", VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
			return false;
		}
		result = create_debug_messenger(instance, &debug_info, nullptr, &debug_messenger);
		if (result != VK_SUCCESS) {
			vkDestroyInstance(instance, nullptr);
			instance = nullptr;
			vk_set_error("vkCreateDebugUtilsMessengerEXT failed: %s (%d)", vk_result_name(result), result);
			return false;
		}
	}

	validation_enabled = enable_validation;
	instance_references = 1;
	snprintf(
		instance_report,
		sizeof(instance_report),
		"loader=%u.%u.%u;instance=%u.%u.%u;validation=%s;extensions=%s,%s%s%s%s%s",
		VK_API_VERSION_MAJOR(loader_api_version),
		VK_API_VERSION_MINOR(loader_api_version),
		VK_API_VERSION_PATCH(loader_api_version),
		VK_API_VERSION_MAJOR(instance_api_version),
		VK_API_VERSION_MINOR(instance_api_version),
		VK_API_VERSION_PATCH(instance_api_version),
		validation_enabled ? "true" : "false",
		VK_KHR_SURFACE_EXTENSION_NAME,
		HL_VK_PLATFORM_EXTENSION,
		surface_maintenance1_enabled ? "," VK_KHR_GET_SURFACE_CAPABILITIES_2_EXTENSION_NAME : "",
		surface_maintenance1_enabled ? "," VK_KHR_SURFACE_MAINTENANCE_1_EXTENSION_NAME : "",
		validation_enabled ? "," VK_EXT_DEBUG_UTILS_EXTENSION_NAME : "",
#if defined(__APPLE__)
		"," VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME
#else
		""
#endif
	);
	return true;
}

HL_PRIM void HL_NAME(vk_shutdown)() {
	if (!instance || instance_references == 0)
		return;
	instance_references--;
	if (instance_references > 0)
		return;
	if (debug_messenger) {
		PFN_vkDestroyDebugUtilsMessengerEXT destroy_debug_messenger =
			(PFN_vkDestroyDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
		if (destroy_debug_messenger)
			destroy_debug_messenger(instance, debug_messenger, nullptr);
		debug_messenger = nullptr;
	}
	vkDestroyInstance(instance, nullptr);
	instance = nullptr;
	validation_enabled = false;
	surface_maintenance1_enabled = false;
	instance_api_version = 0;
	instance_report[0] = '\0';
}

HL_PRIM void HL_NAME(vk_destroy_surface)(VkSurfaceKHR surface) {
	if (instance && surface)
		vkDestroySurfaceKHR(instance, surface, nullptr);
}

HL_PRIM vbyte* HL_NAME(vk_last_error)() {
	return hl_copy_bytes((const vbyte*)last_error, (int)strlen(last_error) + 1);
}

HL_PRIM vbyte* HL_NAME(vk_instance_report)() {
	return hl_copy_bytes((const vbyte*)instance_report, (int)strlen(instance_report) + 1);
}

HL_PRIM int HL_NAME(vk_loader_api_version)() {
	return (int)loader_api_version;
}

HL_PRIM int HL_NAME(vk_instance_api_version)() {
	return (int)instance_api_version;
}

HL_PRIM bool HL_NAME(vk_validation_enabled)() {
	return validation_enabled;
}

HL_PRIM vbyte* HL_NAME(vk_make_ref)(vdynamic* v) {
	if (v->t->kind != HSTRUCT)
		hl_error("assert");
	return v->v.ptr;
}

HL_PRIM vbyte* HL_NAME(vk_make_array)(varray* a) {
	if (a->size == 0)
		return nullptr;
	if (a->at->kind == HABSTRACT)
		return hl_copy_bytes(hl_aptr(a, vbyte), a->size * sizeof(void*));
	if (a->at->kind == HI32)
		return hl_copy_bytes(hl_aptr(a, vbyte), a->size * sizeof(int));
#ifdef HL_DEBUG
	if (a->at->kind != HSTRUCT)
		hl_error("assert");
#endif
	int size = a->at->obj->rt->size;
	vbyte* ptr = hl_alloc_bytes(size * a->size);
	int i;
	for (i = 0; i < a->size; i++)
		memcpy(ptr + i * size, hl_aptr(a, vbyte*)[i], size);
	return ptr;
}

// ------------------------------------------ CONTEXT INIT
// --------------------------------------------

typedef struct _VkContext {
	VkSurfaceKHR surface;
	VkPhysicalDevice pdevice;
	VkPhysicalDeviceProperties properties;
	VkPhysicalDeviceMemoryProperties memProps;
	VkDevice device;
	VkQueue graphics_queue;
	VkQueue present_queue;
	VkQueue compute_queue;
	VkQueue transfer_queue;
	uint32_t graphics_queue_family;
	uint32_t present_queue_family;
	uint32_t compute_queue_family;
	uint32_t transfer_queue_family;
	uint32_t graphics_timestamp_valid_bits;
	uint32_t capability_flags;
	VkPhysicalDeviceVulkan12Properties properties12;
	bool memory_budget;
	VkSwapchainKHR swapchain;
	VkSwapchainKHR* retired_swapchains;
	uint32_t retired_swapchain_count;
	uint32_t retired_swapchain_capacity;
	char report[8192];
	char wsi_report[1024];
}* VkContext;

enum {
	VK_CAP_DYNAMIC_RENDERING = 1 << 0,
	VK_CAP_SYNCHRONIZATION_2 = 1 << 1,
	VK_CAP_TIMELINE_SEMAPHORE = 1 << 2,
	VK_CAP_SWAPCHAIN_MAINTENANCE_1 = 1 << 3,
	VK_CAP_VULKAN_1_4 = 1 << 4,
	VK_CAP_PORTABILITY_SUBSET = 1 << 5,
	VK_CAP_SAMPLER_ANISOTROPY = 1 << 6,
	VK_CAP_INDEPENDENT_BLEND = 1 << 7,
	VK_CAP_DEPTH_CLAMP = 1 << 8,
	VK_CAP_FILL_MODE_NON_SOLID = 1 << 9,
	VK_CAP_MULTI_DRAW_INDIRECT = 1 << 10,
	VK_CAP_DRAW_INDIRECT_FIRST_INSTANCE = 1 << 11,
	VK_CAP_DRAW_INDIRECT_COUNT = 1 << 12,
	VK_CAP_OCCLUSION_QUERY_PRECISE = 1 << 13,
	VK_CAP_GRAPHICS_QUEUE_COMPUTE = 1 << 14,
	VK_CAP_DESCRIPTOR_INDEXING = 1 << 15,
	VK_CAP_SAMPLED_IMAGE_NON_UNIFORM = 1 << 16,
	VK_CAP_STORAGE_BUFFER_NON_UNIFORM = 1 << 17,
	VK_CAP_DESCRIPTOR_PARTIALLY_BOUND = 1 << 18,
	VK_CAP_SAMPLED_IMAGE_UPDATE_AFTER_BIND = 1 << 19,
	VK_CAP_STORAGE_BUFFER_UPDATE_AFTER_BIND = 1 << 20,
	VK_CAP_RUNTIME_DESCRIPTOR_ARRAY = 1 << 21,
	VK_CAP_VARIABLE_DESCRIPTOR_COUNT = 1 << 22,
	VK_CAP_UPDATE_UNUSED_WHILE_PENDING = 1 << 23,
};

typedef struct {
	VkPhysicalDevice handle;
	VkPhysicalDeviceProperties properties;
	VkPhysicalDeviceVulkan12Properties properties12;
	VkPhysicalDeviceMemoryProperties memory_properties;
	uint32_t graphics_queue_family;
	uint32_t present_queue_family;
	uint32_t compute_queue_family;
	uint32_t transfer_queue_family;
	VkQueueFlags graphics_queue_flags;
	VkQueueFlags compute_queue_flags;
	VkQueueFlags transfer_queue_flags;
	bool dynamic_rendering;
	bool synchronization2;
	bool timeline_semaphore;
	bool swapchain_maintenance1;
	bool portability_subset;
	bool memory_budget;
	bool sampler_anisotropy;
	bool independent_blend;
	bool depth_clamp;
	bool fill_mode_non_solid;
	bool multi_draw_indirect;
	bool draw_indirect_first_instance;
	bool draw_indirect_count;
	bool occlusion_query_precise;
	bool descriptor_indexing;
	bool sampled_image_non_uniform;
	bool storage_buffer_non_uniform;
	bool descriptor_partially_bound;
	bool sampled_image_update_after_bind;
	bool storage_buffer_update_after_bind;
	bool runtime_descriptor_array;
	bool variable_descriptor_count;
	bool update_unused_while_pending;
	uint32_t graphics_timestamp_valid_bits;
	int score;
} VkDeviceCandidate;

static void append_text(char* output, size_t capacity, const char* format, ...) {
	size_t length = strlen(output);
	if (length >= capacity - 1)
		return;
	va_list args;
	va_start(args, format);
	vsnprintf(output + length, capacity - length, format, args);
	va_end(args);
}

static void reject_device(char* reason, size_t capacity, const char* format, ...) {
	if (reason[0] != '\0')
		append_text(reason, capacity, ", ");
	va_list args;
	va_start(args, format);
	size_t length = strlen(reason);
	vsnprintf(reason + length, capacity - length, format, args);
	va_end(args);
}

static bool evaluate_device(
	VkPhysicalDevice device,
	VkSurfaceKHR surface,
	uint32_t required_capabilities,
	VkDeviceCandidate* candidate,
	char* rejection,
	size_t rejection_capacity
) {
	*candidate = (VkDeviceCandidate) {
		.handle = device,
		.graphics_queue_family = UINT32_MAX,
		.present_queue_family = UINT32_MAX,
		.compute_queue_family = UINT32_MAX,
		.transfer_queue_family = UINT32_MAX,
	};
	rejection[0] = '\0';

	vkGetPhysicalDeviceProperties(device, &candidate->properties);
	if (candidate->properties.apiVersion < VK_API_VERSION_1_3) {
		reject_device(
			rejection,
			rejection_capacity,
			"requires Vulkan 1.3 (device provides %u.%u.%u)",
			VK_API_VERSION_MAJOR(candidate->properties.apiVersion),
			VK_API_VERSION_MINOR(candidate->properties.apiVersion),
			VK_API_VERSION_PATCH(candidate->properties.apiVersion)
		);
	}

	VkPhysicalDeviceVulkan11Properties properties11 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_PROPERTIES,
	};
	candidate->properties12 = (VkPhysicalDeviceVulkan12Properties) {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_PROPERTIES,
	};
	VkPhysicalDeviceVulkan13Properties properties13 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_PROPERTIES,
	};
#ifdef VK_VERSION_1_4
	VkPhysicalDeviceVulkan14Properties properties14 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_4_PROPERTIES,
	};
	properties13.pNext = candidate->properties.apiVersion >= VK_API_VERSION_1_4 ? &properties14 : nullptr;
#endif
	candidate->properties12.pNext = &properties13;
	properties11.pNext = &candidate->properties12;
	VkPhysicalDeviceProperties2 properties2 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_PROPERTIES_2,
		.pNext = &properties11,
	};
	vkGetPhysicalDeviceProperties2(device, &properties2);
	candidate->properties = properties2.properties;

	VkPhysicalDeviceMemoryProperties2 memory2 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
	};
	vkGetPhysicalDeviceMemoryProperties2(device, &memory2);
	candidate->memory_properties = memory2.memoryProperties;

	uint32_t extension_count = 0;
	VkResult result = vkEnumerateDeviceExtensionProperties(device, nullptr, &extension_count, nullptr);
	if (result != VK_SUCCESS) {
		reject_device(rejection, rejection_capacity, "extension enumeration failed: %s (%d)", vk_result_name(result), result);
		return false;
	}
	VkExtensionProperties* extensions = malloc(sizeof(VkExtensionProperties) * extension_count);
	result = vkEnumerateDeviceExtensionProperties(device, nullptr, &extension_count, extensions);
	if (result != VK_SUCCESS) {
		free(extensions);
		reject_device(rejection, rejection_capacity, "extension query failed: %s (%d)", vk_result_name(result), result);
		return false;
	}
	if (!has_extension(extensions, extension_count, VK_KHR_SWAPCHAIN_EXTENSION_NAME))
		reject_device(rejection, rejection_capacity, "missing %s", VK_KHR_SWAPCHAIN_EXTENSION_NAME);
	candidate->swapchain_maintenance1 = surface_maintenance1_enabled && has_extension(extensions, extension_count, VK_KHR_SWAPCHAIN_MAINTENANCE_1_EXTENSION_NAME);
	candidate->portability_subset = has_extension(extensions, extension_count, "VK_KHR_portability_subset");
	candidate->memory_budget = has_extension(extensions, extension_count, VK_EXT_MEMORY_BUDGET_EXTENSION_NAME);
	free(extensions);

	VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR maintenance1 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SWAPCHAIN_MAINTENANCE_1_FEATURES_KHR,
	};
	VkPhysicalDeviceVulkan11Features features11 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_1_FEATURES,
	};
	VkPhysicalDeviceVulkan12Features features12 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
	};
	VkPhysicalDeviceVulkan13Features features13 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
	};
#ifdef VK_VERSION_1_4
	VkPhysicalDeviceVulkan14Features features14 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_4_FEATURES,
	};
	if (candidate->properties.apiVersion >= VK_API_VERSION_1_4) {
		features13.pNext = &features14;
		features14.pNext = candidate->swapchain_maintenance1 ? &maintenance1 : nullptr;
	} else
#endif
		features13.pNext = candidate->swapchain_maintenance1 ? &maintenance1 : nullptr;
	features12.pNext = &features13;
	features11.pNext = &features12;
	VkPhysicalDeviceFeatures2 features2 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
		.pNext = &features11,
	};
	vkGetPhysicalDeviceFeatures2(device, &features2);
	candidate->dynamic_rendering = features13.dynamicRendering;
	candidate->synchronization2 = features13.synchronization2;
	candidate->timeline_semaphore = features12.timelineSemaphore;
	candidate->sampler_anisotropy = features2.features.samplerAnisotropy;
	candidate->independent_blend = features2.features.independentBlend;
	candidate->depth_clamp = features2.features.depthClamp;
	candidate->fill_mode_non_solid = features2.features.fillModeNonSolid;
	candidate->multi_draw_indirect = features2.features.multiDrawIndirect;
	candidate->draw_indirect_first_instance = features2.features.drawIndirectFirstInstance;
	candidate->draw_indirect_count = features12.drawIndirectCount;
	candidate->occlusion_query_precise = features2.features.occlusionQueryPrecise;
	candidate->descriptor_indexing = features12.descriptorIndexing;
	candidate->sampled_image_non_uniform = features12.shaderSampledImageArrayNonUniformIndexing;
	candidate->storage_buffer_non_uniform = features12.shaderStorageBufferArrayNonUniformIndexing;
	candidate->descriptor_partially_bound = features12.descriptorBindingPartiallyBound;
	candidate->sampled_image_update_after_bind = features12.descriptorBindingSampledImageUpdateAfterBind;
	candidate->storage_buffer_update_after_bind = features12.descriptorBindingStorageBufferUpdateAfterBind;
	candidate->runtime_descriptor_array = features12.runtimeDescriptorArray;
	candidate->variable_descriptor_count = features12.descriptorBindingVariableDescriptorCount;
	candidate->update_unused_while_pending = features12.descriptorBindingUpdateUnusedWhilePending;
	candidate->swapchain_maintenance1 = candidate->swapchain_maintenance1 && maintenance1.swapchainMaintenance1;
	if ((required_capabilities & VK_CAP_DYNAMIC_RENDERING) && !candidate->dynamic_rendering)
		reject_device(rejection, rejection_capacity, "missing dynamicRendering");
	if ((required_capabilities & VK_CAP_SYNCHRONIZATION_2) && !candidate->synchronization2)
		reject_device(rejection, rejection_capacity, "missing synchronization2");
	if ((required_capabilities & VK_CAP_TIMELINE_SEMAPHORE) && !candidate->timeline_semaphore)
		reject_device(rejection, rejection_capacity, "missing timelineSemaphore");
	if ((required_capabilities & VK_CAP_SWAPCHAIN_MAINTENANCE_1) && !candidate->swapchain_maintenance1)
		reject_device(rejection, rejection_capacity, "missing swapchainMaintenance1");
	if ((required_capabilities & VK_CAP_VULKAN_1_4) && candidate->properties.apiVersion < VK_API_VERSION_1_4)
		reject_device(rejection, rejection_capacity, "requires Vulkan 1.4");
	if ((required_capabilities & VK_CAP_PORTABILITY_SUBSET) && !candidate->portability_subset)
		reject_device(rejection, rejection_capacity, "missing portabilitySubset");

	uint32_t queue_count = 0;
	vkGetPhysicalDeviceQueueFamilyProperties2(device, &queue_count, nullptr);
	VkQueueFamilyProperties2* queues = malloc(sizeof(VkQueueFamilyProperties2) * queue_count);
	for (uint32_t i = 0; i < queue_count; i++)
		queues[i] = (VkQueueFamilyProperties2) { .sType = VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2 };
	vkGetPhysicalDeviceQueueFamilyProperties2(device, &queue_count, queues);
	for (uint32_t i = 0; i < queue_count; i++) {
		VkQueueFlags flags = queues[i].queueFamilyProperties.queueFlags;
		if ((flags & VK_QUEUE_GRAPHICS_BIT) && (candidate->graphics_queue_family == UINT32_MAX
			|| (!(candidate->graphics_queue_flags & VK_QUEUE_COMPUTE_BIT) && (flags & VK_QUEUE_COMPUTE_BIT)))) {
			candidate->graphics_queue_family = i;
			candidate->graphics_queue_flags = flags;
			candidate->graphics_timestamp_valid_bits = queues[i].queueFamilyProperties.timestampValidBits;
		}
		VkBool32 present = VK_FALSE;
		result = vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &present);
		if (result != VK_SUCCESS) {
			free(queues);
			reject_device(rejection, rejection_capacity, "surface support query failed: %s (%d)", vk_result_name(result), result);
			return false;
		}
		if (candidate->present_queue_family == UINT32_MAX && present)
			candidate->present_queue_family = i;
		if (flags & VK_QUEUE_COMPUTE_BIT) {
			if (candidate->compute_queue_family == UINT32_MAX || !(flags & VK_QUEUE_GRAPHICS_BIT)) {
				candidate->compute_queue_family = i;
				candidate->compute_queue_flags = flags;
			}
		}
		if (flags & VK_QUEUE_TRANSFER_BIT) {
			if (candidate->transfer_queue_family == UINT32_MAX || !(flags & (VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT))) {
				candidate->transfer_queue_family = i;
				candidate->transfer_queue_flags = flags;
			}
		}
	}
	free(queues);
	if (candidate->graphics_queue_family == UINT32_MAX)
		reject_device(rejection, rejection_capacity, "no graphics queue");
	if (candidate->present_queue_family == UINT32_MAX)
		reject_device(rejection, rejection_capacity, "no present queue");

	uint32_t format_count = 0;
	result = vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &format_count, nullptr);
	if (result != VK_SUCCESS)
		reject_device(rejection, rejection_capacity, "surface format query failed: %s (%d)", vk_result_name(result), result);
	else if (format_count == 0)
		reject_device(rejection, rejection_capacity, "surface has no formats");
	uint32_t present_mode_count = 0;
	result = vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &present_mode_count, nullptr);
	if (result != VK_SUCCESS)
		reject_device(rejection, rejection_capacity, "present mode query failed: %s (%d)", vk_result_name(result), result);
	else if (present_mode_count == 0)
		reject_device(rejection, rejection_capacity, "surface has no present modes");

	if (rejection[0] != '\0')
		return false;
	candidate->score = (int)candidate->properties.limits.maxImageDimension2D;
	if (candidate->properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU)
		candidate->score += 100000;
	else if (candidate->properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU)
		candidate->score += 50000;
	return true;
}

HL_PRIM VkContext HL_NAME(vk_init_context)(VkSurfaceKHR surface, int* outQueue, int required_capability_flags) {
	vk_clear_error();
	const uint32_t known_capabilities = VK_CAP_DYNAMIC_RENDERING | VK_CAP_SYNCHRONIZATION_2 |
		VK_CAP_TIMELINE_SEMAPHORE | VK_CAP_SWAPCHAIN_MAINTENANCE_1 |
		VK_CAP_VULKAN_1_4 | VK_CAP_PORTABILITY_SUBSET;
	if (((uint32_t)required_capability_flags & ~known_capabilities) != 0) {
		vk_set_error("Unknown Vulkan capability requirement mask: 0x%08x", required_capability_flags);
		return nullptr;
	}
	if (!instance || !surface) {
		vk_set_error("Cannot create a Vulkan context without an initialized instance and surface");
		return nullptr;
	}

	uint32_t device_count = 0;
	VkResult result = vkEnumeratePhysicalDevices(instance, &device_count, nullptr);
	if (result != VK_SUCCESS || device_count == 0) {
		vk_set_error(
			result == VK_SUCCESS ? "No Vulkan physical devices were found" : "Failed to enumerate Vulkan physical devices: %s (%d)",
			vk_result_name(result),
			result
		);
		return nullptr;
	}
	VkPhysicalDevice* devices = malloc(sizeof(VkPhysicalDevice) * device_count);
	result = vkEnumeratePhysicalDevices(instance, &device_count, devices);
	if (result != VK_SUCCESS) {
		free(devices);
		vk_set_error("Failed to read Vulkan physical devices: %s (%d)", vk_result_name(result), result);
		return nullptr;
	}

	VkDeviceCandidate selected = {};
	char selection_report[8192] = {};
	for (uint32_t i = 0; i < device_count; i++) {
		VkDeviceCandidate candidate;
		char rejection[1024];
		bool accepted = evaluate_device(devices[i], surface, (uint32_t)required_capability_flags, &candidate, rejection, sizeof(rejection));
		append_text(
			selection_report,
			sizeof(selection_report),
			"candidate[%u]=%s;%s=%s%s",
			i,
			candidate.properties.deviceName,
			accepted ? "accepted" : "rejected",
			accepted ? "true" : rejection,
			i + 1 == device_count ? "" : "\n"
		);
		if (accepted && (!selected.handle || candidate.score > selected.score))
			selected = candidate;
	}
	free(devices);
	if (!selected.handle) {
		vk_set_error("No Vulkan device satisfies the renderer contract: %s", selection_report);
		return nullptr;
	}

	uint32_t queue_candidates[] = {
		selected.graphics_queue_family,
		selected.present_queue_family,
		selected.compute_queue_family,
		selected.transfer_queue_family,
	};
	uint32_t unique_queues[4];
	uint32_t unique_queue_count = 0;
	for (uint32_t i = 0; i < 4; i++) {
		if (queue_candidates[i] == UINT32_MAX)
			continue;
		bool duplicate = false;
		for (uint32_t j = 0; j < unique_queue_count; j++)
			duplicate |= unique_queues[j] == queue_candidates[i];
		if (!duplicate)
			unique_queues[unique_queue_count++] = queue_candidates[i];
	}
	float queue_priority = 1.0f;
	VkDeviceQueueCreateInfo queue_infos[4];
	for (uint32_t i = 0; i < unique_queue_count; i++) {
		queue_infos[i] = (VkDeviceQueueCreateInfo) {
			.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
			.queueFamilyIndex = unique_queues[i],
			.queueCount = 1,
			.pQueuePriorities = &queue_priority,
		};
	}

	const char* enabled_extensions[4] = { VK_KHR_SWAPCHAIN_EXTENSION_NAME };
	uint32_t enabled_extension_count = 1;
	if (selected.swapchain_maintenance1)
		enabled_extensions[enabled_extension_count++] = VK_KHR_SWAPCHAIN_MAINTENANCE_1_EXTENSION_NAME;
	if (selected.portability_subset)
		enabled_extensions[enabled_extension_count++] = "VK_KHR_portability_subset";
	if (selected.memory_budget)
		enabled_extensions[enabled_extension_count++] = VK_EXT_MEMORY_BUDGET_EXTENSION_NAME;

	VkPhysicalDeviceSwapchainMaintenance1FeaturesKHR maintenance1 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_SWAPCHAIN_MAINTENANCE_1_FEATURES_KHR,
		.swapchainMaintenance1 = selected.swapchain_maintenance1,
	};
	VkPhysicalDeviceVulkan12Features features12 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_2_FEATURES,
		.pNext = nullptr,
		.timelineSemaphore = VK_TRUE,
		.drawIndirectCount = selected.draw_indirect_count,
		.descriptorIndexing = selected.descriptor_indexing,
		.shaderSampledImageArrayNonUniformIndexing = selected.sampled_image_non_uniform,
		.shaderStorageBufferArrayNonUniformIndexing = selected.storage_buffer_non_uniform,
		.descriptorBindingSampledImageUpdateAfterBind = selected.sampled_image_update_after_bind,
		.descriptorBindingStorageBufferUpdateAfterBind = selected.storage_buffer_update_after_bind,
		.descriptorBindingUpdateUnusedWhilePending = selected.update_unused_while_pending,
		.descriptorBindingPartiallyBound = selected.descriptor_partially_bound,
		.descriptorBindingVariableDescriptorCount = selected.variable_descriptor_count,
		.runtimeDescriptorArray = selected.runtime_descriptor_array,
	};
	VkPhysicalDeviceVulkan13Features features13 = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_VULKAN_1_3_FEATURES,
		.pNext = selected.swapchain_maintenance1 ? &maintenance1 : nullptr,
		.synchronization2 = VK_TRUE,
		.dynamicRendering = VK_TRUE,
	};
	features12.pNext = &features13;
	VkPhysicalDeviceFeatures2 enabled_features = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2,
		.pNext = &features12,
		.features = {
			.samplerAnisotropy = selected.sampler_anisotropy,
			.independentBlend = selected.independent_blend,
			.depthClamp = selected.depth_clamp,
			.fillModeNonSolid = selected.fill_mode_non_solid,
			.multiDrawIndirect = selected.multi_draw_indirect,
			.drawIndirectFirstInstance = selected.draw_indirect_first_instance,
			.occlusionQueryPrecise = selected.occlusion_query_precise,
		},
	};
	VkDeviceCreateInfo device_info = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		.pNext = &enabled_features,
		.queueCreateInfoCount = unique_queue_count,
		.pQueueCreateInfos = queue_infos,
		.enabledExtensionCount = enabled_extension_count,
		.ppEnabledExtensionNames = enabled_extensions,
	};

	VkContext ctx = malloc(sizeof(struct _VkContext));
	if (!ctx) {
		vk_set_error("Failed to allocate Vulkan context state");
		return nullptr;
	}
	*ctx = (struct _VkContext) {
		.surface = surface,
		.pdevice = selected.handle,
		.properties = selected.properties,
		.memProps = selected.memory_properties,
		.graphics_queue_family = selected.graphics_queue_family,
		.present_queue_family = selected.present_queue_family,
		.compute_queue_family = selected.compute_queue_family,
		.transfer_queue_family = selected.transfer_queue_family,
		.graphics_timestamp_valid_bits = selected.graphics_timestamp_valid_bits,
		.properties12 = selected.properties12,
		.memory_budget = selected.memory_budget,
	};
	result = vkCreateDevice(ctx->pdevice, &device_info, nullptr, &ctx->device);
	if (result != VK_SUCCESS) {
		free(ctx);
		vk_set_error("vkCreateDevice failed for %s: %s (%d)", selected.properties.deviceName, vk_result_name(result), result);
		return nullptr;
	}

	vkGetDeviceQueue(ctx->device, ctx->graphics_queue_family, 0, &ctx->graphics_queue);
	vkGetDeviceQueue(ctx->device, ctx->present_queue_family, 0, &ctx->present_queue);
	if (ctx->compute_queue_family != UINT32_MAX)
		vkGetDeviceQueue(ctx->device, ctx->compute_queue_family, 0, &ctx->compute_queue);
	if (ctx->transfer_queue_family != UINT32_MAX)
		vkGetDeviceQueue(ctx->device, ctx->transfer_queue_family, 0, &ctx->transfer_queue);
	ctx->capability_flags = VK_CAP_DYNAMIC_RENDERING | VK_CAP_SYNCHRONIZATION_2 | VK_CAP_TIMELINE_SEMAPHORE;
	if (selected.swapchain_maintenance1)
		ctx->capability_flags |= VK_CAP_SWAPCHAIN_MAINTENANCE_1;
	if (selected.properties.apiVersion >= VK_API_VERSION_1_4)
		ctx->capability_flags |= VK_CAP_VULKAN_1_4;
	if (selected.portability_subset)
		ctx->capability_flags |= VK_CAP_PORTABILITY_SUBSET;
	if (selected.sampler_anisotropy)
		ctx->capability_flags |= VK_CAP_SAMPLER_ANISOTROPY;
	if (selected.independent_blend)
		ctx->capability_flags |= VK_CAP_INDEPENDENT_BLEND;
	if (selected.depth_clamp)
		ctx->capability_flags |= VK_CAP_DEPTH_CLAMP;
	if (selected.fill_mode_non_solid)
		ctx->capability_flags |= VK_CAP_FILL_MODE_NON_SOLID;
	if (selected.multi_draw_indirect)
		ctx->capability_flags |= VK_CAP_MULTI_DRAW_INDIRECT;
	if (selected.draw_indirect_first_instance)
		ctx->capability_flags |= VK_CAP_DRAW_INDIRECT_FIRST_INSTANCE;
	if (selected.draw_indirect_count)
		ctx->capability_flags |= VK_CAP_DRAW_INDIRECT_COUNT;
	if (selected.occlusion_query_precise)
		ctx->capability_flags |= VK_CAP_OCCLUSION_QUERY_PRECISE;
	if (selected.graphics_queue_flags & VK_QUEUE_COMPUTE_BIT)
		ctx->capability_flags |= VK_CAP_GRAPHICS_QUEUE_COMPUTE;
	if (selected.descriptor_indexing)
		ctx->capability_flags |= VK_CAP_DESCRIPTOR_INDEXING;
	if (selected.sampled_image_non_uniform)
		ctx->capability_flags |= VK_CAP_SAMPLED_IMAGE_NON_UNIFORM;
	if (selected.storage_buffer_non_uniform)
		ctx->capability_flags |= VK_CAP_STORAGE_BUFFER_NON_UNIFORM;
	if (selected.descriptor_partially_bound)
		ctx->capability_flags |= VK_CAP_DESCRIPTOR_PARTIALLY_BOUND;
	if (selected.sampled_image_update_after_bind)
		ctx->capability_flags |= VK_CAP_SAMPLED_IMAGE_UPDATE_AFTER_BIND;
	if (selected.storage_buffer_update_after_bind)
		ctx->capability_flags |= VK_CAP_STORAGE_BUFFER_UPDATE_AFTER_BIND;
	if (selected.runtime_descriptor_array)
		ctx->capability_flags |= VK_CAP_RUNTIME_DESCRIPTOR_ARRAY;
	if (selected.variable_descriptor_count)
		ctx->capability_flags |= VK_CAP_VARIABLE_DESCRIPTOR_COUNT;
	if (selected.update_unused_while_pending)
		ctx->capability_flags |= VK_CAP_UPDATE_UNUSED_WHILE_PENDING;
	char extension_report[256] = {};
	for (uint32_t i = 0; i < enabled_extension_count; i++)
		append_text(extension_report, sizeof(extension_report), "%s%s", i == 0 ? "" : ",", enabled_extensions[i]);
	snprintf(
		ctx->report,
		sizeof(ctx->report),
		"device=%s;vendor=0x%04x;deviceId=0x%04x;driver=%u;api=%u.%u.%u;deviceExtensions=%s;enabledFeatures=dynamicRendering,synchronization2,timelineSemaphore%s%s%s%s%s%s%s%s%s%s;graphicsQueue=%u;graphicsQueueFlags=0x%x;graphicsQueueCompute=%s;presentQueue=%u;computeQueue=%u;computeQueueFlags=0x%x;transferQueue=%u;transferQueueFlags=0x%x;dynamicRendering=true;synchronization2=true;timelineSemaphore=true;swapchainMaintenance1=%s;portabilitySubset=%s;samplerAnisotropy=%s;independentBlend=%s;depthClamp=%s;fillModeNonSolid=%s;multiDrawIndirect=%s;drawIndirectFirstInstance=%s;drawIndirectCount=%s;timestampValidBits=%u;timestampPeriod=%.9g;occlusionQueryPrecise=%s;descriptorIndexing=%s;shaderSampledImageArrayNonUniformIndexing=%s;shaderStorageBufferArrayNonUniformIndexing=%s;descriptorBindingPartiallyBound=%s;descriptorBindingSampledImageUpdateAfterBind=%s;descriptorBindingStorageBufferUpdateAfterBind=%s;runtimeDescriptorArray=%s;descriptorBindingVariableDescriptorCount=%s;descriptorBindingUpdateUnusedWhilePending=%s;maxUpdateAfterBindDescriptorsInAllPools=%u;maxPerStageUpdateAfterBindResources=%u;maxPerStageDescriptorUpdateAfterBindSamplers=%u;maxPerStageDescriptorUpdateAfterBindSampledImages=%u;maxPerStageDescriptorUpdateAfterBindStorageBuffers=%u;maxDescriptorSetUpdateAfterBindSamplers=%u;maxDescriptorSetUpdateAfterBindSampledImages=%u;maxDescriptorSetUpdateAfterBindStorageBuffers=%u\n%s",
		selected.properties.deviceName,
		selected.properties.vendorID,
		selected.properties.deviceID,
		selected.properties.driverVersion,
		VK_API_VERSION_MAJOR(selected.properties.apiVersion),
		VK_API_VERSION_MINOR(selected.properties.apiVersion),
		VK_API_VERSION_PATCH(selected.properties.apiVersion),
		extension_report,
		selected.swapchain_maintenance1 ? ",swapchainMaintenance1" : "",
		selected.sampler_anisotropy ? ",samplerAnisotropy" : "",
		selected.independent_blend ? ",independentBlend" : "",
		selected.depth_clamp ? ",depthClamp" : "",
		selected.fill_mode_non_solid ? ",fillModeNonSolid" : "",
		selected.multi_draw_indirect ? ",multiDrawIndirect" : "",
		selected.draw_indirect_first_instance ? ",drawIndirectFirstInstance" : "",
		selected.draw_indirect_count ? ",drawIndirectCount" : "",
		selected.occlusion_query_precise ? ",occlusionQueryPrecise" : "",
		selected.descriptor_indexing ? ",descriptorIndexing" : "",
		ctx->graphics_queue_family,
		selected.graphics_queue_flags,
		(selected.graphics_queue_flags & VK_QUEUE_COMPUTE_BIT) ? "true" : "false",
		ctx->present_queue_family,
		ctx->compute_queue_family,
		selected.compute_queue_flags,
		ctx->transfer_queue_family,
		selected.transfer_queue_flags,
		selected.swapchain_maintenance1 ? "true" : "false",
		selected.portability_subset ? "true" : "false",
		selected.sampler_anisotropy ? "true" : "false",
		selected.independent_blend ? "true" : "false",
		selected.depth_clamp ? "true" : "false",
		selected.fill_mode_non_solid ? "true" : "false",
		selected.multi_draw_indirect ? "true" : "false",
		selected.draw_indirect_first_instance ? "true" : "false",
		selected.draw_indirect_count ? "true" : "false",
		selected.graphics_timestamp_valid_bits,
		selected.properties.limits.timestampPeriod,
		selected.occlusion_query_precise ? "true" : "false",
		selected.descriptor_indexing ? "true" : "false",
		selected.sampled_image_non_uniform ? "true" : "false",
		selected.storage_buffer_non_uniform ? "true" : "false",
		selected.descriptor_partially_bound ? "true" : "false",
		selected.sampled_image_update_after_bind ? "true" : "false",
		selected.storage_buffer_update_after_bind ? "true" : "false",
		selected.runtime_descriptor_array ? "true" : "false",
		selected.variable_descriptor_count ? "true" : "false",
		selected.update_unused_while_pending ? "true" : "false",
		selected.properties12.maxUpdateAfterBindDescriptorsInAllPools,
		selected.properties12.maxPerStageUpdateAfterBindResources,
		selected.properties12.maxPerStageDescriptorUpdateAfterBindSamplers,
		selected.properties12.maxPerStageDescriptorUpdateAfterBindSampledImages,
		selected.properties12.maxPerStageDescriptorUpdateAfterBindStorageBuffers,
		selected.properties12.maxDescriptorSetUpdateAfterBindSamplers,
		selected.properties12.maxDescriptorSetUpdateAfterBindSampledImages,
		selected.properties12.maxDescriptorSetUpdateAfterBindStorageBuffers,
		selection_report
	);
	*outQueue = (int)ctx->graphics_queue_family;
	return ctx;
}

HL_PRIM bool HL_NAME(vk_destroy_context)(VkContext ctx) {
	if (!ctx)
		return true;
	vk_clear_error();
	VkResult result = vkDeviceWaitIdle(ctx->device);
	if (ctx->swapchain)
		vkDestroySwapchainKHR(ctx->device, ctx->swapchain, nullptr);
	for (uint32_t i = 0; i < ctx->retired_swapchain_count; i++)
		vkDestroySwapchainKHR(ctx->device, ctx->retired_swapchains[i], nullptr);
	free(ctx->retired_swapchains);
	vkDestroyDevice(ctx->device, nullptr);
	free(ctx);
	if (result != VK_SUCCESS) {
		vk_set_error("vkDeviceWaitIdle during context shutdown failed: %s (%d)", vk_result_name(result), result);
		return false;
	}
	return true;
}

HL_PRIM vbyte* HL_NAME(vk_get_context_report)(VkContext ctx) {
	char report[sizeof(ctx->report) + sizeof(ctx->wsi_report) + 2];
	snprintf(report, sizeof(report), "%s%s%s", ctx->report, ctx->wsi_report[0] ? "\n" : "", ctx->wsi_report);
	return hl_copy_bytes((const vbyte*)report, (int)strlen(report) + 1);
}

HL_PRIM int HL_NAME(vk_get_capability_flags)(VkContext ctx) {
	return (int)ctx->capability_flags;
}

static int vk_limit_as_haxe_int(uint32_t value) {
	return value > INT32_MAX ? INT32_MAX : (int)value;
}

HL_PRIM int HL_NAME(vk_get_max_update_after_bind_descriptors)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxUpdateAfterBindDescriptorsInAllPools);
}

HL_PRIM int HL_NAME(vk_get_max_per_stage_update_after_bind_resources)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxPerStageUpdateAfterBindResources);
}

HL_PRIM int HL_NAME(vk_get_max_per_stage_update_after_bind_samplers)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxPerStageDescriptorUpdateAfterBindSamplers);
}

HL_PRIM int HL_NAME(vk_get_max_per_stage_update_after_bind_sampled_images)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxPerStageDescriptorUpdateAfterBindSampledImages);
}

HL_PRIM int HL_NAME(vk_get_max_per_stage_update_after_bind_storage_buffers)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxPerStageDescriptorUpdateAfterBindStorageBuffers);
}

HL_PRIM int HL_NAME(vk_get_max_update_after_bind_samplers)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxDescriptorSetUpdateAfterBindSamplers);
}

HL_PRIM int HL_NAME(vk_get_max_update_after_bind_sampled_images)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxDescriptorSetUpdateAfterBindSampledImages);
}

HL_PRIM int HL_NAME(vk_get_max_update_after_bind_storage_buffers)(VkContext ctx) {
	return vk_limit_as_haxe_int(ctx->properties12.maxDescriptorSetUpdateAfterBindStorageBuffers);
}

HL_PRIM int HL_NAME(vk_get_device_api_version)(VkContext ctx) {
	return (int)ctx->properties.apiVersion;
}

HL_PRIM int HL_NAME(vk_get_vendor_id)(VkContext ctx) {
	return (int)ctx->properties.vendorID;
}

HL_PRIM int HL_NAME(vk_get_device_id)(VkContext ctx) {
	return (int)ctx->properties.deviceID;
}

HL_PRIM int HL_NAME(vk_get_driver_version)(VkContext ctx) {
	return (int)ctx->properties.driverVersion;
}

HL_PRIM int HL_NAME(vk_get_graphics_queue_family)(VkContext ctx) {
	return (int)ctx->graphics_queue_family;
}

HL_PRIM int HL_NAME(vk_get_present_queue_family)(VkContext ctx) {
	return (int)ctx->present_queue_family;
}

HL_PRIM int HL_NAME(vk_get_compute_queue_family)(VkContext ctx) {
	return ctx->compute_queue_family == UINT32_MAX ? -1 : (int)ctx->compute_queue_family;
}

HL_PRIM int HL_NAME(vk_get_transfer_queue_family)(VkContext ctx) {
	return ctx->transfer_queue_family == UINT32_MAX ? -1 : (int)ctx->transfer_queue_family;
}

HL_PRIM int HL_NAME(vk_get_graphics_timestamp_valid_bits)(VkContext ctx) {
	return (int)ctx->graphics_timestamp_valid_bits;
}

HL_PRIM double HL_NAME(vk_get_timestamp_period)(VkContext ctx) {
	return (double)ctx->properties.limits.timestampPeriod;
}

HL_PRIM vbyte* HL_NAME(vk_get_device_name)(VkContext ctx) {
	return hl_copy_bytes(ctx->properties.deviceName, (int)strlen(ctx->properties.deviceName) + 1);
}

HL_PRIM VkPhysicalDeviceLimits* HL_NAME(vk_get_limits)(VkContext ctx) {
	return (VkPhysicalDeviceLimits*)hl_copy_bytes((vbyte*)&ctx->properties.limits, sizeof(VkPhysicalDeviceLimits));
}

HL_PRIM int HL_NAME(vk_get_memory_type_count)(VkContext ctx) {
	return (int)ctx->memProps.memoryTypeCount;
}

HL_PRIM int HL_NAME(vk_get_memory_type_properties)(VkContext ctx, int index) {
	if (index < 0 || (uint32_t)index >= ctx->memProps.memoryTypeCount)
		return 0;
	return (int)ctx->memProps.memoryTypes[index].propertyFlags;
}

HL_PRIM int HL_NAME(vk_get_memory_type_heap_index)(VkContext ctx, int index) {
	if (index < 0 || (uint32_t)index >= ctx->memProps.memoryTypeCount)
		return -1;
	return (int)ctx->memProps.memoryTypes[index].heapIndex;
}

HL_PRIM int HL_NAME(vk_get_memory_heap_count)(VkContext ctx) {
	return (int)ctx->memProps.memoryHeapCount;
}

HL_PRIM int64_t HL_NAME(vk_get_memory_heap_size)(VkContext ctx, int index) {
	if (index < 0 || (uint32_t)index >= ctx->memProps.memoryHeapCount)
		return 0;
	return (int64_t)ctx->memProps.memoryHeaps[index].size;
}

HL_PRIM int HL_NAME(vk_get_memory_heap_flags)(VkContext ctx, int index) {
	if (index < 0 || (uint32_t)index >= ctx->memProps.memoryHeapCount)
		return 0;
	return (int)ctx->memProps.memoryHeaps[index].flags;
}

typedef struct {
	int64_t budget;
	int64_t usage;
} HLVkMemoryHeapBudgetInfo;

HL_PRIM bool HL_NAME(vk_has_memory_budget)(VkContext ctx) {
	return ctx->memory_budget;
}

HL_PRIM bool HL_NAME(vk_get_memory_heap_budget)(VkContext ctx, int index, HLVkMemoryHeapBudgetInfo* output) {
	if (index < 0 || (uint32_t)index >= ctx->memProps.memoryHeapCount || !output)
		return false;
	if (!ctx->memory_budget) {
		output->budget = (int64_t)ctx->memProps.memoryHeaps[index].size;
		output->usage = 0;
		return false;
	}

	VkPhysicalDeviceMemoryBudgetPropertiesEXT budget = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_BUDGET_PROPERTIES_EXT,
	};
	VkPhysicalDeviceMemoryProperties2 properties = {
		.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_MEMORY_PROPERTIES_2,
		.pNext = &budget,
	};
	vkGetPhysicalDeviceMemoryProperties2(ctx->pdevice, &properties);
	output->budget = (int64_t)budget.heapBudget[index];
	output->usage = (int64_t)budget.heapUsage[index];
	return true;
}

static bool set_object_name(VkContext ctx, VkObjectType type, uint64_t handle, vbyte* name) {
	if (!validation_enabled || !handle || !name)
		return false;
	PFN_vkSetDebugUtilsObjectNameEXT set_name =
		(PFN_vkSetDebugUtilsObjectNameEXT)vkGetDeviceProcAddr(ctx->device, "vkSetDebugUtilsObjectNameEXT");
	if (!set_name)
		return false;
	VkDebugUtilsObjectNameInfoEXT info = {
		.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_OBJECT_NAME_INFO_EXT,
		.objectType = type,
		.objectHandle = handle,
		.pObjectName = (const char*)name,
	};
	VkResult result = set_name(ctx->device, &info);
	return result == VK_SUCCESS;
}

HL_PRIM bool HL_NAME(vk_set_buffer_name)(VkContext ctx, VkBuffer buffer, vbyte* name) {
	return set_object_name(ctx, VK_OBJECT_TYPE_BUFFER, (uint64_t)buffer, name);
}

HL_PRIM bool HL_NAME(vk_set_image_name)(VkContext ctx, VkImage image, vbyte* name) {
	return set_object_name(ctx, VK_OBJECT_TYPE_IMAGE, (uint64_t)image, name);
}

HL_PRIM bool HL_NAME(vk_set_image_view_name)(VkContext ctx, VkImageView view, vbyte* name) {
	return set_object_name(ctx, VK_OBJECT_TYPE_IMAGE_VIEW, (uint64_t)view, name);
}

HL_PRIM bool HL_NAME(vk_set_memory_name)(VkContext ctx, VkDeviceMemory memory, vbyte* name) {
	return set_object_name(ctx, VK_OBJECT_TYPE_DEVICE_MEMORY, (uint64_t)memory, name);
}

HL_PRIM int HL_NAME(vk_find_memory_type)(VkContext ctx, int allowed, int req) {
	unsigned int i;
	for (i = 0; i < ctx->memProps.memoryTypeCount; i++) {
		if ((allowed & (1 << i)) && (ctx->memProps.memoryTypes[i].propertyFlags & req) == req) {
			return i;
		}
	}
	return -1;
}

HL_PRIM void HL_NAME(vk_get_pdevice_format_props)(VkContext ctx, VkFormat format, VkFormatProperties* props) {
	vkGetPhysicalDeviceFormatProperties(ctx->pdevice, format, props);
}

enum {
	VK_WSI_SUCCESS,
	VK_WSI_SUBOPTIMAL,
	VK_WSI_OUT_OF_DATE,
	VK_WSI_SURFACE_LOST,
	VK_WSI_DEVICE_LOST,
	VK_WSI_DEFERRED,
	VK_WSI_ERROR = -1,
};

static int wsi_status(VkResult result) {
	switch (result) {
	case VK_SUCCESS:
		return VK_WSI_SUCCESS;
	case VK_SUBOPTIMAL_KHR:
		return VK_WSI_SUBOPTIMAL;
	case VK_ERROR_OUT_OF_DATE_KHR:
		return VK_WSI_OUT_OF_DATE;
	case VK_ERROR_SURFACE_LOST_KHR:
		return VK_WSI_SURFACE_LOST;
	case VK_ERROR_DEVICE_LOST:
		return VK_WSI_DEVICE_LOST;
	default:
		return VK_WSI_ERROR;
	}
}

static bool reserve_retired_swapchain(VkContext ctx) {
	if (!ctx->swapchain || ctx->retired_swapchain_count < ctx->retired_swapchain_capacity)
		return true;
	uint32_t capacity = ctx->retired_swapchain_capacity == 0 ? 4 : ctx->retired_swapchain_capacity * 2;
	VkSwapchainKHR* swapchains = realloc(ctx->retired_swapchains, sizeof(VkSwapchainKHR) * capacity);
	if (!swapchains) {
		vk_set_error("Failed to allocate retired swapchain storage");
		return false;
	}
	ctx->retired_swapchains = swapchains;
	ctx->retired_swapchain_capacity = capacity;
	return true;
}

typedef struct {
	int width;
	int height;
	int vsync;
	VkFormat format;
	int actual_width;
	int actual_height;
	int transfer_source;
} VkSwapchainInfo;

HL_PRIM int HL_NAME(vk_init_swapchain)(VkContext ctx, VkSwapchainInfo* info, varray* outImages) {
	vk_clear_error();
	if (info->width <= 0 || info->height <= 0)
		return VK_WSI_DEFERRED;

	VkSurfaceCapabilitiesKHR capabilities;
	VkResult result = vkGetPhysicalDeviceSurfaceCapabilitiesKHR(ctx->pdevice, ctx->surface, &capabilities);
	if (result != VK_SUCCESS) {
		vk_set_error("vkGetPhysicalDeviceSurfaceCapabilitiesKHR failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	VkExtent2D extent = capabilities.currentExtent;
	if (extent.width == UINT32_MAX) {
		extent.width = (uint32_t)info->width;
		extent.height = (uint32_t)info->height;
		if (extent.width < capabilities.minImageExtent.width)
			extent.width = capabilities.minImageExtent.width;
		if (extent.width > capabilities.maxImageExtent.width)
			extent.width = capabilities.maxImageExtent.width;
		if (extent.height < capabilities.minImageExtent.height)
			extent.height = capabilities.minImageExtent.height;
		if (extent.height > capabilities.maxImageExtent.height)
			extent.height = capabilities.maxImageExtent.height;
	}
	if (extent.width == 0 || extent.height == 0)
		return VK_WSI_DEFERRED;
	if (!(capabilities.supportedUsageFlags & VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)) {
		vk_set_error("Surface swapchain images do not support VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT");
		return VK_WSI_ERROR;
	}

	uint32_t format_count = 0;
	result = vkGetPhysicalDeviceSurfaceFormatsKHR(ctx->pdevice, ctx->surface, &format_count, nullptr);
	if (result != VK_SUCCESS || format_count == 0) {
		vk_set_error("Surface format query failed: %s (%d), count=%u", vk_result_name(result), result, format_count);
		return result == VK_SUCCESS ? VK_WSI_ERROR : wsi_status(result);
	}
	VkSurfaceFormatKHR* formats = malloc(sizeof(VkSurfaceFormatKHR) * format_count);
	result = vkGetPhysicalDeviceSurfaceFormatsKHR(ctx->pdevice, ctx->surface, &format_count, formats);
	if (result != VK_SUCCESS) {
		free(formats);
		vk_set_error("Surface format read failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	VkSurfaceFormatKHR format = formats[0];
	for (uint32_t i = 0; i < format_count; i++) {
		if (formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR && formats[i].format == VK_FORMAT_B8G8R8A8_UNORM) {
			format = formats[i];
			break;
		}
		if (formats[i].colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR && formats[i].format == VK_FORMAT_B8G8R8A8_SRGB)
			format = formats[i];
	}
	free(formats);

	uint32_t present_mode_count = 0;
	result = vkGetPhysicalDeviceSurfacePresentModesKHR(ctx->pdevice, ctx->surface, &present_mode_count, nullptr);
	if (result != VK_SUCCESS || present_mode_count == 0) {
		vk_set_error("Present mode query failed: %s (%d), count=%u", vk_result_name(result), result, present_mode_count);
		return result == VK_SUCCESS ? VK_WSI_ERROR : wsi_status(result);
	}
	VkPresentModeKHR* present_modes = malloc(sizeof(VkPresentModeKHR) * present_mode_count);
	result = vkGetPhysicalDeviceSurfacePresentModesKHR(ctx->pdevice, ctx->surface, &present_mode_count, present_modes);
	if (result != VK_SUCCESS) {
		free(present_modes);
		vk_set_error("Present mode read failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	VkPresentModeKHR present_mode = VK_PRESENT_MODE_FIFO_KHR;
	if (!info->vsync) {
		for (uint32_t i = 0; i < present_mode_count; i++) {
			if (present_modes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR) {
				present_mode = VK_PRESENT_MODE_IMMEDIATE_KHR;
				break;
			}
			if (present_modes[i] == VK_PRESENT_MODE_MAILBOX_KHR)
				present_mode = VK_PRESENT_MODE_MAILBOX_KHR;
		}
	}
	free(present_modes);

	uint32_t image_count = capabilities.minImageCount + 1;
	if (capabilities.maxImageCount > 0 && image_count > capabilities.maxImageCount)
		image_count = capabilities.maxImageCount;
	uint32_t image_capacity = (uint32_t)outImages->size;
	if (image_count > image_capacity) {
		vk_set_error("Swapchain requires %u images, but the output array capacity is %u", image_count, image_capacity);
		return VK_WSI_ERROR;
	}

	VkCompositeAlphaFlagBitsKHR composite_alpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
	if (!(capabilities.supportedCompositeAlpha & composite_alpha)) {
		const VkCompositeAlphaFlagBitsKHR choices[] = {
			VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_POST_MULTIPLIED_BIT_KHR,
			VK_COMPOSITE_ALPHA_INHERIT_BIT_KHR,
		};
		for (uint32_t i = 0; i < 3; i++) {
			if (capabilities.supportedCompositeAlpha & choices[i]) {
				composite_alpha = choices[i];
				break;
			}
		}
	}
	VkSurfaceTransformFlagBitsKHR transform =
		(capabilities.supportedTransforms & VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR)
			? VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR
			: capabilities.currentTransform;
	VkImageUsageFlags image_usage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
	if (capabilities.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_DST_BIT)
		image_usage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
	if (capabilities.supportedUsageFlags & VK_IMAGE_USAGE_TRANSFER_SRC_BIT)
		image_usage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
	info->transfer_source = (image_usage & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) != 0;

	uint32_t queue_families[] = { ctx->graphics_queue_family, ctx->present_queue_family };
	VkSwapchainPresentModesCreateInfoKHR present_modes_info = {
		.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_PRESENT_MODES_CREATE_INFO_KHR,
		.presentModeCount = 1,
		.pPresentModes = &present_mode,
	};
	VkSwapchainCreateInfoKHR swapchain_info = {
		.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
		.pNext = (ctx->capability_flags & VK_CAP_SWAPCHAIN_MAINTENANCE_1) ? &present_modes_info : nullptr,
		.surface = ctx->surface,
		.minImageCount = image_count,
		.imageFormat = format.format,
		.imageColorSpace = format.colorSpace,
		.imageExtent = extent,
		.imageArrayLayers = 1,
		.imageUsage = image_usage,
		.imageSharingMode = ctx->graphics_queue_family == ctx->present_queue_family ? VK_SHARING_MODE_EXCLUSIVE : VK_SHARING_MODE_CONCURRENT,
		.queueFamilyIndexCount = ctx->graphics_queue_family == ctx->present_queue_family ? 0 : 2,
		.pQueueFamilyIndices = ctx->graphics_queue_family == ctx->present_queue_family ? nullptr : queue_families,
		.preTransform = transform,
		.compositeAlpha = composite_alpha,
		.presentMode = present_mode,
		.clipped = VK_TRUE,
		.oldSwapchain = ctx->swapchain,
	};
	if (!reserve_retired_swapchain(ctx))
		return VK_WSI_ERROR;
	VkSwapchainKHR new_swapchain = nullptr;
	result = vkCreateSwapchainKHR(ctx->device, &swapchain_info, nullptr, &new_swapchain);
	if (result != VK_SUCCESS) {
		vk_set_error("vkCreateSwapchainKHR failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	uint32_t actual_image_count = 0;
	result = vkGetSwapchainImagesKHR(ctx->device, new_swapchain, &actual_image_count, nullptr);
	if (result != VK_SUCCESS) {
		vkDestroySwapchainKHR(ctx->device, new_swapchain, nullptr);
		vk_set_error("Swapchain image count query failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	if (actual_image_count > image_capacity) {
		vkDestroySwapchainKHR(ctx->device, new_swapchain, nullptr);
		vk_set_error("Swapchain created %u images, but the output array capacity is %u", actual_image_count, image_capacity);
		return VK_WSI_ERROR;
	}
	result = vkGetSwapchainImagesKHR(ctx->device, new_swapchain, &actual_image_count, hl_aptr(outImages, VkImage));
	if (result != VK_SUCCESS) {
		vkDestroySwapchainKHR(ctx->device, new_swapchain, nullptr);
		vk_set_error("vkGetSwapchainImagesKHR failed: %s (%d)", vk_result_name(result), result);
		return wsi_status(result);
	}
	if (ctx->swapchain)
		ctx->retired_swapchains[ctx->retired_swapchain_count++] = ctx->swapchain;
	ctx->swapchain = new_swapchain;
	outImages->size = (int)actual_image_count;
	info->format = format.format;
	info->actual_width = (int)extent.width;
	info->actual_height = (int)extent.height;
	snprintf(
		ctx->wsi_report,
		sizeof(ctx->wsi_report),
		"swapchainFormat=%d;colorSpace=%d;presentMode=%d;imageCount=%u;extent=%ux%u;usage=0x%x;transform=0x%x;compositeAlpha=0x%x",
		format.format,
		format.colorSpace,
		present_mode,
		actual_image_count,
		extent.width,
		extent.height,
		image_usage,
		transform,
		composite_alpha
	);
	return VK_WSI_SUCCESS;
}

HL_PRIM VkShaderModule HL_NAME(vk_create_shader_module)(VkContext ctx, vbyte* data, int len) {
	vk_clear_error();
	if (data == nullptr || len <= 0 || (len & 3) != 0 || ((const uint32_t*)data)[0] != 0x07230203) {
		vk_set_error("vkCreateShaderModule requires valid 32-bit aligned SPIR-V bytecode");
		return nullptr;
	}
	VkShaderModule module = nullptr;
	VkShaderModuleCreateInfo inf = {
		.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
		.codeSize = len,
		.pCode = (const uint32_t*)data,
	};
	VkResult result = vkCreateShaderModule(ctx->device, &inf, nullptr, &module);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateShaderModule failed: %s (%d)", vk_result_name(result), result);
	return module;
}

HL_PRIM VkPipelineLayout HL_NAME(vk_create_pipeline_layout)(VkContext ctx, VkPipelineLayoutCreateInfo* info) {
	VkPipelineLayout p = nullptr;
	VkResult result = vkCreatePipelineLayout(ctx->device, info, nullptr, &p);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreatePipelineLayout failed: %s (%d)", vk_result_name(result), result);
	return p;
}

HL_PRIM VkPipeline HL_NAME(vk_create_graphics_pipeline)(VkContext ctx, VkGraphicsPipelineCreateInfo* info) {
	VkPipeline p = nullptr;
	VkResult result = vkCreateGraphicsPipelines(ctx->device, nullptr, 1, info, nullptr, &p);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateGraphicsPipelines failed: %s (%d)", vk_result_name(result), result);
	return p;
}

typedef struct {
	VkStructureType type;
	const void* next;
	VkPipelineCreateFlags flags;
	VkPipelineShaderStageCreateInfo* stage;
	VkPipelineLayout layout;
	VkPipeline base_pipeline_handle;
	int base_pipeline_index;
} HLVkComputePipelineCreateInfo;

HL_PRIM VkPipeline HL_NAME(vk_create_compute_pipeline)(VkContext ctx, HLVkComputePipelineCreateInfo* info) {
	VkPipeline pipeline = nullptr;
	if (!info || !info->stage) {
		vk_set_error("vkCreateComputePipelines requires a compute shader stage");
		return nullptr;
	}
	VkComputePipelineCreateInfo native_info = {
		.sType = VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
		.pNext = info->next,
		.flags = info->flags,
		.stage = *info->stage,
		.layout = info->layout,
		.basePipelineHandle = info->base_pipeline_handle,
		.basePipelineIndex = info->base_pipeline_index,
	};
	VkResult result = vkCreateComputePipelines(ctx->device, nullptr, 1, &native_info, nullptr, &pipeline);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateComputePipelines failed: %s (%d)", vk_result_name(result), result);
	return pipeline;
}

HL_PRIM VkRenderPass HL_NAME(vk_create_render_pass)(VkContext ctx, VkRenderPassCreateInfo* info) {
	VkRenderPass p = nullptr;
	vkCreateRenderPass(ctx->device, info, nullptr, &p);
	return p;
}

HL_PRIM VkImageView HL_NAME(vk_create_image_view)(VkContext ctx, VkImageViewCreateInfo* info) {
	VkImageView i = nullptr;
	VkResult result = vkCreateImageView(ctx->device, info, nullptr, &i);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateImageView failed: %s (%d)", vk_result_name(result), result);
	return i;
}

HL_PRIM VkFramebuffer HL_NAME(vk_create_framebuffer)(VkContext ctx, VkFramebufferCreateInfo* info) {
	VkFramebuffer b = nullptr;
	vkCreateFramebuffer(ctx->device, info, nullptr, &b);
	return b;
}

HL_PRIM VkDescriptorSetLayout HL_NAME(vk_create_descriptor_set_layout)(VkContext ctx, VkDescriptorSetLayoutCreateInfo* info) {
	VkDescriptorSetLayout p = nullptr;
	VkResult result = vkCreateDescriptorSetLayout(ctx->device, info, nullptr, &p);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateDescriptorSetLayout failed: %s (%d)", vk_result_name(result), result);
	return p;
}

HL_PRIM VkBuffer HL_NAME(vk_create_buffer)(VkContext ctx, VkBufferCreateInfo* info) {
	VkBuffer b = nullptr;
	VkResult result = vkCreateBuffer(ctx->device, info, nullptr, &b);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateBuffer failed: %s (%d)", vk_result_name(result), result);
	return b;
}

HL_PRIM VkBuffer HL_NAME(vk_create_buffer64)(VkContext ctx, int64_t size, int usage) {
	vk_clear_error();
	if (size <= 0) {
		vk_set_error("vkCreateBuffer requires a positive size, got %lld", (long long)size);
		return nullptr;
	}
	VkBufferCreateInfo info = {
		.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
		.size = (VkDeviceSize)size,
		.usage = (VkBufferUsageFlags)usage,
		.sharingMode = VK_SHARING_MODE_EXCLUSIVE,
	};
	VkBuffer buffer = nullptr;
	VkResult result = vkCreateBuffer(ctx->device, &info, nullptr, &buffer);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateBuffer failed for %llu bytes: %s (%d)", (unsigned long long)info.size, vk_result_name(result), result);
	return buffer;
}

typedef struct {
	uint64_t size;
	uint64_t alignment;
	uint32_t memoryTypeBits;
	VkBool32 requiresDedicatedAllocation;
	VkBool32 prefersDedicatedAllocation;
} HLVkMemoryRequirementsInfo;

static void get_memory_requirements_info(VkMemoryRequirements2* requirements, VkMemoryDedicatedRequirements* dedicated, HLVkMemoryRequirementsInfo* output) {
	output->size = requirements->memoryRequirements.size;
	output->alignment = requirements->memoryRequirements.alignment;
	output->memoryTypeBits = requirements->memoryRequirements.memoryTypeBits;
	output->requiresDedicatedAllocation = dedicated->requiresDedicatedAllocation;
	output->prefersDedicatedAllocation = dedicated->prefersDedicatedAllocation;
}

HL_PRIM void HL_NAME(vk_get_buffer_memory_requirements)(VkContext ctx, VkBuffer buf, VkMemoryRequirements* info) {
	vkGetBufferMemoryRequirements(ctx->device, buf, info);
}

HL_PRIM void HL_NAME(vk_get_buffer_memory_requirements2)(VkContext ctx, VkBuffer buffer, HLVkMemoryRequirementsInfo* output) {
	VkMemoryDedicatedRequirements dedicated = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS,
	};
	VkMemoryRequirements2 requirements = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2,
		.pNext = &dedicated,
	};
	VkBufferMemoryRequirementsInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_REQUIREMENTS_INFO_2,
		.buffer = buffer,
	};
	vkGetBufferMemoryRequirements2(ctx->device, &info, &requirements);
	get_memory_requirements_info(&requirements, &dedicated, output);
}

HL_PRIM VkDeviceMemory HL_NAME(vk_allocate_memory)(VkContext ctx, VkMemoryAllocateInfo* inf) {
	VkDeviceMemory m = nullptr;
	VkResult result = vkAllocateMemory(ctx->device, inf, nullptr, &m);
	if (result != VK_SUCCESS)
		vk_set_error("vkAllocateMemory failed: %s (%d)", vk_result_name(result), result);
	return m;
}

HL_PRIM VkDeviceMemory HL_NAME(vk_allocate_memory64)(VkContext ctx, int64_t size, int memory_type_index, VkBuffer dedicated_buffer, VkImage dedicated_image) {
	vk_clear_error();
	if (size <= 0) {
		vk_set_error("vkAllocateMemory requires a positive size, got %lld", (long long)size);
		return nullptr;
	}
	if (memory_type_index < 0 || (uint32_t)memory_type_index >= ctx->memProps.memoryTypeCount) {
		vk_set_error("vkAllocateMemory received invalid memory type index %d", memory_type_index);
		return nullptr;
	}
	if (dedicated_buffer && dedicated_image) {
		vk_set_error("A Vulkan memory allocation cannot be dedicated to both a buffer and an image");
		return nullptr;
	}
	VkMemoryDedicatedAllocateInfo dedicated = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_ALLOCATE_INFO,
		.buffer = dedicated_buffer,
		.image = dedicated_image,
	};
	VkMemoryAllocateInfo info = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
		.pNext = dedicated_buffer || dedicated_image ? &dedicated : nullptr,
		.allocationSize = (VkDeviceSize)size,
		.memoryTypeIndex = (uint32_t)memory_type_index,
	};
	VkDeviceMemory memory = nullptr;
	VkResult result = vkAllocateMemory(ctx->device, &info, nullptr, &memory);
	if (result != VK_SUCCESS)
		vk_set_error(
			"vkAllocateMemory failed for %llu bytes using memory type %d: %s (%d)",
			(unsigned long long)info.allocationSize,
			memory_type_index,
			vk_result_name(result),
			result
		);
	return memory;
}

HL_PRIM vbyte* HL_NAME(vk_map_memory)(VkContext ctx, VkDeviceMemory mem, int offset, int size, int flags) {
	if (mem == nullptr || size <= 0)
		return nullptr;
	void* ptr = nullptr;
	if (vkMapMemory(ctx->device, mem, offset, size, flags, &ptr) != VK_SUCCESS)
		return nullptr;
	return ptr;
}

HL_PRIM vbyte* HL_NAME(vk_map_memory64)(VkContext ctx, VkDeviceMemory memory, int64_t offset, int64_t size, int flags) {
	vk_clear_error();
	if (!memory || offset < 0 || size <= 0)
		return nullptr;
	void* pointer = nullptr;
	VkResult result = vkMapMemory(ctx->device, memory, (VkDeviceSize)offset, (VkDeviceSize)size, (VkMemoryMapFlags)flags, &pointer);
	if (result != VK_SUCCESS)
		vk_set_error("vkMapMemory failed for offset %llu and size %llu: %s (%d)", (unsigned long long)offset, (unsigned long long)size, vk_result_name(result), result);
	return result == VK_SUCCESS ? pointer : nullptr;
}

static int mapped_memory_operation(VkContext ctx, VkDeviceMemory memory, int64_t offset, int64_t size, bool invalidate) {
	VkMappedMemoryRange range = {
		.sType = VK_STRUCTURE_TYPE_MAPPED_MEMORY_RANGE,
		.memory = memory,
		.offset = (VkDeviceSize)offset,
		.size = (VkDeviceSize)size,
	};
	VkResult result = invalidate
		? vkInvalidateMappedMemoryRanges(ctx->device, 1, &range)
		: vkFlushMappedMemoryRanges(ctx->device, 1, &range);
	if (result != VK_SUCCESS)
		vk_set_error(
			"%s failed for offset %llu and size %llu: %s (%d)",
			invalidate ? "vkInvalidateMappedMemoryRanges" : "vkFlushMappedMemoryRanges",
			(unsigned long long)range.offset,
			(unsigned long long)range.size,
			vk_result_name(result),
			result
		);
	return result;
}

HL_PRIM int HL_NAME(vk_flush_mapped_memory)(VkContext ctx, VkDeviceMemory memory, int64_t offset, int64_t size) {
	return mapped_memory_operation(ctx, memory, offset, size, false);
}

HL_PRIM int HL_NAME(vk_invalidate_mapped_memory)(VkContext ctx, VkDeviceMemory memory, int64_t offset, int64_t size) {
	return mapped_memory_operation(ctx, memory, offset, size, true);
}

HL_PRIM void HL_NAME(vk_unmap_memory)(VkContext ctx, VkDeviceMemory mem) {
	vkUnmapMemory(ctx->device, mem);
}

HL_PRIM bool HL_NAME(vk_bind_buffer_memory)(VkContext ctx, VkBuffer buf, VkDeviceMemory mem, int offset) {
	return vkBindBufferMemory(ctx->device, buf, mem, offset) == VK_SUCCESS;
}

HL_PRIM bool HL_NAME(vk_bind_buffer_memory64)(VkContext ctx, VkBuffer buffer, VkDeviceMemory memory, int64_t offset) {
	VkResult result = vkBindBufferMemory(ctx->device, buffer, memory, (VkDeviceSize)offset);
	if (result != VK_SUCCESS)
		vk_set_error("vkBindBufferMemory failed at offset %llu: %s (%d)", (unsigned long long)offset, vk_result_name(result), result);
	return result == VK_SUCCESS;
}

HL_PRIM VkImage HL_NAME(vk_create_image)(VkContext ctx, VkImageCreateInfo* info) {
	VkImage i = nullptr;
	VkResult result = vkCreateImage(ctx->device, info, nullptr, &i);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateImage failed: %s (%d)", vk_result_name(result), result);
	return i;
}

HL_PRIM void HL_NAME(vk_get_image_memory_requirements)(VkContext ctx, VkImage img, VkMemoryRequirements* info) {
	vkGetImageMemoryRequirements(ctx->device, img, info);
}

HL_PRIM void HL_NAME(vk_get_image_memory_requirements2)(VkContext ctx, VkImage image, HLVkMemoryRequirementsInfo* output) {
	VkMemoryDedicatedRequirements dedicated = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS,
	};
	VkMemoryRequirements2 requirements = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2,
		.pNext = &dedicated,
	};
	VkImageMemoryRequirementsInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2,
		.image = image,
	};
	vkGetImageMemoryRequirements2(ctx->device, &info, &requirements);
	get_memory_requirements_info(&requirements, &dedicated, output);
}

HL_PRIM bool HL_NAME(vk_bind_image_memory)(VkContext ctx, VkImage img, VkDeviceMemory mem, int offset) {
	VkResult result = vkBindImageMemory(ctx->device, img, mem, offset);
	if (result != VK_SUCCESS)
		vk_set_error("vkBindImageMemory failed: %s (%d)", vk_result_name(result), result);
	return result == VK_SUCCESS;
}

HL_PRIM bool HL_NAME(vk_bind_image_memory64)(VkContext ctx, VkImage image, VkDeviceMemory memory, int64_t offset) {
	VkResult result = vkBindImageMemory(ctx->device, image, memory, (VkDeviceSize)offset);
	if (result != VK_SUCCESS)
		vk_set_error("vkBindImageMemory failed at offset %llu: %s (%d)", (unsigned long long)offset, vk_result_name(result), result);
	return result == VK_SUCCESS;
}

HL_PRIM VkCommandPool HL_NAME(vk_create_command_pool)(VkContext ctx, VkCommandPoolCreateInfo* inf) {
	VkCommandPool pool = nullptr;
	VkResult result = vkCreateCommandPool(ctx->device, inf, nullptr, &pool);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateCommandPool failed: %s (%d)", vk_result_name(result), result);
	return pool;
}

HL_PRIM VkQueryPool HL_NAME(vk_create_query_pool)(VkContext ctx, VkQueryPoolCreateInfo* inf) {
	VkQueryPool pool = nullptr;
	VkResult result = vkCreateQueryPool(ctx->device, inf, nullptr, &pool);
	if (result != VK_SUCCESS) {
		vk_set_error("vkCreateQueryPool failed: %s (%d)", vk_result_name(result), result);
		return nullptr;
	}
	return pool;
}

HL_PRIM int HL_NAME(vk_get_query_pool_results)(VkContext ctx, VkQueryPool pool, int first_query, int query_count,
	int data_size, vbyte* data, int64_t stride, int flags) {
	if (first_query < 0 || query_count <= 0 || data_size <= 0 || stride < 0) {
		vk_set_error("Invalid Vulkan query result range: first=%d count=%d dataSize=%d stride=%lld",
			first_query, query_count, data_size, (long long)stride);
		return VK_ERROR_UNKNOWN;
	}
	VkResult result = vkGetQueryPoolResults(ctx->device, pool, (uint32_t)first_query, (uint32_t)query_count,
		(size_t)data_size, data, (VkDeviceSize)stride, (VkQueryResultFlags)flags);
	if (result != VK_SUCCESS && result != VK_NOT_READY)
		vk_set_error("vkGetQueryPoolResults failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_allocate_command_buffers)(VkContext ctx, VkCommandBufferAllocateInfo* inf, varray* buffers) {
	VkResult result = vkAllocateCommandBuffers(ctx->device, inf, hl_aptr(buffers, VkCommandBuffer));
	if (result != VK_SUCCESS)
		vk_set_error("vkAllocateCommandBuffers failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM VkDescriptorPool HL_NAME(vk_create_descriptor_pool)(VkContext ctx, VkDescriptorPoolCreateInfo* inf) {
	vk_clear_error();
	VkDescriptorPool pool = nullptr;
	VkResult result = vkCreateDescriptorPool(ctx->device, inf, nullptr, &pool);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateDescriptorPool failed: %s (%d)", vk_result_name(result), result);
	return pool;
}

HL_PRIM int HL_NAME(vk_allocate_descriptor_sets)(VkContext ctx, VkDescriptorSetAllocateInfo* inf, varray* sets) {
	vk_clear_error();
	VkResult result = vkAllocateDescriptorSets(ctx->device, inf, hl_aptr(sets, VkDescriptorSet));
	if (result != VK_SUCCESS)
		vk_set_error("vkAllocateDescriptorSets failed for %u sets: %s (%d)", inf->descriptorSetCount, vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_reset_descriptor_pool)(VkContext ctx, VkDescriptorPool pool) {
	VkResult result = vkResetDescriptorPool(ctx->device, pool, 0);
	if (result != VK_SUCCESS)
		vk_set_error("vkResetDescriptorPool failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM void HL_NAME(vk_update_descriptor_sets)(VkContext ctx, int writeCount, VkWriteDescriptorSet* write, int copyCount, VkCopyDescriptorSet* copy) {
	vkUpdateDescriptorSets(ctx->device, writeCount, write, copyCount, copy);
}

HL_PRIM void HL_NAME(vk_update_descriptor_image_sampler)(VkContext ctx, VkDescriptorSet set, int binding, int array_element, VkImageView view, VkSampler sampler, VkImageLayout layout) {
	VkDescriptorImageInfo imageInfo = {
		.sampler = sampler,
		.imageView = view,
		.imageLayout = layout,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = binding,
		.dstArrayElement = array_element,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
		.pImageInfo = &imageInfo,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_sampled_image)(VkContext ctx, VkDescriptorSet set, int binding, int array_element, VkImageView view, VkImageLayout layout) {
	VkDescriptorImageInfo image_info = {
		.imageView = view,
		.imageLayout = layout,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = binding,
		.dstArrayElement = array_element,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE,
		.pImageInfo = &image_info,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_sampler)(VkContext ctx, VkDescriptorSet set, int binding, int array_element, VkSampler sampler) {
	VkDescriptorImageInfo image_info = {
		.sampler = sampler,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = binding,
		.dstArrayElement = array_element,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER,
		.pImageInfo = &image_info,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_sampled_image_range)(VkContext ctx, VkDescriptorSet set, int binding, int first_element, varray* views, int layout) {
	VkDescriptorImageInfo* image_infos = malloc(sizeof(VkDescriptorImageInfo) * views->size);
	for (int i = 0; i < views->size; i++) {
		image_infos[i] = (VkDescriptorImageInfo) {
			.imageView = hl_aptr(views, VkImageView)[i],
			.imageLayout = (VkImageLayout)layout,
		};
	}
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = (uint32_t)binding,
		.dstArrayElement = (uint32_t)first_element,
		.descriptorCount = (uint32_t)views->size,
		.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLED_IMAGE,
		.pImageInfo = image_infos,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
	free(image_infos);
}

HL_PRIM void HL_NAME(vk_update_descriptor_sampler_range)(VkContext ctx, VkDescriptorSet set, int binding, int first_element, varray* samplers) {
	VkDescriptorImageInfo* image_infos = malloc(sizeof(VkDescriptorImageInfo) * samplers->size);
	for (int i = 0; i < samplers->size; i++)
		image_infos[i] = (VkDescriptorImageInfo) {.sampler = hl_aptr(samplers, VkSampler)[i]};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = (uint32_t)binding,
		.dstArrayElement = (uint32_t)first_element,
		.descriptorCount = (uint32_t)samplers->size,
		.descriptorType = VK_DESCRIPTOR_TYPE_SAMPLER,
		.pImageInfo = image_infos,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
	free(image_infos);
}

HL_PRIM void HL_NAME(vk_update_descriptor_storage_image)(VkContext ctx, VkDescriptorSet set, int binding, int array_element, VkImageView view, VkImageLayout layout) {
	VkDescriptorImageInfo image_info = {
		.sampler = VK_NULL_HANDLE,
		.imageView = view,
		.imageLayout = layout,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = binding,
		.dstArrayElement = array_element,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_STORAGE_IMAGE,
		.pImageInfo = &image_info,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_buffer)(VkContext ctx, VkDescriptorSet set, int binding, int descriptor_type, VkBuffer buffer, int64_t offset, int64_t range) {
	VkDescriptorBufferInfo buffer_info = {
		.buffer = buffer,
		.offset = (VkDeviceSize)offset,
		.range = (VkDeviceSize)range,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = (uint32_t)binding,
		.descriptorCount = 1,
		.descriptorType = (VkDescriptorType)descriptor_type,
		.pBufferInfo = &buffer_info,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_buffer_element)(VkContext ctx, VkDescriptorSet set, int binding, int array_element, int descriptor_type, VkBuffer buffer, int64_t offset, int64_t range) {
	VkDescriptorBufferInfo buffer_info = {
		.buffer = buffer,
		.offset = (VkDeviceSize)offset,
		.range = (VkDeviceSize)range,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = (uint32_t)binding,
		.dstArrayElement = (uint32_t)array_element,
		.descriptorCount = 1,
		.descriptorType = (VkDescriptorType)descriptor_type,
		.pBufferInfo = &buffer_info,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
}

HL_PRIM void HL_NAME(vk_update_descriptor_buffer_range)(VkContext ctx, VkDescriptorSet set, int binding, int first_element, int descriptor_type, varray* buffers, varray* ranges) {
	if (buffers->size != ranges->size)
		hl_error("Vulkan descriptor buffer/range batch sizes differ");
	VkDescriptorBufferInfo* buffer_infos = malloc(sizeof(VkDescriptorBufferInfo) * buffers->size);
	for (int i = 0; i < buffers->size; i++) {
		buffer_infos[i] = (VkDescriptorBufferInfo) {
			.buffer = hl_aptr(buffers, VkBuffer)[i],
			.offset = 0,
			.range = (VkDeviceSize)hl_aptr(ranges, int64_t)[i],
		};
	}
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = (uint32_t)binding,
		.dstArrayElement = (uint32_t)first_element,
		.descriptorCount = (uint32_t)buffers->size,
		.descriptorType = (VkDescriptorType)descriptor_type,
		.pBufferInfo = buffer_infos,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, nullptr);
	free(buffer_infos);
}

HL_PRIM VkSampler HL_NAME(vk_create_sampler)(VkContext ctx, VkSamplerCreateInfo* inf) {
	VkSampler sampler = nullptr;
	VkResult result = vkCreateSampler(ctx->device, inf, nullptr, &sampler);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateSampler failed: %s (%d)", vk_result_name(result), result);
	return sampler;
}

HL_PRIM VkFence HL_NAME(vk_create_fence)(VkContext ctx, VkFenceCreateInfo* inf) {
	VkFence fence = nullptr;
	VkResult result = vkCreateFence(ctx->device, inf, nullptr, &fence);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateFence failed: %s (%d)", vk_result_name(result), result);
	return fence;
}

HL_PRIM VkSemaphore HL_NAME(vk_create_semaphore)(VkContext ctx, VkSemaphoreCreateInfo* inf) {
	VkSemaphore s = nullptr;
	VkResult result = vkCreateSemaphore(ctx->device, inf, nullptr, &s);
	if (result != VK_SUCCESS)
		vk_set_error("vkCreateSemaphore failed: %s (%d)", vk_result_name(result), result);
	return s;
}

HL_PRIM int HL_NAME(vk_reset_fence)(VkContext ctx, VkFence f) {
	VkResult result = vkResetFences(ctx->device, 1, &f);
	if (result != VK_SUCCESS)
		vk_set_error("vkResetFences failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_wait_for_fence)(VkContext ctx, VkFence f, double timeout) {
	uint64_t t = timeout < 0 ? UINT64_MAX : (uint64_t)timeout;
	VkResult result = vkWaitForFences(ctx->device, 1, &f, VK_TRUE, t);
	if (result != VK_SUCCESS && result != VK_TIMEOUT)
		vk_set_error("vkWaitForFences failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_get_fence_status)(VkContext ctx, VkFence fence) {
	VkResult result = vkGetFenceStatus(ctx->device, fence);
	if (result != VK_SUCCESS && result != VK_NOT_READY)
		vk_set_error("vkGetFenceStatus failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_acquire_next_image)(VkContext ctx, VkSemaphore lock, int* out_image) {
	vk_clear_error();
	uint32_t image = 0;
	VkResult result = vkAcquireNextImageKHR(ctx->device, ctx->swapchain, UINT64_MAX, lock, VK_NULL_HANDLE, &image);
	if (result == VK_SUCCESS || result == VK_SUBOPTIMAL_KHR)
		*out_image = (int)image;
	else
		vk_set_error("vkAcquireNextImageKHR failed: %s (%d)", vk_result_name(result), result);
	return wsi_status(result);
}

HL_PRIM int HL_NAME(vk_queue_submit)(VkContext ctx, VkSubmitInfo* inf, VkFence fence) {
	VkResult result = vkQueueSubmit(ctx->graphics_queue, 1, inf, fence);
	if (result != VK_SUCCESS)
		vk_set_error("vkQueueSubmit failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_submit_command)(VkContext ctx, VkCommandBuffer command, VkFence fence) {
	VkCommandBufferSubmitInfo command_info = {
		.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO,
		.commandBuffer = command,
	};
	VkSubmitInfo2 submit = {
		.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO_2,
		.commandBufferInfoCount = 1,
		.pCommandBufferInfos = &command_info,
	};
	VkResult result = vkQueueSubmit2(ctx->graphics_queue, 1, &submit, fence);
	if (result != VK_SUCCESS)
		vk_set_error("vkQueueSubmit2 failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_queue_wait_idle)(VkContext ctx) {
	VkResult result = vkQueueWaitIdle(ctx->graphics_queue);
	if (result != VK_SUCCESS)
		vk_set_error("vkQueueWaitIdle failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_wait_idle)(VkContext ctx) {
	VkResult result = vkDeviceWaitIdle(ctx->device);
	if (result != VK_SUCCESS)
		vk_set_error("vkDeviceWaitIdle failed during shutdown: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_present)(VkContext ctx, VkSemaphore sem, int image) {
	vk_clear_error();
	VkPresentInfoKHR presentInfo = {
		.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
		.waitSemaphoreCount = 1,
		.pWaitSemaphores = &sem,
		.swapchainCount = 1,
		.pSwapchains = &ctx->swapchain,
		.pImageIndices = &image,
	};
	VkResult result = vkQueuePresentKHR(ctx->present_queue, &presentInfo);
	if (result != VK_SUCCESS && result != VK_SUBOPTIMAL_KHR)
		vk_set_error("vkQueuePresentKHR failed: %s (%d)", vk_result_name(result), result);
	return wsi_status(result);
}

HL_PRIM void HL_NAME(vk_destroy_buffer)(VkContext ctx, VkBuffer buf) {
	vkDestroyBuffer(ctx->device, buf, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_image)(VkContext ctx, VkImage img) {
	vkDestroyImage(ctx->device, img, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_image_view)(VkContext ctx, VkImageView view) {
	vkDestroyImageView(ctx->device, view, nullptr);
}

HL_PRIM void HL_NAME(vk_free_memory)(VkContext ctx, VkDeviceMemory mem) {
	vkFreeMemory(ctx->device, mem, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_fence)(VkContext ctx, VkFence fence) {
	vkDestroyFence(ctx->device, fence, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_semaphore)(VkContext ctx, VkSemaphore sem) {
	vkDestroySemaphore(ctx->device, sem, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_command_pool)(VkContext ctx, VkCommandPool pool) {
	vkDestroyCommandPool(ctx->device, pool, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_query_pool)(VkContext ctx, VkQueryPool pool) {
	vkDestroyQueryPool(ctx->device, pool, nullptr);
}

HL_PRIM void HL_NAME(vk_free_command_buffers)(VkContext ctx, VkCommandPool pool, varray* cmd) {
	vkFreeCommandBuffers(ctx->device, pool, cmd->size, hl_aptr(cmd, VkCommandBuffer));
}

HL_PRIM void HL_NAME(vk_destroy_framebuffer)(VkContext ctx, VkFramebuffer fb) {
	vkDestroyFramebuffer(ctx->device, fb, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_render_pass)(VkContext ctx, VkRenderPass pass) {
	vkDestroyRenderPass(ctx->device, pass, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_descriptor_pool)(VkContext ctx, VkDescriptorPool pool) {
	vkDestroyDescriptorPool(ctx->device, pool, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_sampler)(VkContext ctx, VkSampler sampler) {
	vkDestroySampler(ctx->device, sampler, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_shader_module)(VkContext ctx, VkShaderModule module) {
	vkDestroyShaderModule(ctx->device, module, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_pipeline_layout)(VkContext ctx, VkPipelineLayout layout) {
	vkDestroyPipelineLayout(ctx->device, layout, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_graphics_pipeline)(VkContext ctx, VkPipeline pipeline) {
	vkDestroyPipeline(ctx->device, pipeline, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_compute_pipeline)(VkContext ctx, VkPipeline pipeline) {
	vkDestroyPipeline(ctx->device, pipeline, nullptr);
}

HL_PRIM void HL_NAME(vk_destroy_descriptor_set_layout)(VkContext ctx, VkDescriptorSetLayout layout) {
	vkDestroyDescriptorSetLayout(ctx->device, layout, nullptr);
}

HL_PRIM bool HL_NAME(vk_set_shader_module_name)(VkContext ctx, VkShaderModule module, vbyte* name) {
	return set_object_name(ctx, VK_OBJECT_TYPE_SHADER_MODULE, (uint64_t)module, name);
}

#define _VCTX _ABSTRACT(vk_context)
#define _SHADER_MODULE _ABSTRACT(vk_shader_module)
#define _GPIPELINE _ABSTRACT(vk_gpipeline)
#define _PIPELAYOUT _ABSTRACT(vk_pipeline_layout)
#define _RENDERPASS _ABSTRACT(vk_render_pass)
#define _IMAGE _ABSTRACT(vk_image)
#define _IMAGE_VIEW _ABSTRACT(vk_image_view)
#define _FRAMEBUFFER _ABSTRACT(vk_framebuffer)
#define _DLAYOUT _ABSTRACT(vk_descriptor_layout)
#define _BUFFER _ABSTRACT(vk_buffer)
#define _MEMORY _ABSTRACT(vk_device_memory)
#define _CMD _ABSTRACT(vk_command_buffer)
#define _CMD_POOL _ABSTRACT(vk_command_pool)
#define _FENCE _ABSTRACT(vk_fence)
#define _SEMAPHORE _ABSTRACT(vk_semaphore)
#define _DPOOL _ABSTRACT(vk_descriptor_pool)
#define _DSET _ABSTRACT(vk_descriptor_set)
#define _SAMPLER _ABSTRACT(vk_sampler)
#define _QPOOL _ABSTRACT(vk_query_pool)

DEFINE_PRIM(_BOOL, vk_init, _BOOL);
DEFINE_PRIM(_VOID, vk_shutdown, _NO_ARG);
DEFINE_PRIM(_VOID, vk_destroy_surface, _BYTES);
DEFINE_PRIM(_BYTES, vk_last_error, _NO_ARG);
DEFINE_PRIM(_BYTES, vk_instance_report, _NO_ARG);
DEFINE_PRIM(_I32, vk_loader_api_version, _NO_ARG);
DEFINE_PRIM(_I32, vk_instance_api_version, _NO_ARG);
DEFINE_PRIM(_BOOL, vk_validation_enabled, _NO_ARG);
DEFINE_PRIM(_VCTX, vk_init_context, _BYTES _REF(_I32) _I32);
DEFINE_PRIM(_BOOL, vk_destroy_context, _VCTX);
DEFINE_PRIM(_BYTES, vk_get_context_report, _VCTX);
DEFINE_PRIM(_I32, vk_get_capability_flags, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_update_after_bind_descriptors, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_per_stage_update_after_bind_resources, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_per_stage_update_after_bind_samplers, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_per_stage_update_after_bind_sampled_images, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_per_stage_update_after_bind_storage_buffers, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_update_after_bind_samplers, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_update_after_bind_sampled_images, _VCTX);
DEFINE_PRIM(_I32, vk_get_max_update_after_bind_storage_buffers, _VCTX);
DEFINE_PRIM(_I32, vk_get_device_api_version, _VCTX);
DEFINE_PRIM(_I32, vk_get_vendor_id, _VCTX);
DEFINE_PRIM(_I32, vk_get_device_id, _VCTX);
DEFINE_PRIM(_I32, vk_get_driver_version, _VCTX);
DEFINE_PRIM(_I32, vk_get_graphics_queue_family, _VCTX);
DEFINE_PRIM(_I32, vk_get_present_queue_family, _VCTX);
DEFINE_PRIM(_I32, vk_get_compute_queue_family, _VCTX);
DEFINE_PRIM(_I32, vk_get_transfer_queue_family, _VCTX);
DEFINE_PRIM(_I32, vk_get_graphics_timestamp_valid_bits, _VCTX);
DEFINE_PRIM(_F64, vk_get_timestamp_period, _VCTX);
DEFINE_PRIM(_I32, vk_init_swapchain, _VCTX _STRUCT _ARR);
DEFINE_PRIM(_BYTES, vk_make_array, _ARR);
DEFINE_PRIM(_BYTES, vk_make_ref, _DYN);
DEFINE_PRIM(_STRUCT, vk_get_limits, _VCTX);
DEFINE_PRIM(_I32, vk_get_memory_type_count, _VCTX);
DEFINE_PRIM(_I32, vk_get_memory_type_properties, _VCTX _I32);
DEFINE_PRIM(_I32, vk_get_memory_type_heap_index, _VCTX _I32);
DEFINE_PRIM(_I32, vk_get_memory_heap_count, _VCTX);
DEFINE_PRIM(_I64, vk_get_memory_heap_size, _VCTX _I32);
DEFINE_PRIM(_I32, vk_get_memory_heap_flags, _VCTX _I32);
DEFINE_PRIM(_BOOL, vk_has_memory_budget, _VCTX);
DEFINE_PRIM(_BOOL, vk_get_memory_heap_budget, _VCTX _I32 _STRUCT);
DEFINE_PRIM(_BOOL, vk_set_buffer_name, _VCTX _BUFFER _BYTES);
DEFINE_PRIM(_BOOL, vk_set_image_name, _VCTX _IMAGE _BYTES);
DEFINE_PRIM(_BOOL, vk_set_image_view_name, _VCTX _IMAGE_VIEW _BYTES);
DEFINE_PRIM(_BOOL, vk_set_memory_name, _VCTX _MEMORY _BYTES);
DEFINE_PRIM(_BYTES, vk_get_device_name, _VCTX);
DEFINE_PRIM(_I32, vk_find_memory_type, _VCTX _I32 _I32);
DEFINE_PRIM(_SHADER_MODULE, vk_create_shader_module, _VCTX _BYTES _I32);
DEFINE_PRIM(_GPIPELINE, vk_create_graphics_pipeline, _VCTX _STRUCT);
DEFINE_PRIM(_GPIPELINE, vk_create_compute_pipeline, _VCTX _STRUCT);
DEFINE_PRIM(_PIPELAYOUT, vk_create_pipeline_layout, _VCTX _STRUCT);
DEFINE_PRIM(_RENDERPASS, vk_create_render_pass, _VCTX _STRUCT);
DEFINE_PRIM(_IMAGE_VIEW, vk_create_image_view, _VCTX _STRUCT);
DEFINE_PRIM(_FENCE, vk_create_fence, _VCTX _STRUCT);
DEFINE_PRIM(_I32, vk_wait_for_fence, _VCTX _FENCE _F64);
DEFINE_PRIM(_I32, vk_get_fence_status, _VCTX _FENCE);
DEFINE_PRIM(_I32, vk_reset_fence, _VCTX _FENCE);
DEFINE_PRIM(_CMD_POOL, vk_create_command_pool, _VCTX _STRUCT);
DEFINE_PRIM(_QPOOL, vk_create_query_pool, _VCTX _STRUCT);
DEFINE_PRIM(_I32, vk_get_query_pool_results, _VCTX _QPOOL _I32 _I32 _I32 _BYTES _I64 _I32);
DEFINE_PRIM(_I32, vk_allocate_command_buffers, _VCTX _STRUCT _ARR);
DEFINE_PRIM(_FRAMEBUFFER, vk_create_framebuffer, _VCTX _STRUCT);
DEFINE_PRIM(_DLAYOUT, vk_create_descriptor_set_layout, _VCTX _STRUCT);
DEFINE_PRIM(_SAMPLER, vk_create_sampler, _VCTX _STRUCT);
DEFINE_PRIM(_BUFFER, vk_create_buffer, _VCTX _STRUCT);
DEFINE_PRIM(_BUFFER, vk_create_buffer64, _VCTX _I64 _I32);
DEFINE_PRIM(_VOID, vk_get_buffer_memory_requirements, _VCTX _BUFFER _STRUCT);
DEFINE_PRIM(_VOID, vk_get_buffer_memory_requirements2, _VCTX _BUFFER _STRUCT);
DEFINE_PRIM(_IMAGE, vk_create_image, _VCTX _STRUCT);
DEFINE_PRIM(_VOID, vk_get_image_memory_requirements, _VCTX _IMAGE _STRUCT);
DEFINE_PRIM(_VOID, vk_get_image_memory_requirements2, _VCTX _IMAGE _STRUCT);
DEFINE_PRIM(_BOOL, vk_bind_image_memory, _VCTX _IMAGE _MEMORY _I32);
DEFINE_PRIM(_BOOL, vk_bind_image_memory64, _VCTX _IMAGE _MEMORY _I64);
DEFINE_PRIM(_MEMORY, vk_allocate_memory, _VCTX _STRUCT);
DEFINE_PRIM(_MEMORY, vk_allocate_memory64, _VCTX _I64 _I32 _BUFFER _IMAGE);
DEFINE_PRIM(_BYTES, vk_map_memory, _VCTX _MEMORY _I32 _I32 _I32);
DEFINE_PRIM(_BYTES, vk_map_memory64, _VCTX _MEMORY _I64 _I64 _I32);
DEFINE_PRIM(_I32, vk_flush_mapped_memory, _VCTX _MEMORY _I64 _I64);
DEFINE_PRIM(_I32, vk_invalidate_mapped_memory, _VCTX _MEMORY _I64 _I64);
DEFINE_PRIM(_VOID, vk_unmap_memory, _VCTX _MEMORY);
DEFINE_PRIM(_BOOL, vk_bind_buffer_memory, _VCTX _BUFFER _MEMORY _I32);
DEFINE_PRIM(_BOOL, vk_bind_buffer_memory64, _VCTX _BUFFER _MEMORY _I64);
DEFINE_PRIM(_SEMAPHORE, vk_create_semaphore, _VCTX _STRUCT);
DEFINE_PRIM(_I32, vk_acquire_next_image, _VCTX _SEMAPHORE _REF(_I32));
DEFINE_PRIM(_I32, vk_queue_submit, _VCTX _STRUCT _FENCE);
DEFINE_PRIM(_I32, vk_submit_command, _VCTX _CMD _FENCE);
DEFINE_PRIM(_I32, vk_queue_wait_idle, _VCTX);
DEFINE_PRIM(_I32, vk_wait_idle, _VCTX);
DEFINE_PRIM(_I32, vk_present, _VCTX _SEMAPHORE _I32);
DEFINE_PRIM(_VOID, vk_get_pdevice_format_props, _VCTX _I32 _STRUCT);
DEFINE_PRIM(_DPOOL, vk_create_descriptor_pool, _VCTX _STRUCT);
DEFINE_PRIM(_I32, vk_allocate_descriptor_sets, _VCTX _STRUCT _ARR);
DEFINE_PRIM(_I32, vk_reset_descriptor_pool, _VCTX _DPOOL);
DEFINE_PRIM(_VOID, vk_update_descriptor_sets, _VCTX _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_update_descriptor_image_sampler, _VCTX _DSET _I32 _I32 _IMAGE_VIEW _SAMPLER _I32);
DEFINE_PRIM(_VOID, vk_update_descriptor_sampled_image, _VCTX _DSET _I32 _I32 _IMAGE_VIEW _I32);
DEFINE_PRIM(_VOID, vk_update_descriptor_sampler, _VCTX _DSET _I32 _I32 _SAMPLER);
DEFINE_PRIM(_VOID, vk_update_descriptor_sampled_image_range, _VCTX _DSET _I32 _I32 _ARR _I32);
DEFINE_PRIM(_VOID, vk_update_descriptor_sampler_range, _VCTX _DSET _I32 _I32 _ARR);
DEFINE_PRIM(_VOID, vk_update_descriptor_storage_image, _VCTX _DSET _I32 _I32 _IMAGE_VIEW _I32);
DEFINE_PRIM(_VOID, vk_update_descriptor_buffer, _VCTX _DSET _I32 _I32 _BUFFER _I64 _I64);
DEFINE_PRIM(_VOID, vk_update_descriptor_buffer_element, _VCTX _DSET _I32 _I32 _I32 _BUFFER _I64 _I64);
DEFINE_PRIM(_VOID, vk_update_descriptor_buffer_range, _VCTX _DSET _I32 _I32 _I32 _ARR _ARR);
DEFINE_PRIM(_VOID, vk_destroy_image, _VCTX _IMAGE);
DEFINE_PRIM(_VOID, vk_destroy_image_view, _VCTX _IMAGE_VIEW);
DEFINE_PRIM(_VOID, vk_destroy_framebuffer, _VCTX _FRAMEBUFFER);
DEFINE_PRIM(_VOID, vk_destroy_render_pass, _VCTX _RENDERPASS);
DEFINE_PRIM(_VOID, vk_free_command_buffers, _VCTX _CMD_POOL _ARR);
DEFINE_PRIM(_VOID, vk_destroy_command_pool, _VCTX _CMD_POOL);
DEFINE_PRIM(_VOID, vk_destroy_query_pool, _VCTX _QPOOL);
DEFINE_PRIM(_VOID, vk_destroy_buffer, _VCTX _BUFFER);
DEFINE_PRIM(_VOID, vk_destroy_fence, _VCTX _FENCE);
DEFINE_PRIM(_VOID, vk_destroy_semaphore, _VCTX _SEMAPHORE);
DEFINE_PRIM(_VOID, vk_free_memory, _VCTX _MEMORY);
DEFINE_PRIM(_VOID, vk_destroy_descriptor_pool, _VCTX _DPOOL);
DEFINE_PRIM(_VOID, vk_destroy_sampler, _VCTX _SAMPLER);
DEFINE_PRIM(_VOID, vk_destroy_shader_module, _VCTX _SHADER_MODULE);
DEFINE_PRIM(_VOID, vk_destroy_pipeline_layout, _VCTX _PIPELAYOUT);
DEFINE_PRIM(_VOID, vk_destroy_graphics_pipeline, _VCTX _GPIPELINE);
DEFINE_PRIM(_VOID, vk_destroy_compute_pipeline, _VCTX _GPIPELINE);
DEFINE_PRIM(_VOID, vk_destroy_descriptor_set_layout, _VCTX _DLAYOUT);
DEFINE_PRIM(_BOOL, vk_set_shader_module_name, _VCTX _SHADER_MODULE _BYTES);

// ------ COMMAND BUFFER OPERATIONS -----------------------

HL_PRIM int HL_NAME(vk_command_reset)(VkCommandBuffer out) {
	VkResult result = vkResetCommandBuffer(out, 0);
	if (result != VK_SUCCESS)
		vk_set_error("vkResetCommandBuffer failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_command_begin)(VkCommandBuffer out, VkCommandBufferBeginInfo* inf) {
	VkResult result = vkBeginCommandBuffer(out, inf);
	if (result != VK_SUCCESS)
		vk_set_error("vkBeginCommandBuffer failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM int HL_NAME(vk_command_end)(VkCommandBuffer out) {
	VkResult result = vkEndCommandBuffer(out);
	if (result != VK_SUCCESS)
		vk_set_error("vkEndCommandBuffer failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM void HL_NAME(vk_reset_query_pool)(VkCommandBuffer command, VkQueryPool pool, int first_query, int query_count) {
	vkCmdResetQueryPool(command, pool, (uint32_t)first_query, (uint32_t)query_count);
}

HL_PRIM void HL_NAME(vk_begin_query)(VkCommandBuffer command, VkQueryPool pool, int query, int flags) {
	vkCmdBeginQuery(command, pool, (uint32_t)query, (VkQueryControlFlags)flags);
}

HL_PRIM void HL_NAME(vk_end_query)(VkCommandBuffer command, VkQueryPool pool, int query) {
	vkCmdEndQuery(command, pool, (uint32_t)query);
}

HL_PRIM void HL_NAME(vk_write_timestamp2)(VkCommandBuffer command, int64_t stage_mask, VkQueryPool pool, int query) {
	vkCmdWriteTimestamp2(command, (VkPipelineStageFlags2)stage_mask, pool, (uint32_t)query);
}

typedef struct {
	VkImage color_image;
	VkImageView color_view;
	VkImage depth_image;
	VkImageView depth_view;
	int width;
	int height;
	int first_use;
	int resume;
	VkImageAspectFlags depth_aspect;
	float red;
	float green;
	float blue;
	float alpha;
	float depth;
	int stencil;
} VkDynamicRenderingClearInfo;

HL_PRIM void HL_NAME(vk_begin_dynamic_rendering_clear)(VkCommandBuffer command, VkDynamicRenderingClearInfo* info) {
	VkImageMemoryBarrier2 barriers[2] = {
		{
			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
			.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
			.srcAccessMask = info->resume ? VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT : VK_ACCESS_2_NONE,
			.dstStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
			.dstAccessMask = VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
			.oldLayout = info->resume ? VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL : (info->first_use ? VK_IMAGE_LAYOUT_UNDEFINED : VK_IMAGE_LAYOUT_PRESENT_SRC_KHR),
			.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.image = info->color_image,
			.subresourceRange = {
				.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		},
		{
			.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
			.srcStageMask = info->first_use && !info->resume ? VK_PIPELINE_STAGE_2_NONE : VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
			.srcAccessMask = info->first_use && !info->resume ? VK_ACCESS_2_NONE : VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
			.dstStageMask = VK_PIPELINE_STAGE_2_EARLY_FRAGMENT_TESTS_BIT | VK_PIPELINE_STAGE_2_LATE_FRAGMENT_TESTS_BIT,
			.dstAccessMask = VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_READ_BIT | VK_ACCESS_2_DEPTH_STENCIL_ATTACHMENT_WRITE_BIT,
			.oldLayout = info->first_use && !info->resume ? VK_IMAGE_LAYOUT_UNDEFINED : VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
			.newLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
			.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
			.image = info->depth_image,
			.subresourceRange = {
				.aspectMask = info->depth_aspect,
				.baseMipLevel = 0,
				.levelCount = 1,
				.baseArrayLayer = 0,
				.layerCount = 1,
			},
		},
	};
	VkDependencyInfo dependency = {
		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
		.imageMemoryBarrierCount = info->depth_image ? 2 : 1,
		.pImageMemoryBarriers = barriers,
	};
	vkCmdPipelineBarrier2(command, &dependency);

	VkRenderingAttachmentInfo color_attachment = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
		.imageView = info->color_view,
		.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
		.loadOp = info->resume ? VK_ATTACHMENT_LOAD_OP_LOAD : VK_ATTACHMENT_LOAD_OP_CLEAR,
		.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
		.clearValue.color = { .float32 = { info->red, info->green, info->blue, info->alpha } },
	};
	VkRenderingAttachmentInfo depth_attachment = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
		.imageView = info->depth_view,
		.imageLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
		.loadOp = info->resume ? VK_ATTACHMENT_LOAD_OP_LOAD : VK_ATTACHMENT_LOAD_OP_CLEAR,
		.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
		.clearValue.depthStencil = { info->depth, (uint32_t)info->stencil },
	};
	VkRenderingInfo rendering = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_INFO,
		.renderArea = { .offset = { 0, 0 }, .extent = { (uint32_t)info->width, (uint32_t)info->height } },
		.layerCount = 1,
		.colorAttachmentCount = 1,
		.pColorAttachments = &color_attachment,
		.pDepthAttachment = info->depth_view ? &depth_attachment : nullptr,
	};
	vkCmdBeginRendering(command, &rendering);
	VkViewport viewport = { 0.0f, 0.0f, (float)info->width, (float)info->height, 0.0f, 1.0f };
	VkRect2D scissor = { .offset = { 0, 0 }, .extent = { (uint32_t)info->width, (uint32_t)info->height } };
	vkCmdSetViewport(command, 0, 1, &viewport);
	vkCmdSetScissor(command, 0, 1, &scissor);
}

HL_PRIM void HL_NAME(vk_begin_dynamic_rendering)(VkCommandBuffer command, int width, int height, int color_count,
	VkImageView* color_views, VkImageLayout color_layout, VkImageView depth_view, VkImageLayout depth_layout,
	VkImageView stencil_view, VkImageLayout stencil_layout) {
	VkRenderingAttachmentInfo color_attachments[32];
	if (color_count < 0 || color_count > 32) {
		vk_set_error("vkCmdBeginRendering color attachment count %d is outside the supported range 0...32", color_count);
		return;
	}
	for (int i = 0; i < color_count; i++) {
		color_attachments[i] = (VkRenderingAttachmentInfo) {
			.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
			.imageView = color_views[i],
			.imageLayout = color_layout,
			.loadOp = VK_ATTACHMENT_LOAD_OP_LOAD,
			.storeOp = VK_ATTACHMENT_STORE_OP_STORE,
		};
	}
	VkRenderingAttachmentInfo depth_attachment = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
		.imageView = depth_view,
		.imageLayout = depth_layout,
		.loadOp = VK_ATTACHMENT_LOAD_OP_LOAD,
		.storeOp = depth_layout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
			? (VkAttachmentStoreOp)1000301000 : VK_ATTACHMENT_STORE_OP_STORE,
	};
	VkRenderingAttachmentInfo stencil_attachment = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO,
		.imageView = stencil_view,
		.imageLayout = stencil_layout,
		.loadOp = VK_ATTACHMENT_LOAD_OP_LOAD,
		.storeOp = stencil_layout == VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL
			? (VkAttachmentStoreOp)1000301000 : VK_ATTACHMENT_STORE_OP_STORE,
	};
	VkRenderingInfo rendering = {
		.sType = VK_STRUCTURE_TYPE_RENDERING_INFO,
		.renderArea = { .offset = { 0, 0 }, .extent = { (uint32_t)width, (uint32_t)height } },
		.layerCount = 1,
		.colorAttachmentCount = (uint32_t)color_count,
		.pColorAttachments = color_count == 0 ? nullptr : color_attachments,
		.pDepthAttachment = depth_view ? &depth_attachment : nullptr,
		.pStencilAttachment = stencil_view ? &stencil_attachment : nullptr,
	};
	vkCmdBeginRendering(command, &rendering);
}

HL_PRIM void HL_NAME(vk_begin_dynamic_rendering_native)(VkCommandBuffer command, int width, int height, int color_count,
	varray* color_views, VkImageLayout color_layout, VkImageView depth_view, VkImageLayout depth_layout,
	VkImageView stencil_view, VkImageLayout stencil_layout) {
	HL_NAME(vk_begin_dynamic_rendering)(command, width, height, color_count, hl_aptr(color_views, VkImageView), color_layout,
		depth_view, depth_layout, stencil_view, stencil_layout);
}

HL_PRIM void HL_NAME(vk_end_dynamic_rendering_present)(VkCommandBuffer command, VkImage color_image) {
	vkCmdEndRendering(command);
	VkImageMemoryBarrier2 barrier = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
		.srcStageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
		.srcAccessMask = VK_ACCESS_2_COLOR_ATTACHMENT_WRITE_BIT,
		.dstStageMask = VK_PIPELINE_STAGE_2_NONE,
		.dstAccessMask = VK_ACCESS_2_NONE,
		.oldLayout = VK_IMAGE_LAYOUT_ATTACHMENT_OPTIMAL,
		.newLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR,
		.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.image = color_image,
		.subresourceRange = {
			.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
			.baseMipLevel = 0,
			.levelCount = 1,
			.baseArrayLayer = 0,
			.layerCount = 1,
		},
	};
	VkDependencyInfo dependency = {
		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
		.imageMemoryBarrierCount = 1,
		.pImageMemoryBarriers = &barrier,
	};
	vkCmdPipelineBarrier2(command, &dependency);
}

HL_PRIM void HL_NAME(vk_end_dynamic_rendering)(VkCommandBuffer command) {
	vkCmdEndRendering(command);
}

HL_PRIM int HL_NAME(vk_submit_frame)(VkContext ctx, VkCommandBuffer command, VkSemaphore acquired, VkSemaphore finished, VkFence fence) {
	VkSemaphoreSubmitInfo wait = {
		.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO,
		.semaphore = acquired,
		.stageMask = VK_PIPELINE_STAGE_2_COLOR_ATTACHMENT_OUTPUT_BIT,
		.deviceIndex = 0,
	};
	VkCommandBufferSubmitInfo command_info = {
		.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_SUBMIT_INFO,
		.commandBuffer = command,
		.deviceMask = 0,
	};
	VkSemaphoreSubmitInfo signal = {
		.sType = VK_STRUCTURE_TYPE_SEMAPHORE_SUBMIT_INFO,
		.semaphore = finished,
		.stageMask = VK_PIPELINE_STAGE_2_ALL_COMMANDS_BIT,
		.deviceIndex = 0,
	};
	VkSubmitInfo2 submit = {
		.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO_2,
		.waitSemaphoreInfoCount = acquired ? 1 : 0,
		.pWaitSemaphoreInfos = acquired ? &wait : nullptr,
		.commandBufferInfoCount = 1,
		.pCommandBufferInfos = &command_info,
		.signalSemaphoreInfoCount = finished ? 1 : 0,
		.pSignalSemaphoreInfos = finished ? &signal : nullptr,
	};
	VkResult result = vkQueueSubmit2(ctx->graphics_queue, 1, &submit, fence);
	if (result != VK_SUCCESS)
		vk_set_error("vkQueueSubmit2 failed: %s (%d)", vk_result_name(result), result);
	return result;
}

HL_PRIM void HL_NAME(vk_clear_color_image)(VkCommandBuffer out, VkImage img, VkImageLayout layout, VkClearColorValue* colors, int count, VkImageSubresourceRange* range) {
	vkCmdClearColorImage(out, img, layout, colors, count, range);
}

HL_PRIM void HL_NAME(vk_clear_attachments)(VkCommandBuffer out, int count, VkClearAttachment* attachs, int rectCount, VkClearRect* rects) {
	vkCmdClearAttachments(out, count, attachs, rectCount, rects);
}

HL_PRIM void HL_NAME(vk_clear_attachments_native)(VkCommandBuffer out, int count, varray* attachs, int rectCount, varray* rects) {
	_Static_assert(sizeof(VkClearAttachment) == 6 * sizeof(int32_t), "VkClearAttachment must contain six 32-bit words");
	_Static_assert(sizeof(VkClearRect) == 6 * sizeof(int32_t), "VkClearRect must contain six 32-bit words");
	vkCmdClearAttachments(out, count, hl_aptr(attachs, VkClearAttachment), rectCount, hl_aptr(rects, VkClearRect));
}

HL_PRIM void HL_NAME(vk_clear_depth_stencil_image)(VkCommandBuffer out, VkImage img, VkImageLayout layout, VkClearDepthStencilValue* values, int count, VkImageSubresourceRange* range) {
	vkCmdClearDepthStencilImage(out, img, layout, values, count, range);
}

HL_PRIM void HL_NAME(vk_draw_indexed)(VkCommandBuffer out, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {
	vkCmdDrawIndexed(out, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);
}

HL_PRIM void HL_NAME(vk_draw_indexed_indirect)(VkCommandBuffer out, VkBuffer buffer, int64_t offset, int drawCount, int stride) {
	vkCmdDrawIndexedIndirect(out, buffer, (VkDeviceSize)offset, (uint32_t)drawCount, (uint32_t)stride);
}

HL_PRIM void HL_NAME(vk_draw_indexed_indirect_count)(VkCommandBuffer out, VkBuffer buffer, int64_t offset, VkBuffer countBuffer, int64_t countOffset, int maxDrawCount, int stride) {
	vkCmdDrawIndexedIndirectCount(out, buffer, (VkDeviceSize)offset, countBuffer, (VkDeviceSize)countOffset, (uint32_t)maxDrawCount, (uint32_t)stride);
}

HL_PRIM void HL_NAME(vk_bind_pipeline)(VkCommandBuffer out, int bindPoint, VkPipeline pipeline) {
	vkCmdBindPipeline(out, (VkPipelineBindPoint)bindPoint, pipeline);
}

HL_PRIM void HL_NAME(vk_bind_compute_pipeline)(VkCommandBuffer command, VkPipeline pipeline) {
	vkCmdBindPipeline(command, VK_PIPELINE_BIND_POINT_COMPUTE, pipeline);
}

HL_PRIM void HL_NAME(vk_dispatch)(VkCommandBuffer command, int group_count_x, int group_count_y, int group_count_z) {
	vkCmdDispatch(command, (uint32_t)group_count_x, (uint32_t)group_count_y, (uint32_t)group_count_z);
}

HL_PRIM void HL_NAME(vk_begin_render_pass)(VkCommandBuffer out, VkRenderPassBeginInfo* info, int contents) {
	vkCmdBeginRenderPass(out, info, (VkSubpassContents)contents);
}

HL_PRIM void HL_NAME(vk_bind_index_buffer)(VkCommandBuffer out, VkBuffer buf, int offset, int type) {
	vkCmdBindIndexBuffer(out, buf, offset, type);
}

HL_PRIM void HL_NAME(vk_bind_index_buffer64)(VkCommandBuffer out, VkBuffer buffer, int64_t offset, int type) {
	vkCmdBindIndexBuffer(out, buffer, (VkDeviceSize)offset, (VkIndexType)type);
}

HL_PRIM void HL_NAME(vk_bind_vertex_buffers)(VkCommandBuffer out, int first, int count, VkBuffer* buffers, VkDeviceSize* sizes) {
	vkCmdBindVertexBuffers(out, first, count, buffers, sizes);
}

HL_PRIM void HL_NAME(vk_bind_vertex_buffers_native)(VkCommandBuffer out, int first, int count, varray* buffers, varray* offsets) {
	vkCmdBindVertexBuffers(out, first, count, hl_aptr(buffers, VkBuffer), hl_aptr(offsets, VkDeviceSize));
}

HL_PRIM void HL_NAME(vk_bind_vertex_buffer)(VkCommandBuffer out, int first, VkBuffer buffer, int offset) {
	VkDeviceSize vkOffset = offset;
	vkCmdBindVertexBuffers(out, first, 1, &buffer, &vkOffset);
}

HL_PRIM void HL_NAME(vk_set_viewport)(VkCommandBuffer out, int first, int count, VkViewport* viewports) {
	vkCmdSetViewport(out, first, count, viewports);
}

HL_PRIM void HL_NAME(vk_set_viewport1)(VkCommandBuffer out, int first, float x, float y, float width, float height, float minDepth, float maxDepth) {
	VkViewport viewport = {
		.x = x,
		.y = y,
		.width = width,
		.height = height,
		.minDepth = minDepth,
		.maxDepth = maxDepth,
	};
	vkCmdSetViewport(out, first, 1, &viewport);
}

HL_PRIM void HL_NAME(vk_set_scissor)(VkCommandBuffer out, int first, int count, VkRect2D* scissors) {
	vkCmdSetScissor(out, first, count, scissors);
}

HL_PRIM void HL_NAME(vk_set_scissor1)(VkCommandBuffer out, int first, int x, int y, int width, int height) {
	VkRect2D scissor = {
		.offset = { x, y },
		.extent = { width, height },
	};
	vkCmdSetScissor(out, first, 1, &scissor);
}

HL_PRIM void HL_NAME(vk_set_cull_mode)(VkCommandBuffer out, int mode) {
	vkCmdSetCullMode(out, (VkCullModeFlags)mode);
}

HL_PRIM void HL_NAME(vk_set_front_face)(VkCommandBuffer out, int face) {
	vkCmdSetFrontFace(out, (VkFrontFace)face);
}

HL_PRIM void HL_NAME(vk_set_primitive_topology)(VkCommandBuffer out, int topology) {
	vkCmdSetPrimitiveTopology(out, (VkPrimitiveTopology)topology);
}

HL_PRIM void HL_NAME(vk_set_depth_test_enable)(VkCommandBuffer out, bool enabled) {
	vkCmdSetDepthTestEnable(out, enabled ? VK_TRUE : VK_FALSE);
}

HL_PRIM void HL_NAME(vk_set_depth_write_enable)(VkCommandBuffer out, bool enabled) {
	vkCmdSetDepthWriteEnable(out, enabled ? VK_TRUE : VK_FALSE);
}

HL_PRIM void HL_NAME(vk_set_depth_compare_op)(VkCommandBuffer out, int compare) {
	vkCmdSetDepthCompareOp(out, (VkCompareOp)compare);
}

HL_PRIM void HL_NAME(vk_set_depth_bias_enable)(VkCommandBuffer out, bool enabled) {
	vkCmdSetDepthBiasEnable(out, enabled ? VK_TRUE : VK_FALSE);
}

HL_PRIM void HL_NAME(vk_set_depth_bias)(VkCommandBuffer out, float constantFactor, float clamp, float slopeFactor) {
	vkCmdSetDepthBias(out, constantFactor, clamp, slopeFactor);
}

HL_PRIM void HL_NAME(vk_end_render_pass)(VkCommandBuffer out) {
	vkCmdEndRenderPass(out);
}

HL_PRIM void HL_NAME(vk_push_constants)(VkCommandBuffer out, VkPipelineLayout layout, VkShaderStageFlags flags, int offset, int size, vbyte* data) {
	vkCmdPushConstants(out, layout, flags, offset, size, data);
}

HL_PRIM void HL_NAME(vk_copy_buffer_to_image)(VkCommandBuffer out, VkBuffer buf, VkImage img, VkImageLayout layout, int count, VkBufferImageCopy* regions) {
	vkCmdCopyBufferToImage(out, buf, img, layout, count, regions);
}

static VkBufferImageCopy2* copy_buffer_image_regions(int count, const VkBufferImageCopy* regions) {
	if (count <= 0 || !regions)
		return nullptr;
	VkBufferImageCopy2* copies = malloc(sizeof(VkBufferImageCopy2) * count);
	if (!copies)
		return nullptr;
	for (int index = 0; index < count; index++) {
		copies[index] = (VkBufferImageCopy2) {
			.sType = VK_STRUCTURE_TYPE_BUFFER_IMAGE_COPY_2,
			.bufferOffset = regions[index].bufferOffset,
			.bufferRowLength = regions[index].bufferRowLength,
			.bufferImageHeight = regions[index].bufferImageHeight,
			.imageSubresource = regions[index].imageSubresource,
			.imageOffset = regions[index].imageOffset,
			.imageExtent = regions[index].imageExtent,
		};
	}
	return copies;
}

HL_PRIM void HL_NAME(vk_copy_buffer_to_image2)(VkCommandBuffer command, VkBuffer buffer, VkImage image, int layout, int count, VkBufferImageCopy* regions) {
	VkBufferImageCopy2* copies = copy_buffer_image_regions(count, regions);
	if (!copies)
		return;
	VkCopyBufferToImageInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_COPY_BUFFER_TO_IMAGE_INFO_2,
		.srcBuffer = buffer,
		.dstImage = image,
		.dstImageLayout = (VkImageLayout)layout,
		.regionCount = (uint32_t)count,
		.pRegions = copies,
	};
	vkCmdCopyBufferToImage2(command, &info);
	free(copies);
}

HL_PRIM void HL_NAME(vk_copy_image_to_buffer2)(VkCommandBuffer command, VkImage image, int layout, VkBuffer buffer, int count, VkBufferImageCopy* regions) {
	VkBufferImageCopy2* copies = copy_buffer_image_regions(count, regions);
	if (!copies)
		return;
	VkCopyImageToBufferInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_COPY_IMAGE_TO_BUFFER_INFO_2,
		.srcImage = image,
		.srcImageLayout = (VkImageLayout)layout,
		.dstBuffer = buffer,
		.regionCount = (uint32_t)count,
		.pRegions = copies,
	};
	vkCmdCopyImageToBuffer2(command, &info);
	free(copies);
}

typedef struct {
	VkImageAspectFlags aspect_mask;
	int src_mip_level;
	int src_base_array_layer;
	int src_layer_count;
	int src_x0;
	int src_y0;
	int src_z0;
	int src_x1;
	int src_y1;
	int src_z1;
	int dst_mip_level;
	int dst_base_array_layer;
	int dst_layer_count;
	int dst_x0;
	int dst_y0;
	int dst_z0;
	int dst_x1;
	int dst_y1;
	int dst_z1;
} LimenImageBlitRegion;

HL_PRIM void HL_NAME(vk_blit_image2)(VkCommandBuffer command, VkImage source, int source_layout, VkImage destination, int destination_layout,
	int filter, int count, const LimenImageBlitRegion* regions) {
	if (count <= 0 || !regions)
		return;
	VkImageBlit2* blits = malloc(sizeof(VkImageBlit2) * count);
	if (!blits)
		return;
	for (int index = 0; index < count; index++) {
		const LimenImageBlitRegion* region = &regions[index];
		blits[index] = (VkImageBlit2) {
			.sType = VK_STRUCTURE_TYPE_IMAGE_BLIT_2,
			.srcSubresource = {
				.aspectMask = region->aspect_mask,
				.mipLevel = region->src_mip_level,
				.baseArrayLayer = region->src_base_array_layer,
				.layerCount = region->src_layer_count,
			},
			.srcOffsets = {
				{ region->src_x0, region->src_y0, region->src_z0 },
				{ region->src_x1, region->src_y1, region->src_z1 },
			},
			.dstSubresource = {
				.aspectMask = region->aspect_mask,
				.mipLevel = region->dst_mip_level,
				.baseArrayLayer = region->dst_base_array_layer,
				.layerCount = region->dst_layer_count,
			},
			.dstOffsets = {
				{ region->dst_x0, region->dst_y0, region->dst_z0 },
				{ region->dst_x1, region->dst_y1, region->dst_z1 },
			},
		};
	}
	VkBlitImageInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_BLIT_IMAGE_INFO_2,
		.srcImage = source,
		.srcImageLayout = (VkImageLayout)source_layout,
		.dstImage = destination,
		.dstImageLayout = (VkImageLayout)destination_layout,
		.regionCount = (uint32_t)count,
		.pRegions = blits,
		.filter = (VkFilter)filter,
	};
	vkCmdBlitImage2(command, &info);
	free(blits);
}

HL_PRIM void HL_NAME(vk_copy_buffer2)(VkCommandBuffer command, VkBuffer source, VkBuffer destination, int64_t source_offset, int64_t destination_offset, int64_t size) {
	VkBufferCopy2 region = {
		.sType = VK_STRUCTURE_TYPE_BUFFER_COPY_2,
		.srcOffset = (VkDeviceSize)source_offset,
		.dstOffset = (VkDeviceSize)destination_offset,
		.size = (VkDeviceSize)size,
	};
	VkCopyBufferInfo2 info = {
		.sType = VK_STRUCTURE_TYPE_COPY_BUFFER_INFO_2,
		.srcBuffer = source,
		.dstBuffer = destination,
		.regionCount = 1,
		.pRegions = &region,
	};
	vkCmdCopyBuffer2(command, &info);
}

HL_PRIM void HL_NAME(vk_buffer_barrier2)(VkCommandBuffer command, VkBuffer buffer, int64_t offset, int64_t size, int64_t source_stage, int64_t source_access, int64_t destination_stage, int64_t destination_access) {
	VkBufferMemoryBarrier2 barrier = {
		.sType = VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER_2,
		.srcStageMask = (VkPipelineStageFlags2)source_stage,
		.srcAccessMask = (VkAccessFlags2)source_access,
		.dstStageMask = (VkPipelineStageFlags2)destination_stage,
		.dstAccessMask = (VkAccessFlags2)destination_access,
		.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.buffer = buffer,
		.offset = (VkDeviceSize)offset,
		.size = (VkDeviceSize)size,
	};
	VkDependencyInfo dependency = {
		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
		.bufferMemoryBarrierCount = 1,
		.pBufferMemoryBarriers = &barrier,
	};
	vkCmdPipelineBarrier2(command, &dependency);
}

HL_PRIM void HL_NAME(vk_image_barrier2)(VkCommandBuffer command, VkImage image, int aspect_mask, int base_mip_level, int level_count, int base_array_layer, int layer_count, int old_layout, int new_layout,
	int64_t source_stage, int64_t source_access, int64_t destination_stage, int64_t destination_access) {
	VkImageMemoryBarrier2 barrier = {
		.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER_2,
		.srcStageMask = (VkPipelineStageFlags2)source_stage,
		.srcAccessMask = (VkAccessFlags2)source_access,
		.dstStageMask = (VkPipelineStageFlags2)destination_stage,
		.dstAccessMask = (VkAccessFlags2)destination_access,
		.oldLayout = (VkImageLayout)old_layout,
		.newLayout = (VkImageLayout)new_layout,
		.srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
		.image = image,
		.subresourceRange = {
			.aspectMask = (VkImageAspectFlags)aspect_mask,
			.baseMipLevel = (uint32_t)base_mip_level,
			.levelCount = (uint32_t)level_count,
			.baseArrayLayer = (uint32_t)base_array_layer,
			.layerCount = (uint32_t)layer_count,
		},
	};
	VkDependencyInfo dependency = {
		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
		.imageMemoryBarrierCount = 1,
		.pImageMemoryBarriers = &barrier,
	};
	vkCmdPipelineBarrier2(command, &dependency);
}

HL_PRIM void HL_NAME(vk_memory_barrier2)(VkCommandBuffer command, int64_t source_stage, int64_t source_access, int64_t destination_stage, int64_t destination_access) {
	VkMemoryBarrier2 barrier = {
		.sType = VK_STRUCTURE_TYPE_MEMORY_BARRIER_2,
		.srcStageMask = (VkPipelineStageFlags2)source_stage,
		.srcAccessMask = (VkAccessFlags2)source_access,
		.dstStageMask = (VkPipelineStageFlags2)destination_stage,
		.dstAccessMask = (VkAccessFlags2)destination_access,
	};
	VkDependencyInfo dependency = {
		.sType = VK_STRUCTURE_TYPE_DEPENDENCY_INFO,
		.memoryBarrierCount = 1,
		.pMemoryBarriers = &barrier,
	};
	vkCmdPipelineBarrier2(command, &dependency);
}

HL_PRIM void HL_NAME(vk_pipeline_barrier)(VkCommandBuffer out, VkPipelineStageFlags srcMask, VkPipelineStageFlags dstMask, VkDependencyFlags flags, int memCount, VkMemoryBarrier* memBarriers, int bufferCount, VkBufferMemoryBarrier* bufBarriers,
                                          int imageCount, VkImageMemoryBarrier* imgBarriers) {
	vkCmdPipelineBarrier(out, srcMask, dstMask, flags, memCount, memBarriers, bufferCount, bufBarriers, imageCount, imgBarriers);
}

HL_PRIM void HL_NAME(vk_bind_descriptor_sets)(VkCommandBuffer out, VkPipelineBindPoint bind, VkPipelineLayout layout, int first, int count, VkDescriptorSet* sets, int offsetCount, int* offsets) {
	vkCmdBindDescriptorSets(out, bind, layout, first, count, sets, offsetCount, offsets);
}

HL_PRIM void HL_NAME(vk_bind_descriptor_sets_native)(VkCommandBuffer out, VkPipelineBindPoint bind, VkPipelineLayout layout, int first, int count, varray* sets, int offsetCount, varray* offsets) {
	vkCmdBindDescriptorSets(out, bind, layout, first, count, hl_aptr(sets, VkDescriptorSet), offsetCount, hl_aptr(offsets, uint32_t));
}

HL_PRIM void HL_NAME(vk_bind_descriptor_set)(VkCommandBuffer out, VkPipelineBindPoint bind, VkPipelineLayout layout, int first, VkDescriptorSet set) {
	vkCmdBindDescriptorSets(out, bind, layout, first, 1, &set, 0, nullptr);
}

DEFINE_PRIM(_I32, vk_command_reset, _CMD);
DEFINE_PRIM(_I32, vk_command_begin, _CMD _STRUCT);
DEFINE_PRIM(_I32, vk_command_end, _CMD);
DEFINE_PRIM(_VOID, vk_reset_query_pool, _CMD _QPOOL _I32 _I32);
DEFINE_PRIM(_VOID, vk_begin_query, _CMD _QPOOL _I32 _I32);
DEFINE_PRIM(_VOID, vk_end_query, _CMD _QPOOL _I32);
DEFINE_PRIM(_VOID, vk_write_timestamp2, _CMD _I64 _QPOOL _I32);
DEFINE_PRIM(_VOID, vk_begin_dynamic_rendering_clear, _CMD _STRUCT);
DEFINE_PRIM(_VOID, vk_begin_dynamic_rendering, _CMD _I32 _I32 _I32 _BYTES _I32 _IMAGE_VIEW _I32 _IMAGE_VIEW _I32);
DEFINE_PRIM(_VOID, vk_begin_dynamic_rendering_native, _CMD _I32 _I32 _I32 _ARR _I32 _IMAGE_VIEW _I32 _IMAGE_VIEW _I32);
DEFINE_PRIM(_VOID, vk_end_dynamic_rendering_present, _CMD _IMAGE);
DEFINE_PRIM(_VOID, vk_end_dynamic_rendering, _CMD);
DEFINE_PRIM(_I32, vk_submit_frame, _VCTX _CMD _SEMAPHORE _SEMAPHORE _FENCE);
DEFINE_PRIM(_VOID, vk_clear_color_image, _CMD _IMAGE _I32 _BYTES _I32 _STRUCT);
DEFINE_PRIM(_VOID, vk_clear_depth_stencil_image, _CMD _IMAGE _I32 _BYTES _I32 _STRUCT);
DEFINE_PRIM(_VOID, vk_clear_attachments, _CMD _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_clear_attachments_native, _CMD _I32 _ARR _I32 _ARR);
DEFINE_PRIM(_VOID, vk_draw_indexed, _CMD _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_draw_indexed_indirect, _CMD _BUFFER _I64 _I32 _I32);
DEFINE_PRIM(_VOID, vk_draw_indexed_indirect_count, _CMD _BUFFER _I64 _BUFFER _I64 _I32 _I32);
DEFINE_PRIM(_VOID, vk_bind_pipeline, _CMD _I32 _GPIPELINE);
DEFINE_PRIM(_VOID, vk_bind_compute_pipeline, _CMD _GPIPELINE);
DEFINE_PRIM(_VOID, vk_dispatch, _CMD _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_begin_render_pass, _CMD _STRUCT _I32);
DEFINE_PRIM(_VOID, vk_bind_index_buffer, _CMD _BUFFER _I32 _I32);
DEFINE_PRIM(_VOID, vk_bind_index_buffer64, _CMD _BUFFER _I64 _I32);
DEFINE_PRIM(_VOID, vk_bind_vertex_buffers, _CMD _I32 _I32 _BYTES _BYTES);
DEFINE_PRIM(_VOID, vk_bind_vertex_buffers_native, _CMD _I32 _I32 _ARR _ARR);
DEFINE_PRIM(_VOID, vk_bind_vertex_buffer, _CMD _I32 _BUFFER _I32);
DEFINE_PRIM(_VOID, vk_set_viewport, _CMD _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_set_viewport1, _CMD _I32 _F32 _F32 _F32 _F32 _F32 _F32);
DEFINE_PRIM(_VOID, vk_set_scissor, _CMD _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_set_scissor1, _CMD _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_set_cull_mode, _CMD _I32);
DEFINE_PRIM(_VOID, vk_set_front_face, _CMD _I32);
DEFINE_PRIM(_VOID, vk_set_primitive_topology, _CMD _I32);
DEFINE_PRIM(_VOID, vk_set_depth_test_enable, _CMD _BOOL);
DEFINE_PRIM(_VOID, vk_set_depth_write_enable, _CMD _BOOL);
DEFINE_PRIM(_VOID, vk_set_depth_compare_op, _CMD _I32);
DEFINE_PRIM(_VOID, vk_set_depth_bias_enable, _CMD _BOOL);
DEFINE_PRIM(_VOID, vk_set_depth_bias, _CMD _F32 _F32 _F32);
DEFINE_PRIM(_VOID, vk_push_constants, _CMD _PIPELAYOUT _I32 _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_end_render_pass, _CMD);
DEFINE_PRIM(_VOID, vk_copy_buffer_to_image, _CMD _BUFFER _IMAGE _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_copy_buffer_to_image2, _CMD _BUFFER _IMAGE _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_copy_image_to_buffer2, _CMD _IMAGE _I32 _BUFFER _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_blit_image2, _CMD _IMAGE _I32 _IMAGE _I32 _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_copy_buffer2, _CMD _BUFFER _BUFFER _I64 _I64 _I64);
DEFINE_PRIM(_VOID, vk_buffer_barrier2, _CMD _BUFFER _I64 _I64 _I64 _I64 _I64 _I64);
DEFINE_PRIM(_VOID, vk_image_barrier2, _CMD _IMAGE _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I64 _I64 _I64 _I64);
DEFINE_PRIM(_VOID, vk_memory_barrier2, _CMD _I64 _I64 _I64 _I64);
DEFINE_PRIM(_VOID, vk_pipeline_barrier, _CMD _I32 _I32 _I32 _I32 _BYTES _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_bind_descriptor_sets, _CMD _I32 _PIPELAYOUT _I32 _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_bind_descriptor_sets_native, _CMD _I32 _PIPELAYOUT _I32 _I32 _ARR _I32 _ARR);
DEFINE_PRIM(_VOID, vk_bind_descriptor_set, _CMD _I32 _PIPELAYOUT _I32 _DSET);
