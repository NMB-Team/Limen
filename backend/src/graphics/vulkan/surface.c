#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>
#include "native_window.h"
#include <vulkan/vulkan.h>

extern VkInstance vk_get_instance(void);

HL_PRIM void* HL_NAME(win_get_vulkan)(void* window) {
	uint64_t surface = 0;
	if (!limen_vulkan_create_surface(window, vk_get_instance(), &surface))
		return nullptr;
	return (void*)(uintptr_t)surface;
}

DEFINE_PRIM(_BYTES, win_get_vulkan, _ABSTRACT(limen_window));
