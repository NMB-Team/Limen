#pragma once

#include "graphics_driver.h"
#include <stdint.h>

#ifdef __cplusplus
enum class PostProcessBackend : int {
	Vulkan = LIMEN_GRAPHICS_VULKAN,
	D3D11 = LIMEN_GRAPHICS_D3D11,
	D3D12 = LIMEN_GRAPHICS_D3D12,
};
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
