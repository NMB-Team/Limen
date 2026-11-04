#include "../backend/src/graphics/vulkan/memory_allocator.cpp"

extern "C" void* limen_vulkan_memory_create(void*, int*) {
	return nullptr;
}

#include <cstdio>
#include <cstring>

#define CHECK(x)                                                           \
	do {                                                                   \
		if (!(x)) {                                                        \
			std::fprintf(stderr, "Failed at line %d: %s\n", __LINE__, #x); \
			return 1;                                                      \
		}                                                                  \
	} while (0)

static int validationErrors;

static VKAPI_ATTR VkBool32 VKAPI_CALL validation(VkDebugUtilsMessageSeverityFlagBitsEXT severity, VkDebugUtilsMessageTypeFlagsEXT, const VkDebugUtilsMessengerCallbackDataEXT* data, void*) {
	if (severity & VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT) {
		validationErrors++;
		std::fprintf(stderr, "%s\n", data->pMessage);
	}

	return VK_FALSE;
}

int main() {
	int stack;
	hl_global_init();
	hl_register_thread(&stack);

	VkApplicationInfo app = {};
	app.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
	app.apiVersion = VK_API_VERSION_1_2;

	VkInstanceCreateInfo ici = {};
	ici.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
	ici.pApplicationInfo = &app;

	uint32_t layerCount = 0;
	vkEnumerateInstanceLayerProperties(&layerCount, nullptr);

	auto layers = new VkLayerProperties[layerCount];
	vkEnumerateInstanceLayerProperties(&layerCount, layers);

	bool validate = false;

	for (uint32_t i = 0; i < layerCount; i++)
		validate |= std::strcmp(layers[i].layerName, "VK_LAYER_KHRONOS_validation") == 0;

	delete[] layers;

	const char* layer = "VK_LAYER_KHRONOS_validation";
	const char* extension = VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
	VkDebugUtilsMessengerCreateInfoEXT debug = {};
	debug.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
	debug.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
	debug.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
	debug.pfnUserCallback = validation;

	if (validate) {
		ici.enabledLayerCount = ici.enabledExtensionCount = 1;
		ici.ppEnabledLayerNames = &layer;
		ici.ppEnabledExtensionNames = &extension;
		ici.pNext = &debug;
	}

	VkInstance instance = VK_NULL_HANDLE;
	VkResult instanceResult = vkCreateInstance(&ici, nullptr, &instance);

	if (instanceResult == VK_ERROR_INCOMPATIBLE_DRIVER) {
		std::fprintf(stderr, "SKIP: No compatible Vulkan driver available\n");
		return 77;
	}

	CHECK(instanceResult == VK_SUCCESS);

	VkDebugUtilsMessengerEXT messenger = VK_NULL_HANDLE;

	if (validate) {
		auto create = (PFN_vkCreateDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
		CHECK(create(instance, &debug, nullptr, &messenger) == VK_SUCCESS);
	}

	std::printf("Validation layer: %s\n", validate ? "enabled" : "unavailable");

	uint32_t count = 0;
	CHECK(vkEnumeratePhysicalDevices(instance, &count, nullptr) == VK_SUCCESS && count);
	auto devices = new VkPhysicalDevice[count];
	CHECK(vkEnumeratePhysicalDevices(instance, &count, devices) == VK_SUCCESS);
	VkPhysicalDevice physical = devices[0];
	delete[] devices;

	vkGetPhysicalDeviceQueueFamilyProperties(physical, &count, nullptr);
	auto queues = new VkQueueFamilyProperties[count];
	vkGetPhysicalDeviceQueueFamilyProperties(physical, &count, queues);

	uint32_t family = 0;
	while (family < count && !(queues[family].queueFlags & VK_QUEUE_GRAPHICS_BIT))
		family++;

	delete[] queues;
	CHECK(family < count);

	float priority = 1;
	VkDeviceQueueCreateInfo q = {};
	q.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
	q.queueFamilyIndex = family;
	q.queueCount = 1;
	q.pQueuePriorities = &priority;

	VkDeviceCreateInfo dci = {};
	dci.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;
	dci.queueCreateInfoCount = 1;
	dci.pQueueCreateInfos = &q;

	VkDevice device;
	CHECK(vkCreateDevice(physical, &dci, nullptr, &device) == VK_SUCCESS);

	int result;
	auto a = (Allocator*)limen_vma_create(instance, physical, device, app.apiVersion, false, &result);
	CHECK(a && result == VK_SUCCESS && limen_vma_has_allocators(device));

	for (bool dedicated : { false, true }) {
		VkBufferCreateInfo bci = {};
		bci.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
		bci.size = 65536;
		bci.usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
		VkBuffer buffer;
		CHECK(vkCreateBuffer(device, &bci, nullptr, &buffer) == VK_SUCCESS);

		auto b = limen_vulkan_memory_allocate_buffer(a, buffer, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, 0, dedicated, &result);
		CHECK(b && result == VK_SUCCESS);
		CHECK(limen_vulkan_memory_bind_buffer(b, buffer) == VK_SUCCESS);

		auto data = limen_vulkan_memory_map(b, &result);
		CHECK(data && result == VK_SUCCESS);

		std::memset(data, 42, 65536);
		CHECK(limen_vulkan_memory_flush(b, 0, 65536) == VK_SUCCESS);
		CHECK(limen_vulkan_memory_invalidate(b, 0, 65536) == VK_SUCCESS);

		limen_vulkan_memory_unmap(b);

		vkDestroyBuffer(device, buffer, nullptr);
		limen_vulkan_memory_release(b);
		limen_vulkan_memory_release(b);

		VkImageCreateInfo imageInfo = {};
		imageInfo.sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO;
		imageInfo.imageType = VK_IMAGE_TYPE_2D;
		imageInfo.format = VK_FORMAT_R8G8B8A8_UNORM;
		imageInfo.extent = { 64, 64, 1 };
		imageInfo.mipLevels = imageInfo.arrayLayers = 1;
		imageInfo.samples = VK_SAMPLE_COUNT_1_BIT;
		imageInfo.tiling = VK_IMAGE_TILING_LINEAR;
		imageInfo.usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT;
		VkImage image;
		CHECK(vkCreateImage(device, &imageInfo, nullptr, &image) == VK_SUCCESS);

		auto i = limen_vulkan_memory_allocate_image(a, image, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT, 0, dedicated, &result);
		CHECK(i && result == VK_SUCCESS);
		CHECK(limen_vulkan_memory_bind_image(i, image) == VK_SUCCESS);

		int type;
		VkDeviceMemory memory;
		int64 offset, size;
		limen_vulkan_memory_info(i, &type, &memory, &offset, &size);
		CHECK(memory && size > 0 && offset >= 0);

		auto imageData = limen_vulkan_memory_map(i, &result);
		CHECK(imageData && result == VK_SUCCESS);
		CHECK(limen_vulkan_memory_flush(i, 0, -1) == VK_SUCCESS);
		CHECK(limen_vulkan_memory_invalidate(i, 0, -1) == VK_SUCCESS);

		limen_vulkan_memory_unmap(i);
		limen_vulkan_memory_set_name(i, (vbyte*)"test image");

		vkDestroyImage(device, image, nullptr);
		limen_vulkan_memory_release(i);
	}

	int blocks, allocations;
	int64 blockBytes, allocationBytes, usage, budget;
	limen_vulkan_memory_statistics(a, &blocks, &allocations, &blockBytes, &allocationBytes);
	CHECK(allocations == 0 && allocationBytes == 0);

	limen_vulkan_memory_budget(a, 0, &usage, &budget);
	CHECK(budget > 0);

	limen_vulkan_memory_destroy(a);
	CHECK(!limen_vma_has_allocators(device));

	vkDestroyDevice(device, nullptr);
	if (messenger) {
		auto destroy = (PFN_vkDestroyDebugUtilsMessengerEXT)vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
		destroy(instance, messenger, nullptr);
	}

	vkDestroyInstance(instance, nullptr);
	CHECK(validationErrors == 0);

	return 0;
}
