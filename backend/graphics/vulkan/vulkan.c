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
#include <stdlib.h>
#include <string.h>
#if defined(_WIN32)
#include <windows.h>
#endif

#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>

static VkInstance instance = NULL;

#if defined(_WIN32)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_WIN32_SURFACE_EXTENSION_NAME
#elif defined(__APPLE__)
#define HL_VK_PLATFORM_EXTENSION VK_EXT_METAL_SURFACE_EXTENSION_NAME
#elif defined(__ANDROID__)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_ANDROID_SURFACE_EXTENSION_NAME
#elif defined(__linux__)
#define HL_VK_PLATFORM_EXTENSION VK_KHR_XLIB_SURFACE_EXTENSION_NAME
#else
#define HL_VK_PLATFORM_EXTENSION NULL
#endif

VkInstance vk_get_instance() {
	return instance;
}

HL_PRIM bool HL_NAME(vk_init)(bool enable_validation) {
	if (instance)
		return true;
#if defined(_WIN32)
	if (GetEnvironmentVariableA("VK_LOADER_LAYERS_DISABLE", NULL, 0) == 0 && GetLastError() == ERROR_ENVVAR_NOT_FOUND) {
		SetEnvironmentVariableA("VK_LOADER_LAYERS_DISABLE", "~implicit~");
	}
#endif
#if defined(__APPLE__)
	const char* extensions[4] = {
		VK_KHR_SURFACE_EXTENSION_NAME,
		HL_VK_PLATFORM_EXTENSION,
		VK_KHR_PORTABILITY_ENUMERATION_EXTENSION_NAME,
		VK_EXT_DEBUG_UTILS_EXTENSION_NAME
	};
	int extensionCount = enable_validation ? 4 : 3;
#else
	const char* extensions[3] = { VK_KHR_SURFACE_EXTENSION_NAME, HL_VK_PLATFORM_EXTENSION, VK_EXT_DEBUG_UTILS_EXTENSION_NAME };
	int extensionCount = enable_validation ? 3 : 2;
	if (extensions[1] == NULL)
		extensionCount = enable_validation ? 2 : 1;
#endif
	VkApplicationInfo appInfo = {
		.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
		.pApplicationName = "HashLink Vulkan",
		.applicationVersion = VK_MAKE_VERSION(1, 0, 0),
		.pEngineName = "Heaps.io",
		.engineVersion = VK_MAKE_VERSION(1, 0, 0),
		.apiVersion = VK_API_VERSION_1_0,
	};
	VkInstanceCreateInfo info = {
		.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
#if defined(__APPLE__)
		.flags = VK_INSTANCE_CREATE_ENUMERATE_PORTABILITY_BIT_KHR,
#endif
		.pApplicationInfo = &appInfo,
		.enabledLayerCount = enable_validation ? 1 : 0,
		.enabledExtensionCount = extensionCount,
		.ppEnabledLayerNames = (const char* const[]){ "VK_LAYER_KHRONOS_validation" },
		.ppEnabledExtensionNames = extensions,
	};

	return vkCreateInstance(&info, NULL, &instance) == VK_SUCCESS;
}

HL_PRIM vbyte* HL_NAME(vk_make_ref)(vdynamic* v) {
	if (v->t->kind != HSTRUCT)
		hl_error("assert");
	return v->v.ptr;
}

HL_PRIM vbyte* HL_NAME(vk_make_array)(varray* a) {
	if (a->size == 0)
		return NULL;
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
	VkPhysicalDeviceMemoryProperties memProps;
	VkDevice device;
	VkQueue queue;
	VkSwapchainKHR swapchain;
}* VkContext;

HL_PRIM VkContext HL_NAME(vk_init_context)(VkSurfaceKHR surface, int* outQueue) {
	VkContext ctx = (VkContext)malloc(sizeof(struct _VkContext));
	memset(ctx, 0, sizeof(struct _VkContext));
	ctx->surface = surface;

	int queueFamily = 0;
	int physicalDeviceCount;
#define MAX_DEVICE_COUNT 16
#define MAX_QUEUE_COUNT 16
	VkPhysicalDevice deviceHandles[MAX_DEVICE_COUNT];
	VkQueueFamilyProperties queueFamilyProperties[MAX_QUEUE_COUNT];
	VkPhysicalDeviceProperties deviceProperties;
	VkPhysicalDeviceFeatures deviceFeatures;

	vkEnumeratePhysicalDevices(instance, &physicalDeviceCount, 0);
	physicalDeviceCount = physicalDeviceCount > MAX_DEVICE_COUNT ? MAX_DEVICE_COUNT : physicalDeviceCount;
	vkEnumeratePhysicalDevices(instance, &physicalDeviceCount, deviceHandles);

	for (int i = 0; i < physicalDeviceCount; i++) {
		int queueFamilyCount = 0;
		vkGetPhysicalDeviceQueueFamilyProperties(deviceHandles[i], &queueFamilyCount, NULL);
		queueFamilyCount = queueFamilyCount > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : queueFamilyCount;
		vkGetPhysicalDeviceQueueFamilyProperties(deviceHandles[i], &queueFamilyCount, queueFamilyProperties);
		vkGetPhysicalDeviceProperties(deviceHandles[i], &deviceProperties);
		vkGetPhysicalDeviceFeatures(deviceHandles[i], &deviceFeatures);
		for (int j = 0; j < queueFamilyCount; j++) {
			VkBool32 supportsPresent = VK_FALSE;
			vkGetPhysicalDeviceSurfaceSupportKHR(deviceHandles[i], j, ctx->surface, &supportsPresent);
			if (supportsPresent && (queueFamilyProperties[j].queueFlags & VK_QUEUE_GRAPHICS_BIT)) {
				queueFamily = j;
				ctx->pdevice = deviceHandles[i];
				break;
			}
		}
		if (ctx->pdevice)
			break;
	}

	VkDeviceQueueCreateInfo qinf = { .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO, .queueFamilyIndex = queueFamily, .queueCount = 1, .pQueuePriorities = (const float[]){ 1.0f } };
	VkDeviceCreateInfo dinf = {
		.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
		.queueCreateInfoCount = 1,
		.pQueueCreateInfos = 0,
		.enabledLayerCount = 0,
		.ppEnabledLayerNames = 0,
		.enabledExtensionCount = 1,
		.ppEnabledExtensionNames = (const char* const[]){ VK_KHR_SWAPCHAIN_EXTENSION_NAME },
		.pEnabledFeatures = 0,
		.pQueueCreateInfos = &qinf,
	};

	if (vkCreateDevice(ctx->pdevice, &dinf, NULL, &ctx->device) != VK_SUCCESS)
		return NULL;

	vkGetDeviceQueue(ctx->device, queueFamily, 0, &ctx->queue);
	vkGetPhysicalDeviceMemoryProperties(ctx->pdevice, &ctx->memProps);
	*outQueue = queueFamily;
	return ctx;
}

HL_PRIM vbyte* HL_NAME(vk_get_device_name)(VkContext ctx) {
	VkPhysicalDeviceProperties props;
	vkGetPhysicalDeviceProperties(ctx->pdevice, &props);
	return hl_copy_bytes(props.deviceName, (int)strlen(props.deviceName) + 1);
}

HL_PRIM VkPhysicalDeviceLimits* HL_NAME(vk_get_limits)(VkContext ctx) {
	VkPhysicalDeviceProperties props;
	vkGetPhysicalDeviceProperties(ctx->pdevice, &props);
	return (VkPhysicalDeviceLimits*)hl_copy_bytes((vbyte*)&props.limits, sizeof(VkPhysicalDeviceLimits));
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

HL_PRIM bool HL_NAME(vk_init_swapchain)(VkContext ctx, int width, int height, bool vsync, varray* outImages, VkFormat* outFormat) {

	vkDeviceWaitIdle(ctx->device);

	if (ctx->swapchain) {
		vkDestroySwapchainKHR(ctx->device, ctx->swapchain, NULL);
		ctx->swapchain = NULL;
	}

	int formatCount = 1;
	VkSurfaceFormatKHR format;
	vkGetPhysicalDeviceSurfaceFormatsKHR(ctx->pdevice, ctx->surface, &formatCount, 0);
	formatCount = 1;
	vkGetPhysicalDeviceSurfaceFormatsKHR(ctx->pdevice, ctx->surface, &formatCount, &format);
	format.format = format.format == VK_FORMAT_UNDEFINED ? VK_FORMAT_B8G8R8A8_UNORM : format.format;

	int modeCount = 0;
#define MAX_PRESENT_MODE_COUNT 16
	VkPresentModeKHR modes[MAX_PRESENT_MODE_COUNT];

	vkGetPhysicalDeviceSurfacePresentModesKHR(ctx->pdevice, ctx->surface, &modeCount, NULL);
	modeCount = modeCount > MAX_PRESENT_MODE_COUNT ? MAX_PRESENT_MODE_COUNT : modeCount;
	vkGetPhysicalDeviceSurfacePresentModesKHR(ctx->pdevice, ctx->surface, &modeCount, modes);

	VkPresentModeKHR presentMode = VK_PRESENT_MODE_FIFO_KHR;
	if (!vsync) {
		unsigned int i;
		for (i = 0; i < modeCount; i++) {
			if (modes[i] == VK_PRESENT_MODE_IMMEDIATE_KHR) {
				presentMode = VK_PRESENT_MODE_IMMEDIATE_KHR;
				break;
			}
		}
		if (presentMode == VK_PRESENT_MODE_FIFO_KHR) {
			for (i = 0; i < modeCount; i++) {
				if (modes[i] == VK_PRESENT_MODE_MAILBOX_KHR) {
					presentMode = VK_PRESENT_MODE_MAILBOX_KHR;
					break;
				}
			}
		}
	}

	VkSurfaceCapabilitiesKHR scaps;
	vkGetPhysicalDeviceSurfaceCapabilitiesKHR(ctx->pdevice, ctx->surface, &scaps);

	VkExtent2D swapchainExtent = scaps.currentExtent;
#define clamp(v, min, max) (((v) < (min)) ? (min) : ((v) > (max)) ? (max) : (v))
	if (swapchainExtent.width == UINT32_MAX) {
		swapchainExtent.width = clamp((unsigned)width, scaps.minImageExtent.width, scaps.maxImageExtent.width);
		swapchainExtent.height = clamp((unsigned)height, scaps.minImageExtent.height, scaps.maxImageExtent.height);
	}

	unsigned int imageCapacity = outImages->size;
	unsigned int imageCount = scaps.minImageCount + 1;
	if (imageCount > imageCapacity)
		imageCount = imageCapacity;
	if (scaps.maxImageCount > 0 && imageCount > scaps.maxImageCount)
		imageCount = scaps.maxImageCount;
	if (imageCount < scaps.minImageCount)
		return false;

	VkSwapchainCreateInfoKHR swapInfo = {
		.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR,
		.surface = ctx->surface,
		.minImageCount = imageCount,
		.imageFormat = format.format,
		.imageColorSpace = format.colorSpace,
		.imageExtent = swapchainExtent,
		.imageArrayLayers = 1,
		.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT,
		.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE,
		.preTransform = scaps.currentTransform,
		.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,
		.presentMode = presentMode,
		.clipped = VK_TRUE,
	};

	if (vkCreateSwapchainKHR(ctx->device, &swapInfo, 0, &ctx->swapchain) != VK_SUCCESS) {
		return false;
	}

	outImages->size = imageCapacity;
	if (vkGetSwapchainImagesKHR(ctx->device, ctx->swapchain, &outImages->size, hl_aptr(outImages, void)) != VK_SUCCESS) {
		return false;
	}
	*outFormat = format.format;

	return true;
}

HL_PRIM VkShaderModule HL_NAME(vk_create_shader_module)(VkContext ctx, vbyte* data, int len) {
	VkShaderModule module = NULL;
	VkShaderModuleCreateInfo inf = {
		.sType = VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
		.codeSize = len,
		.pCode = (const uint32_t*)data,
	};
	vkCreateShaderModule(ctx->device, &inf, NULL, &module);
	return module;
}

HL_PRIM VkPipelineLayout HL_NAME(vk_create_pipeline_layout)(VkContext ctx, VkPipelineLayoutCreateInfo* info) {
	VkPipelineLayout p = NULL;
	vkCreatePipelineLayout(ctx->device, info, NULL, &p);
	return p;
}

HL_PRIM VkPipeline HL_NAME(vk_create_graphics_pipeline)(VkContext ctx, VkGraphicsPipelineCreateInfo* info) {
	VkPipeline p = NULL;
	vkCreateGraphicsPipelines(ctx->device, NULL, 1, info, NULL, &p);
	return p;
}

HL_PRIM VkRenderPass HL_NAME(vk_create_render_pass)(VkContext ctx, VkRenderPassCreateInfo* info) {
	VkRenderPass p = NULL;
	vkCreateRenderPass(ctx->device, info, NULL, &p);
	return p;
}

HL_PRIM VkImageView HL_NAME(vk_create_image_view)(VkContext ctx, VkImageViewCreateInfo* info) {
	VkImageView i = NULL;
	vkCreateImageView(ctx->device, info, NULL, &i);
	return i;
}

HL_PRIM VkFramebuffer HL_NAME(vk_create_framebuffer)(VkContext ctx, VkFramebufferCreateInfo* info) {
	VkFramebuffer b = NULL;
	vkCreateFramebuffer(ctx->device, info, NULL, &b);
	return b;
}

HL_PRIM VkDescriptorSetLayout HL_NAME(vk_create_descriptor_set_layout)(VkContext ctx, VkDescriptorSetLayoutCreateInfo* info) {
	VkDescriptorSetLayout p = NULL;
	vkCreateDescriptorSetLayout(ctx->device, info, NULL, &p);
	return p;
}

HL_PRIM VkBuffer HL_NAME(vk_create_buffer)(VkContext ctx, VkBufferCreateInfo* info) {
	VkBuffer b = NULL;
	vkCreateBuffer(ctx->device, info, NULL, &b);
	return b;
}

HL_PRIM void HL_NAME(vk_get_buffer_memory_requirements)(VkContext ctx, VkBuffer buf, VkMemoryRequirements* info) {
	vkGetBufferMemoryRequirements(ctx->device, buf, info);
}

HL_PRIM VkDeviceMemory HL_NAME(vk_allocate_memory)(VkContext ctx, VkMemoryAllocateInfo* inf) {
	VkDeviceMemory m = NULL;
	vkAllocateMemory(ctx->device, inf, NULL, &m);
	return m;
}

HL_PRIM vbyte* HL_NAME(vk_map_memory)(VkContext ctx, VkDeviceMemory mem, int offset, int size, int flags) {
	if (mem == NULL || size <= 0)
		return NULL;
	void* ptr = NULL;
	if (vkMapMemory(ctx->device, mem, offset, size, flags, &ptr) != VK_SUCCESS)
		return NULL;
	return ptr;
}

HL_PRIM void HL_NAME(vk_unmap_memory)(VkContext ctx, VkDeviceMemory mem) {
	vkUnmapMemory(ctx->device, mem);
}

HL_PRIM bool HL_NAME(vk_bind_buffer_memory)(VkContext ctx, VkBuffer buf, VkDeviceMemory mem, int offset) {
	return vkBindBufferMemory(ctx->device, buf, mem, offset) == VK_SUCCESS;
}

HL_PRIM VkImage HL_NAME(vk_create_image)(VkContext ctx, VkImageCreateInfo* info) {
	VkImage i = NULL;
	vkCreateImage(ctx->device, info, NULL, &i);
	return i;
}

HL_PRIM void HL_NAME(vk_get_image_memory_requirements)(VkContext ctx, VkImage img, VkMemoryRequirements* info) {
	vkGetImageMemoryRequirements(ctx->device, img, info);
}

HL_PRIM bool HL_NAME(vk_bind_image_memory)(VkContext ctx, VkImage img, VkDeviceMemory mem, int offset) {
	return vkBindImageMemory(ctx->device, img, mem, offset) == VK_SUCCESS;
}

HL_PRIM VkCommandPool HL_NAME(vk_create_command_pool)(VkContext ctx, VkCommandPoolCreateInfo* inf) {
	VkCommandPool pool = NULL;
	vkCreateCommandPool(ctx->device, inf, NULL, &pool);
	return pool;
}

HL_PRIM bool HL_NAME(vk_allocate_command_buffers)(VkContext ctx, VkCommandBufferAllocateInfo* inf, varray* buffers) {
	return vkAllocateCommandBuffers(ctx->device, inf, hl_aptr(buffers, VkCommandBuffer)) == VK_SUCCESS;
}

HL_PRIM VkDescriptorPool HL_NAME(vk_create_descriptor_pool)(VkContext ctx, VkDescriptorPoolCreateInfo* inf) {
	VkDescriptorPool pool = NULL;
	vkCreateDescriptorPool(ctx->device, inf, NULL, &pool);
	return pool;
}

HL_PRIM bool HL_NAME(vk_allocate_descriptor_sets)(VkContext ctx, VkDescriptorSetAllocateInfo* inf, varray* sets) {
	return vkAllocateDescriptorSets(ctx->device, inf, hl_aptr(sets, VkDescriptorSet)) == VK_SUCCESS;
}

HL_PRIM void HL_NAME(vk_update_descriptor_sets)(VkContext ctx, int writeCount, VkWriteDescriptorSet* write, int copyCount, VkCopyDescriptorSet* copy) {
	vkUpdateDescriptorSets(ctx->device, writeCount, write, copyCount, copy);
}

HL_PRIM void HL_NAME(vk_update_descriptor_image_sampler)(VkContext ctx, VkDescriptorSet set, int binding, VkImageView view, VkSampler sampler, VkImageLayout layout) {
	VkDescriptorImageInfo imageInfo = {
		.sampler = sampler,
		.imageView = view,
		.imageLayout = layout,
	};
	VkWriteDescriptorSet write = {
		.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET,
		.dstSet = set,
		.dstBinding = binding,
		.descriptorCount = 1,
		.descriptorType = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER,
		.pImageInfo = &imageInfo,
	};
	vkUpdateDescriptorSets(ctx->device, 1, &write, 0, NULL);
}

HL_PRIM VkSampler HL_NAME(vk_create_sampler)(VkContext ctx, VkSamplerCreateInfo* inf) {
	VkSampler sampler = NULL;
	vkCreateSampler(ctx->device, inf, NULL, &sampler);
	return sampler;
}

HL_PRIM VkFence HL_NAME(vk_create_fence)(VkContext ctx, VkFenceCreateInfo* inf) {
	VkFence fence = NULL;
	vkCreateFence(ctx->device, inf, NULL, &fence);
	return fence;
}

HL_PRIM VkSemaphore HL_NAME(vk_create_semaphore)(VkContext ctx, VkSemaphoreCreateInfo* inf) {
	VkSemaphore s = NULL;
	vkCreateSemaphore(ctx->device, inf, NULL, &s);
	return s;
}

HL_PRIM void HL_NAME(vk_reset_fence)(VkContext ctx, VkFence f) {
	vkResetFences(ctx->device, 1, &f);
}

HL_PRIM bool HL_NAME(vk_wait_for_fence)(VkContext ctx, VkFence f, double timeout) {
	uint64_t t = (uint64_t)timeout;
	return vkWaitForFences(ctx->device, 1, &f, VK_TRUE, t) == VK_SUCCESS;
}

HL_PRIM int HL_NAME(vk_get_next_image_index)(VkContext ctx, VkSemaphore lock) {
	int image = -1;
	if (vkAcquireNextImageKHR(ctx->device, ctx->swapchain, UINT64_MAX, lock, VK_NULL_HANDLE, &image) != VK_SUCCESS) {
		return -1;
	}
	return image;
}

HL_PRIM void HL_NAME(vk_queue_submit)(VkContext ctx, VkSubmitInfo* inf, VkFence fence) {
	vkQueueSubmit(ctx->queue, 1, inf, fence);
}

HL_PRIM void HL_NAME(vk_queue_wait_idle)(VkContext ctx) {
	vkQueueWaitIdle(ctx->queue);
}

HL_PRIM void HL_NAME(vk_present)(VkContext ctx, VkSemaphore sem, int image) {
	VkPresentInfoKHR presentInfo = {
		.sType = VK_STRUCTURE_TYPE_PRESENT_INFO_KHR,
		.waitSemaphoreCount = 1,
		.pWaitSemaphores = &sem,
		.swapchainCount = 1,
		.pSwapchains = &ctx->swapchain,
		.pImageIndices = &image,
	};
	vkQueuePresentKHR(ctx->queue, &presentInfo);
}

HL_PRIM void HL_NAME(vk_destroy_buffer)(VkContext ctx, VkBuffer buf) {
	vkDestroyBuffer(ctx->device, buf, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_image)(VkContext ctx, VkImage img) {
	vkDestroyImage(ctx->device, img, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_image_view)(VkContext ctx, VkImageView view) {
	vkDestroyImageView(ctx->device, view, NULL);
}

HL_PRIM void HL_NAME(vk_free_memory)(VkContext ctx, VkDeviceMemory mem) {
	vkFreeMemory(ctx->device, mem, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_fence)(VkContext ctx, VkFence fence) {
	vkDestroyFence(ctx->device, fence, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_semaphore)(VkContext ctx, VkSemaphore sem) {
	vkDestroySemaphore(ctx->device, sem, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_command_pool)(VkContext ctx, VkCommandPool pool) {
	vkDestroyCommandPool(ctx->device, pool, NULL);
}

HL_PRIM void HL_NAME(vk_free_command_buffers)(VkContext ctx, VkCommandPool pool, varray* cmd) {
	vkFreeCommandBuffers(ctx->device, pool, cmd->size, hl_aptr(cmd, VkCommandBuffer));
}

HL_PRIM void HL_NAME(vk_destroy_framebuffer)(VkContext ctx, VkFramebuffer fb) {
	vkDestroyFramebuffer(ctx->device, fb, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_render_pass)(VkContext ctx, VkRenderPass pass) {
	vkDestroyRenderPass(ctx->device, pass, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_descriptor_pool)(VkContext ctx, VkDescriptorPool pool) {
	vkDestroyDescriptorPool(ctx->device, pool, NULL);
}

HL_PRIM void HL_NAME(vk_destroy_sampler)(VkContext ctx, VkSampler sampler) {
	vkDestroySampler(ctx->device, sampler, NULL);
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

DEFINE_PRIM(_BOOL, vk_init, _BOOL);
DEFINE_PRIM(_VCTX, vk_init_context, _BYTES _REF(_I32));
DEFINE_PRIM(_BOOL, vk_init_swapchain, _VCTX _I32 _I32 _BOOL _ARR _REF(_I32));
DEFINE_PRIM(_BYTES, vk_make_array, _ARR);
DEFINE_PRIM(_BYTES, vk_make_ref, _DYN);
DEFINE_PRIM(_STRUCT, vk_get_limits, _VCTX);
DEFINE_PRIM(_BYTES, vk_get_device_name, _VCTX);
DEFINE_PRIM(_I32, vk_find_memory_type, _VCTX _I32 _I32);
DEFINE_PRIM(_SHADER_MODULE, vk_create_shader_module, _VCTX _BYTES _I32);
DEFINE_PRIM(_GPIPELINE, vk_create_graphics_pipeline, _VCTX _STRUCT);
DEFINE_PRIM(_PIPELAYOUT, vk_create_pipeline_layout, _VCTX _STRUCT);
DEFINE_PRIM(_RENDERPASS, vk_create_render_pass, _VCTX _STRUCT);
DEFINE_PRIM(_IMAGE_VIEW, vk_create_image_view, _VCTX _STRUCT);
DEFINE_PRIM(_FENCE, vk_create_fence, _VCTX _STRUCT);
DEFINE_PRIM(_BOOL, vk_wait_for_fence, _VCTX _FENCE _F64);
DEFINE_PRIM(_VOID, vk_reset_fence, _VCTX _FENCE);
DEFINE_PRIM(_CMD_POOL, vk_create_command_pool, _VCTX _STRUCT);
DEFINE_PRIM(_BOOL, vk_allocate_command_buffers, _VCTX _STRUCT _ARR);
DEFINE_PRIM(_FRAMEBUFFER, vk_create_framebuffer, _VCTX _STRUCT);
DEFINE_PRIM(_DLAYOUT, vk_create_descriptor_set_layout, _VCTX _STRUCT);
DEFINE_PRIM(_SAMPLER, vk_create_sampler, _VCTX _STRUCT);
DEFINE_PRIM(_BUFFER, vk_create_buffer, _VCTX _STRUCT);
DEFINE_PRIM(_VOID, vk_get_buffer_memory_requirements, _VCTX _BUFFER _STRUCT);
DEFINE_PRIM(_IMAGE, vk_create_image, _VCTX _STRUCT);
DEFINE_PRIM(_VOID, vk_get_image_memory_requirements, _VCTX _IMAGE _STRUCT);
DEFINE_PRIM(_BOOL, vk_bind_image_memory, _VCTX _IMAGE _MEMORY _I32);
DEFINE_PRIM(_MEMORY, vk_allocate_memory, _VCTX _STRUCT);
DEFINE_PRIM(_BYTES, vk_map_memory, _VCTX _MEMORY _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_unmap_memory, _VCTX _MEMORY);
DEFINE_PRIM(_BOOL, vk_bind_buffer_memory, _VCTX _BUFFER _MEMORY _I32);
DEFINE_PRIM(_SEMAPHORE, vk_create_semaphore, _VCTX _STRUCT);
DEFINE_PRIM(_I32, vk_get_next_image_index, _VCTX _SEMAPHORE);
DEFINE_PRIM(_VOID, vk_queue_submit, _VCTX _STRUCT _FENCE);
DEFINE_PRIM(_VOID, vk_queue_wait_idle, _VCTX);
DEFINE_PRIM(_VOID, vk_present, _VCTX _SEMAPHORE _I32);
DEFINE_PRIM(_VOID, vk_get_pdevice_format_props, _VCTX _I32 _STRUCT);
DEFINE_PRIM(_DPOOL, vk_create_descriptor_pool, _VCTX _STRUCT);
DEFINE_PRIM(_BOOL, vk_allocate_descriptor_sets, _VCTX _STRUCT _ARR);
DEFINE_PRIM(_VOID, vk_update_descriptor_sets, _VCTX _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_update_descriptor_image_sampler, _VCTX _DSET _I32 _IMAGE_VIEW _SAMPLER _I32);
DEFINE_PRIM(_VOID, vk_destroy_image, _VCTX _IMAGE);
DEFINE_PRIM(_VOID, vk_destroy_image_view, _VCTX _IMAGE_VIEW);
DEFINE_PRIM(_VOID, vk_destroy_framebuffer, _VCTX _FRAMEBUFFER);
DEFINE_PRIM(_VOID, vk_destroy_render_pass, _VCTX _RENDERPASS);
DEFINE_PRIM(_VOID, vk_free_command_buffers, _VCTX _CMD_POOL _ARR);
DEFINE_PRIM(_VOID, vk_destroy_command_pool, _VCTX _CMD_POOL);
DEFINE_PRIM(_VOID, vk_destroy_buffer, _VCTX _BUFFER);
DEFINE_PRIM(_VOID, vk_destroy_fence, _VCTX _FENCE);
DEFINE_PRIM(_VOID, vk_destroy_semaphore, _VCTX _SEMAPHORE);
DEFINE_PRIM(_VOID, vk_free_memory, _VCTX _MEMORY);
DEFINE_PRIM(_VOID, vk_destroy_descriptor_pool, _VCTX _DPOOL);
DEFINE_PRIM(_VOID, vk_destroy_sampler, _VCTX _SAMPLER);

// ------ COMMAND BUFFER OPERATIONS -----------------------

HL_PRIM void HL_NAME(vk_command_begin)(VkCommandBuffer out, VkCommandBufferBeginInfo* inf) {
	vkBeginCommandBuffer(out, inf);
}

HL_PRIM void HL_NAME(vk_command_end)(VkCommandBuffer out) {
	vkEndCommandBuffer(out);
}

HL_PRIM void HL_NAME(vk_clear_color_image)(VkCommandBuffer out, VkImage img, VkImageLayout layout, VkClearColorValue* colors, int count, VkImageSubresourceRange* range) {
	vkCmdClearColorImage(out, img, layout, colors, count, range);
}

HL_PRIM void HL_NAME(vk_clear_attachments)(VkCommandBuffer out, int count, VkClearAttachment* attachs, int rectCount, VkClearRect* rects) {
	vkCmdClearAttachments(out, count, attachs, rectCount, rects);
}

HL_PRIM void HL_NAME(vk_clear_depth_stencil_image)(VkCommandBuffer out, VkImage img, VkImageLayout layout, VkClearDepthStencilValue* values, int count, VkImageSubresourceRange* range) {
	vkCmdClearDepthStencilImage(out, img, layout, values, count, range);
}

HL_PRIM void HL_NAME(vk_draw_indexed)(VkCommandBuffer out, int indexCount, int instanceCount, int firstIndex, int vertexOffset, int firstInstance) {
	vkCmdDrawIndexed(out, indexCount, instanceCount, firstIndex, vertexOffset, firstInstance);
}

HL_PRIM void HL_NAME(vk_bind_pipeline)(VkCommandBuffer out, int bindPoint, VkPipeline pipeline) {
	vkCmdBindPipeline(out, (VkPipelineBindPoint)bindPoint, pipeline);
}

HL_PRIM void HL_NAME(vk_begin_render_pass)(VkCommandBuffer out, VkRenderPassBeginInfo* info, int contents) {
	vkCmdBeginRenderPass(out, info, (VkSubpassContents)contents);
}

HL_PRIM void HL_NAME(vk_bind_index_buffer)(VkCommandBuffer out, VkBuffer buf, int offset, int type) {
	vkCmdBindIndexBuffer(out, buf, offset, type);
}

HL_PRIM void HL_NAME(vk_bind_vertex_buffers)(VkCommandBuffer out, int first, int count, VkBuffer* buffers, VkDeviceSize* sizes) {
	vkCmdBindVertexBuffers(out, first, count, buffers, sizes);
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

HL_PRIM void HL_NAME(vk_end_render_pass)(VkCommandBuffer out) {
	vkCmdEndRenderPass(out);
}

HL_PRIM void HL_NAME(vk_push_constants)(VkCommandBuffer out, VkPipelineLayout layout, VkShaderStageFlags flags, int offset, int size, vbyte* data) {
	vkCmdPushConstants(out, layout, flags, offset, size, data);
}

HL_PRIM void HL_NAME(vk_copy_buffer_to_image)(VkCommandBuffer out, VkBuffer buf, VkImage img, VkImageLayout layout, int count, VkBufferImageCopy* regions) {
	vkCmdCopyBufferToImage(out, buf, img, layout, count, regions);
}

HL_PRIM void HL_NAME(vk_pipeline_barrier)(VkCommandBuffer out, VkPipelineStageFlags srcMask, VkPipelineStageFlags dstMask, VkDependencyFlags flags, int memCount, VkMemoryBarrier* memBarriers, int bufferCount, VkBufferMemoryBarrier* bufBarriers,
                                          int imageCount, VkImageMemoryBarrier* imgBarriers) {
	vkCmdPipelineBarrier(out, srcMask, dstMask, flags, memCount, memBarriers, bufferCount, bufBarriers, imageCount, imgBarriers);
}

HL_PRIM void HL_NAME(vk_bind_descriptor_sets)(VkCommandBuffer out, VkPipelineBindPoint bind, VkPipelineLayout layout, int first, int count, VkDescriptorSet* sets, int offsetCount, int* offsets) {
	vkCmdBindDescriptorSets(out, bind, layout, first, count, sets, offsetCount, offsets);
}

HL_PRIM void HL_NAME(vk_bind_descriptor_set)(VkCommandBuffer out, VkPipelineBindPoint bind, VkPipelineLayout layout, int first, VkDescriptorSet set) {
	vkCmdBindDescriptorSets(out, bind, layout, first, 1, &set, 0, NULL);
}

DEFINE_PRIM(_VOID, vk_command_begin, _CMD _STRUCT);
DEFINE_PRIM(_VOID, vk_command_end, _CMD);
DEFINE_PRIM(_VOID, vk_clear_color_image, _CMD _IMAGE _I32 _BYTES _I32 _STRUCT);
DEFINE_PRIM(_VOID, vk_clear_depth_stencil_image, _CMD _IMAGE _I32 _BYTES _I32 _STRUCT);
DEFINE_PRIM(_VOID, vk_clear_attachments, _CMD _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_draw_indexed, _CMD _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_bind_pipeline, _CMD _I32 _GPIPELINE);
DEFINE_PRIM(_VOID, vk_begin_render_pass, _CMD _STRUCT _I32);
DEFINE_PRIM(_VOID, vk_bind_index_buffer, _CMD _BUFFER _I32 _I32);
DEFINE_PRIM(_VOID, vk_bind_vertex_buffers, _CMD _I32 _I32 _BYTES _BYTES);
DEFINE_PRIM(_VOID, vk_bind_vertex_buffer, _CMD _I32 _BUFFER _I32);
DEFINE_PRIM(_VOID, vk_set_viewport, _CMD _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_set_viewport1, _CMD _I32 _F32 _F32 _F32 _F32 _F32 _F32);
DEFINE_PRIM(_VOID, vk_set_scissor, _CMD _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_set_scissor1, _CMD _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, vk_push_constants, _CMD _PIPELAYOUT _I32 _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_end_render_pass, _CMD);
DEFINE_PRIM(_VOID, vk_copy_buffer_to_image, _CMD _BUFFER _IMAGE _I32 _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_pipeline_barrier, _CMD _I32 _I32 _I32 _I32 _BYTES _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_bind_descriptor_sets, _CMD _I32 _PIPELAYOUT _I32 _I32 _BYTES _I32 _BYTES);
DEFINE_PRIM(_VOID, vk_bind_descriptor_set, _CMD _I32 _PIPELAYOUT _I32 _DSET);
