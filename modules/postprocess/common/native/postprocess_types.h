#pragma once

#include <stdint.h>

#ifdef __cplusplus
enum class PostProcessBackend : int { Vulkan = 2, D3D11 = 3, D3D12 = 4 };
#else
typedef int PostProcessBackend;
#endif

typedef struct PostProcessDevice {
	PostProcessBackend backend;
	void* device;
	void* instance;
	void* physicalDevice;
	int graphicsQueueFamily;
	int graphicsQueueIndex;
	int computeQueueFamily;
	int computeQueueIndex;
} PostProcessDevice;

typedef struct TextureResource {
	void* native;
	void* memory;
	void* view;
	uint32_t state;
	uint32_t width;
	uint32_t height;
	uint32_t format;
	uint32_t mipLevels;
	uint32_t arrayLayers;
	uint32_t usage;
	uint32_t flags;
} TextureResource;
