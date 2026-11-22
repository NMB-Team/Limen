#ifdef nullptr
#undef nullptr
#endif
#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>
#define VMA_STATIC_VULKAN_FUNCTIONS 0
#define VMA_DYNAMIC_VULKAN_FUNCTIONS 1
#define VMA_IMPLEMENTATION
#include <vk_mem_alloc.h>
#include "memory_allocator.h"

struct Allocator {
	VmaAllocator native;
	VkDevice device;
	int allocations;
	Allocator* next;
};

struct Allocation {
	VmaAllocation native;
	Allocator* owner;
	int mappings;
	bool aliasable;
};

static Allocator* allocators;
static bool rooted;

static void require_allocator(Allocator* a) {
	if (!a || !a->native)
		hl_error("VMA allocator is closed");
}

static void require_allocation(Allocation* a) {
	if (!a || !a->native)
		hl_error("VMA allocation is closed");
}

extern "C" bool limen_vma_has_allocators(VkDevice device) {
	for (auto a = allocators; a; a = a->next)
		if (a->device == device)
			return true;
	return false;
}

extern "C" void* limen_vma_create(VkInstance instance, VkPhysicalDevice physical, VkDevice device, uint32_t version, bool budget, int* result) {
	if (!rooted) {
		hl_add_root(&allocators);
		rooted = true;
	}

	auto a = (Allocator*)hl_gc_alloc_raw(sizeof(Allocator));
	*a = {};
	VmaVulkanFunctions functions = {};
	functions.vkGetInstanceProcAddr = vkGetInstanceProcAddr;
	functions.vkGetDeviceProcAddr = vkGetDeviceProcAddr;

	VmaAllocatorCreateInfo info = {};
	info.instance = instance;
	info.physicalDevice = physical;
	info.device = device;
	info.vulkanApiVersion = version;
	info.flags = budget ? VMA_ALLOCATOR_CREATE_EXT_MEMORY_BUDGET_BIT : 0;
	info.pVulkanFunctions = &functions;
	info.preferredLargeHeapBlockSize = 64ull * 1024 * 1024;
	*result = vmaCreateAllocator(&info, &a->native);
	if (*result != VK_SUCCESS)
		return nullptr;

	a->device = device;
	a->next = allocators;
	allocators = a;

	return a;
}

HL_PRIM void HL_NAME(memory_destroy)(Allocator* a) {
	if (!a || !a->native)
		return;
	if (a->allocations)
		hl_error("Release VMA allocations before destroying their allocator");

	auto link = &allocators;

	while (*link != a)
		link = &(*link)->next;
	*link = a->next;
	vmaDestroyAllocator(a->native);
	a->native = nullptr;
	a->next = nullptr;
}

HL_PRIM Allocation* HL_NAME(memory_allocate_buffer)(Allocator* a, VkBuffer resource, int required, int preferred, bool dedicated, int* result) {
	require_allocator(a);

	if (!resource) {
		*result = VK_ERROR_INITIALIZATION_FAILED;
		return nullptr;
	}

	auto allocation = (Allocation*)hl_gc_alloc_raw(sizeof(Allocation));
	*allocation = {};
	VmaAllocationCreateInfo info = {};
	info.requiredFlags = required;
	info.preferredFlags = preferred;
	info.flags = dedicated ? VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT : 0;
	*result = vmaAllocateMemoryForBuffer(a->native, resource, &info, &allocation->native, nullptr);
	if (*result != VK_SUCCESS)
		return nullptr;

	allocation->owner = a;
	a->allocations++;

	return allocation;
}

HL_PRIM int HL_NAME(memory_bind_buffer)(Allocation* a, VkBuffer resource) {
	require_allocation(a);

	return vmaBindBufferMemory(a->owner->native, a->native, resource);
}

HL_PRIM Allocation* HL_NAME(memory_allocate_image)(Allocator* a, VkImage resource, int required, int preferred, bool dedicated, int* result) {
	require_allocator(a);

	if (!resource) {
		*result = VK_ERROR_INITIALIZATION_FAILED;
		return nullptr;
	}

	auto allocation = (Allocation*)hl_gc_alloc_raw(sizeof(Allocation));
	*allocation = {};
	VmaAllocationCreateInfo info = {};
	info.requiredFlags = required;
	info.preferredFlags = preferred;
	info.flags = dedicated ? VMA_ALLOCATION_CREATE_DEDICATED_MEMORY_BIT : 0;
	*result = vmaAllocateMemoryForImage(a->native, resource, &info, &allocation->native, nullptr);
	if (*result != VK_SUCCESS)
		return nullptr;

	allocation->owner = a;
	a->allocations++;

	return allocation;
}

HL_PRIM Allocation* HL_NAME(memory_allocate_transient_image)(Allocator* a, VkImage resource, int required, int preferred, int* result) {
	require_allocator(a);

	if (!resource) {
		*result = VK_ERROR_INITIALIZATION_FAILED;
		return nullptr;
	}

	VkMemoryDedicatedRequirements dedicated = {};
	dedicated.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS;

	VkMemoryRequirements2 requirements = {};
	requirements.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2;
	requirements.pNext = &dedicated;

	VkImageMemoryRequirementsInfo2 query = {};
	query.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2;
	query.image = resource;
	vkGetImageMemoryRequirements2(a->device, &query, &requirements);

	if (dedicated.requiresDedicatedAllocation) {
		*result = VK_ERROR_FEATURE_NOT_PRESENT;
		return nullptr;
	}

	auto allocation = (Allocation*)hl_gc_alloc_raw(sizeof(Allocation));
	*allocation = {};
	VmaAllocationCreateInfo info = {};
	info.requiredFlags = required;
	info.preferredFlags = preferred;
	info.flags = VMA_ALLOCATION_CREATE_CAN_ALIAS_BIT;
	*result = vmaAllocateMemoryForImage(a->native, resource, &info, &allocation->native, nullptr);
	if (*result != VK_SUCCESS)
		return nullptr;

	allocation->owner = a;
	allocation->aliasable = true;
	a->allocations++;

	return allocation;
}
HL_PRIM int HL_NAME(memory_bind_transient_image)(Allocation* a, VkImage resource) {
	require_allocation(a);

	if (!a->aliasable || !resource)
		return VK_ERROR_INITIALIZATION_FAILED;

	VkMemoryDedicatedRequirements dedicated = {};
	dedicated.sType = VK_STRUCTURE_TYPE_MEMORY_DEDICATED_REQUIREMENTS;

	VkMemoryRequirements2 requirements = {};
	requirements.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2;
	requirements.pNext = &dedicated;

	VkImageMemoryRequirementsInfo2 query = {};
	query.sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2;
	query.image = resource;
	vkGetImageMemoryRequirements2(a->owner->device, &query, &requirements);

	VmaAllocationInfo info;
	vmaGetAllocationInfo(a->owner->native, a->native, &info);

	const auto& r = requirements.memoryRequirements;

	if (dedicated.requiresDedicatedAllocation || !(r.memoryTypeBits & (1u << info.memoryType)) || r.size > info.size || info.offset % r.alignment != 0)
		return VK_ERROR_FEATURE_NOT_PRESENT;

	return vmaBindImageMemory(a->owner->native, a->native, resource);
}

HL_PRIM int HL_NAME(memory_bind_image)(Allocation* a, VkImage resource) {
	require_allocation(a);

	return vmaBindImageMemory(a->owner->native, a->native, resource);
}

HL_PRIM void HL_NAME(memory_release)(Allocation* a) {
	if (!a || !a->native)
		return;
	if (a->mappings)
		hl_error("Unmap VMA allocation before releasing it");

	vmaFreeMemory(a->owner->native, a->native);
	a->owner->allocations--;
	a->native = nullptr;
	a->owner = nullptr;
}

HL_PRIM void HL_NAME(memory_info)(Allocation* a, int* type, VkDeviceMemory* memory, int64* offset, int64* size) {
	require_allocation(a);

	VmaAllocationInfo info;
	vmaGetAllocationInfo(a->owner->native, a->native, &info);
	*type = info.memoryType;
	*memory = info.deviceMemory;
	*offset = info.offset;
	*size = info.size;
}

HL_PRIM vbyte* HL_NAME(memory_map)(Allocation* a, int* result) {
	require_allocation(a);

	void* data = nullptr;
	*result = vmaMapMemory(a->owner->native, a->native, &data);
	if (*result == VK_SUCCESS)
		a->mappings++;

	return (vbyte*)data;
}

HL_PRIM void HL_NAME(memory_unmap)(Allocation* a) {
	require_allocation(a);

	if (!a->mappings)
		hl_error("VMA allocation is not mapped");

	a->mappings--;
	vmaUnmapMemory(a->owner->native, a->native);
}

HL_PRIM int HL_NAME(memory_flush)(Allocation* a, int64 offset, int64 size) {
	require_allocation(a);

	VmaAllocationInfo info;
	vmaGetAllocationInfo(a->owner->native, a->native, &info);

	if (offset < 0 || (uint64_t)offset > info.size || (size != -1 && (size < 0 || (uint64_t)size > info.size - offset)))
		return VK_ERROR_MEMORY_MAP_FAILED;

	return vmaFlushAllocation(a->owner->native, a->native, offset, size);
}

HL_PRIM int HL_NAME(memory_invalidate)(Allocation* a, int64 offset, int64 size) {
	require_allocation(a);

	VmaAllocationInfo info;
	vmaGetAllocationInfo(a->owner->native, a->native, &info);

	if (offset < 0 || (uint64_t)offset > info.size || (size != -1 && (size < 0 || (uint64_t)size > info.size - offset)))
		return VK_ERROR_MEMORY_MAP_FAILED;

	return vmaInvalidateAllocation(a->owner->native, a->native, offset, size);
}

HL_PRIM void HL_NAME(memory_set_name)(Allocation* a, vbyte* name) {
	require_allocation(a);
	vmaSetAllocationName(a->owner->native, a->native, (const char*)name);
}

HL_PRIM void HL_NAME(memory_statistics)(Allocator* a, int* blocks, int* allocations, int64* blockBytes, int64* allocationBytes) {
	require_allocator(a);

	VmaBudget budgets[VK_MAX_MEMORY_HEAPS];
	vmaGetHeapBudgets(a->native, budgets);
	const VkPhysicalDeviceMemoryProperties* properties;
	vmaGetMemoryProperties(a->native, &properties);
	*blocks = *allocations = 0;
	*blockBytes = *allocationBytes = 0;
	for (uint32_t heap = 0; heap < properties->memoryHeapCount; heap++) {
		const auto& stats = budgets[heap].statistics;
		*blocks += stats.blockCount;
		*allocations += stats.allocationCount;
		*blockBytes += stats.blockBytes;
		*allocationBytes += stats.allocationBytes;
	}
}

HL_PRIM void HL_NAME(memory_heap_statistics)(Allocator* a, int heap, int* blocks, int* allocations, int64* blockBytes, int64* allocationBytes) {
	require_allocator(a);

	const VkPhysicalDeviceMemoryProperties* properties;
	vmaGetMemoryProperties(a->native, &properties);

	if (heap < 0 || (uint32_t)heap >= properties->memoryHeapCount)
		hl_error("Invalid VMA heap index");

	VmaBudget budgets[VK_MAX_MEMORY_HEAPS];
	vmaGetHeapBudgets(a->native, budgets);

	const VmaStatistics& statistics = budgets[heap].statistics;
	*blocks = statistics.blockCount;
	*allocations = statistics.allocationCount;
	*blockBytes = statistics.blockBytes;
	*allocationBytes = statistics.allocationBytes;
}

HL_PRIM void HL_NAME(memory_budget)(Allocator* a, int heap, int64* usage, int64* budget) {
	require_allocator(a);

	const VkPhysicalDeviceMemoryProperties* properties;
	vmaGetMemoryProperties(a->native, &properties);

	if (heap < 0 || (uint32_t)heap >= properties->memoryHeapCount)
		hl_error("Invalid VMA heap index");

	VmaBudget budgets[VK_MAX_MEMORY_HEAPS];
	vmaGetHeapBudgets(a->native, budgets);
	*usage = budgets[heap].usage;
	*budget = budgets[heap].budget;
}

extern "C" void* HL_NAME(memory_create)(void* context, int* result);
#define _MA _ABSTRACT(vma_allocator)
#define _ALLOCATION _ABSTRACT(vma_allocation)

DEFINE_PRIM(_VOID, memory_destroy, _MA);
DEFINE_PRIM(_ALLOCATION, memory_allocate_buffer, _MA _ABSTRACT(vk_buffer) _I32 _I32 _BOOL _REF(_I32));
DEFINE_PRIM(_ALLOCATION, memory_allocate_image, _MA _ABSTRACT(vk_image) _I32 _I32 _BOOL _REF(_I32));
DEFINE_PRIM(_I32, memory_bind_buffer, _ALLOCATION _ABSTRACT(vk_buffer));
DEFINE_PRIM(_I32, memory_bind_image, _ALLOCATION _ABSTRACT(vk_image));
DEFINE_PRIM(_VOID, memory_release, _ALLOCATION);
DEFINE_PRIM(_VOID, memory_info, _ALLOCATION _REF(_I32) _REF(_ABSTRACT(vk_device_memory)) _REF(_I64) _REF(_I64));
DEFINE_PRIM(_BYTES, memory_map, _ALLOCATION _REF(_I32));
DEFINE_PRIM(_VOID, memory_unmap, _ALLOCATION);
DEFINE_PRIM(_I32, memory_flush, _ALLOCATION _I64 _I64);
DEFINE_PRIM(_I32, memory_invalidate, _ALLOCATION _I64 _I64);
DEFINE_PRIM(_VOID, memory_set_name, _ALLOCATION _BYTES);
DEFINE_PRIM(_VOID, memory_statistics, _MA _REF(_I32) _REF(_I32) _REF(_I64) _REF(_I64));
DEFINE_PRIM(_VOID, memory_heap_statistics, _MA _I32 _REF(_I32) _REF(_I32) _REF(_I64) _REF(_I64));
DEFINE_PRIM(_VOID, memory_budget, _MA _I32 _REF(_I64) _REF(_I64));
DEFINE_PRIM(_MA, memory_create, _ABSTRACT(vk_context) _REF(_I32));

DEFINE_PRIM(_ALLOCATION, memory_allocate_transient_image, _MA _ABSTRACT(vk_image) _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, memory_bind_transient_image, _ALLOCATION _ABSTRACT(vk_image));
