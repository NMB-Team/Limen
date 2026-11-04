#pragma once
#include <vulkan/vulkan.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif
void* limen_vma_create(VkInstance instance, VkPhysicalDevice physical, VkDevice device, uint32_t version, bool budget, int* result);
bool limen_vma_has_allocators(VkDevice device);
#ifdef __cplusplus
}
#endif
