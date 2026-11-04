#define HL_NAME(n) limen_d3d12_##n
#include <hl.h>
#undef _GUID
#include <D3D12MemAlloc.h>
#include "memory_allocator.h"

struct MemoryAllocator {
	D3D12MA::Allocator* native;
	ID3D12Device* device;
	int allocations;
	MemoryAllocator* next;
};

struct MemoryAllocation {
	D3D12MA::Allocation* native;
	MemoryAllocator* owner;
	ID3D12Resource* alias;
	bool aliasable;
	D3D12_RESOURCE_DESC description;
};

static MemoryAllocator* allocators;
static bool rooted;

static void require_allocator(MemoryAllocator* allocator) {
	if (!allocator || !allocator->native)
		hl_error("D3D12MA allocator is closed");
}

static void require_allocation(MemoryAllocation* allocation) {
	if (!allocation || !allocation->native)
		hl_error("D3D12MA allocation is closed");
}

HL_PRIM MemoryAllocator* HL_NAME(memory_create)(ID3D12Device* device, IDXGIAdapter* adapter, int* result) {
	*result = E_INVALIDARG;
	if (!device || !adapter)
		return nullptr;
	if (!rooted) {
		hl_add_root(&allocators);
		rooted = true;
	}
	auto handle = (MemoryAllocator*)hl_gc_alloc_raw(sizeof(MemoryAllocator));
	*handle = {};
	D3D12MA::ALLOCATOR_DESC desc = {};
	desc.pDevice = device;
	desc.pAdapter = adapter;
	*result = D3D12MA::CreateAllocator(&desc, &handle->native);
	if (FAILED(*result))
		return nullptr;
	handle->device = device;
	handle->next = allocators;
	allocators = handle;
	return handle;
}

HL_PRIM void HL_NAME(memory_destroy)(MemoryAllocator* allocator) {
	if (!allocator || !allocator->native)
		return;
	if (allocator->allocations)
		hl_error("Release D3D12MA allocations before destroying their allocator");
	auto link = &allocators;
	while (*link != allocator)
		link = &(*link)->next;
	*link = allocator->next;
	allocator->native->Release();
	allocator->native = nullptr;
	allocator->device = nullptr;
	allocator->next = nullptr;
}

void limen_d3d12ma_dispose_device(ID3D12Device* device) {
	for (auto a = allocators; a; a = a->next)
		if (a->device == device && a->allocations)
			hl_error("Release D3D12MA allocations before disposing or replacing the device");
	for (auto a = allocators; a;) {
		auto next = a->next;
		if (a->device == device)
			HL_NAME(memory_destroy)(a);
		a = next;
	}
}

HL_PRIM MemoryAllocation* HL_NAME(memory_allocate)(MemoryAllocator* allocator, int heapType, D3D12_RESOURCE_DESC* desc, int state, D3D12_CLEAR_VALUE* clear, int* result) {
	require_allocator(allocator);
	*result = E_INVALIDARG;
	if (!desc || heapType < D3D12_HEAP_TYPE_DEFAULT || heapType > D3D12_HEAP_TYPE_READBACK)
		return nullptr;
	auto handle = (MemoryAllocation*)hl_gc_alloc_raw(sizeof(MemoryAllocation));
	*handle = {};
	D3D12MA::ALLOCATION_DESC allocationDesc = {};
	allocationDesc.HeapType = (D3D12_HEAP_TYPE)heapType;
	*result = allocator->native->CreateResource(&allocationDesc, desc, (D3D12_RESOURCE_STATES)state, clear, &handle->native, IID_NULL, nullptr);
	if (FAILED(*result))
		return nullptr;
	handle->owner = allocator;
	++allocator->allocations;
	return handle;
}

HL_PRIM ID3D12Resource* HL_NAME(memory_resource)(MemoryAllocation* allocation) {
	require_allocation(allocation);
	return allocation->alias ? allocation->alias : allocation->native->GetResource();
}

HL_PRIM void HL_NAME(memory_release)(MemoryAllocation* allocation) {
	if (!allocation || !allocation->native)
		return;
	if (allocation->alias) {
		allocation->alias->Release();
		allocation->alias = nullptr;
	}
	allocation->native->Release();
	allocation->native = nullptr;
	--allocation->owner->allocations;
	allocation->owner = nullptr;
}

HL_PRIM void HL_NAME(memory_set_name)(MemoryAllocation* allocation, uchar* name) {
	require_allocation(allocation);
	allocation->native->SetName((LPCWSTR)name);
	HL_NAME(memory_resource)(allocation)->SetName(name ? (LPCWSTR)name : L"");
}

HL_PRIM MemoryAllocation* HL_NAME(memory_allocate_transient)(MemoryAllocator* allocator, D3D12_RESOURCE_DESC* desc, int state, D3D12_CLEAR_VALUE* clear, int* result) {
	require_allocator(allocator);
	*result = E_INVALIDARG;
	if (!desc || desc->Dimension != D3D12_RESOURCE_DIMENSION_TEXTURE2D ||
		desc->Flags != D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET || desc->SampleDesc.Count != 1 ||
		desc->SampleDesc.Quality != 0 || desc->DepthOrArraySize != 1 || desc->MipLevels != 1 ||
		desc->Layout != D3D12_TEXTURE_LAYOUT_UNKNOWN || desc->Alignment != 0)
		return nullptr;

	auto handle = (MemoryAllocation*)hl_gc_alloc_raw(sizeof(MemoryAllocation));
	*handle = {};
	D3D12MA::ALLOCATION_DESC allocationDesc = {};
	allocationDesc.HeapType = D3D12_HEAP_TYPE_DEFAULT;
	allocationDesc.Flags = D3D12MA::ALLOCATION_FLAG_CAN_ALIAS;
	*result = allocator->native->CreateResource(&allocationDesc, desc, (D3D12_RESOURCE_STATES)state, clear, &handle->native, IID_NULL, nullptr);
	if (FAILED(*result))
		return nullptr;
	handle->owner = allocator;
	handle->aliasable = true;
	handle->description = *desc;
	++allocator->allocations;
	return handle;
}

HL_PRIM MemoryAllocation* HL_NAME(memory_alias)(MemoryAllocation* source, D3D12_RESOURCE_DESC* desc, int state, D3D12_CLEAR_VALUE* clear, int* result) {
	require_allocation(source);
	*result = E_INVALIDARG;
	if (!source->aliasable || !desc)
		return nullptr;
	const auto& original = source->description;
	if (desc->Dimension != original.Dimension || desc->Alignment != original.Alignment ||
		desc->Width != original.Width || desc->Height != original.Height ||
		desc->DepthOrArraySize != original.DepthOrArraySize || desc->MipLevels != original.MipLevels ||
		desc->Format != original.Format || desc->SampleDesc.Count != original.SampleDesc.Count ||
		desc->SampleDesc.Quality != original.SampleDesc.Quality || desc->Layout != original.Layout || desc->Flags != original.Flags)
		return nullptr;

	auto handle = (MemoryAllocation*)hl_gc_alloc_raw(sizeof(MemoryAllocation));
	*handle = {};
	*result = source->owner->native->CreateAliasingResource(source->native, 0, desc,
		(D3D12_RESOURCE_STATES)state, clear, IID_PPV_ARGS(&handle->alias));
	if (FAILED(*result))
		return nullptr;

	// each resource owner retains the backing allocation independently
	source->native->AddRef();
	handle->native = source->native;
	handle->owner = source->owner;
	handle->aliasable = true;
	handle->description = *desc;
	++handle->owner->allocations;
	return handle;
}

HL_PRIM int64 HL_NAME(memory_size)(MemoryAllocation* allocation) {
	require_allocation(allocation);
	return allocation->native->GetSize();
}

HL_PRIM void HL_NAME(memory_statistics)(MemoryAllocator* allocator, int heapType, int* blocks, int* allocations, int64* blockBytes, int64* allocationBytes) {
	require_allocator(allocator);
	if (heapType < 0 || heapType > 3)
		hl_error("D3D12MA statistics heap type must be 0 (total), 1, 2, or 3");
	D3D12MA::TotalStatistics stats;
	allocator->native->CalculateStatistics(&stats);
	const auto& s = heapType ? stats.HeapType[heapType - 1].Stats : stats.Total.Stats;
	*blocks = s.BlockCount;
	*allocations = s.AllocationCount;
	*blockBytes = s.BlockBytes;
	*allocationBytes = s.AllocationBytes;
}

#define _MA _ABSTRACT(dx_memory_allocator)
#define _ALLOCATION _ABSTRACT(dx_memory_allocation)
DEFINE_PRIM(_MA, memory_create, _ABSTRACT(dx_device) _ABSTRACT(dx_adapter) _REF(_I32));
DEFINE_PRIM(_VOID, memory_destroy, _MA);
DEFINE_PRIM(_ALLOCATION, memory_allocate, _MA _I32 _STRUCT _I32 _STRUCT _REF(_I32));
DEFINE_PRIM(_ALLOCATION, memory_allocate_transient, _MA _STRUCT _I32 _STRUCT _REF(_I32));
DEFINE_PRIM(_ALLOCATION, memory_alias, _ALLOCATION _STRUCT _I32 _STRUCT _REF(_I32));
DEFINE_PRIM(_ABSTRACT(dx_resource), memory_resource, _ALLOCATION);
DEFINE_PRIM(_VOID, memory_release, _ALLOCATION);
DEFINE_PRIM(_VOID, memory_set_name, _ALLOCATION _BYTES);
DEFINE_PRIM(_I64, memory_size, _ALLOCATION);
DEFINE_PRIM(_VOID, memory_statistics, _MA _I32 _REF(_I32) _REF(_I32) _REF(_I64) _REF(_I64));
