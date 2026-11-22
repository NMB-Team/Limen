#include <hl.h>
#undef _GUID
#include <d3d12.h>
#include <dxgi1_4.h>
#include <cstdio>
#include <wrl/client.h>
#include <d3d12sdklayers.h>
#include <cstdlib>

struct MemoryAllocator;
struct MemoryAllocation;

extern "C" {
MemoryAllocator* limen_d3d12_memory_create(ID3D12Device*, IDXGIAdapter*, int*);
void limen_d3d12_memory_destroy(MemoryAllocator*);
MemoryAllocation* limen_d3d12_memory_allocate(MemoryAllocator*, int, D3D12_RESOURCE_DESC*, int, D3D12_CLEAR_VALUE*, int*);
MemoryAllocation* limen_d3d12_memory_allocate_transient(MemoryAllocator*, D3D12_RESOURCE_DESC*, int, D3D12_CLEAR_VALUE*, int*);
MemoryAllocation* limen_d3d12_memory_alias(MemoryAllocation*, D3D12_RESOURCE_DESC*, int, D3D12_CLEAR_VALUE*, int*);
ID3D12Resource* limen_d3d12_memory_resource(MemoryAllocation*);
void limen_d3d12_memory_release(MemoryAllocation*);
void limen_d3d12_memory_statistics(MemoryAllocator*, int, int*, int*, int64*, int64*);
}

void limen_d3d12ma_dispose_device(ID3D12Device*);

static bool check_aliasing(ID3D12Device* device, MemoryAllocator* allocator) {
	using Microsoft::WRL::ComPtr;

	struct Owners {
		MemoryAllocation* first = nullptr;
		MemoryAllocation* second = nullptr;

		~Owners() {
			limen_d3d12_memory_release(first);
			limen_d3d12_memory_release(second);
		}
	} owners;

	D3D12_RESOURCE_DESC desc = {};
	desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
	desc.Width = desc.Height = 64;
	desc.DepthOrArraySize = desc.MipLevels = desc.SampleDesc.Count = 1;
	desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;

	int result;

	owners.first = limen_d3d12_memory_allocate_transient(allocator, &desc, D3D12_RESOURCE_STATE_RENDER_TARGET, nullptr, &result);
	if (!owners.first || FAILED(result))
		return false;

	owners.second = limen_d3d12_memory_alias(owners.first, &desc, D3D12_RESOURCE_STATE_RENDER_TARGET, nullptr, &result);
	if (!owners.second || FAILED(result))
		return false;

	int blocks, allocations;
	int64 blockBytes, bytes;

	limen_d3d12_memory_statistics(allocator, 0, &blocks, &allocations, &blockBytes, &bytes);
	if (allocations != 1)
		return false;

	const auto info = device->GetResourceAllocationInfo(0, 1, &desc);
	std::printf("Transient pair: backing=%lld bytes, baseline=%llu bytes, saved=%llu bytes\n", bytes, 2 * info.SizeInBytes, 2 * info.SizeInBytes - bytes);

	ComPtr<ID3D12CommandQueue> queue;
	ComPtr<ID3D12CommandAllocator> commands;
	ComPtr<ID3D12GraphicsCommandList> list;
	ComPtr<ID3D12Fence> fence;
	ComPtr<ID3D12DescriptorHeap> views;
	ComPtr<ID3D12Resource> readback;

	D3D12_COMMAND_QUEUE_DESC queueDesc = {};

	D3D12_DESCRIPTOR_HEAP_DESC viewDesc = {};
	viewDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
	viewDesc.NumDescriptors = 2;

	if (FAILED(device->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&queue))) || FAILED(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT, IID_PPV_ARGS(&commands))) ||
	    FAILED(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT, commands.Get(), nullptr, IID_PPV_ARGS(&list))) || FAILED(device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence))) ||
	    FAILED(device->CreateDescriptorHeap(&viewDesc, IID_PPV_ARGS(&views))))
		return false;

	D3D12_PLACED_SUBRESOURCE_FOOTPRINT footprint;
	UINT64 total;
	device->GetCopyableFootprints(&desc, 0, 1, 0, &footprint, nullptr, nullptr, &total);

	D3D12_RESOURCE_DESC buffer = {};
	buffer.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	buffer.Width = total * 2;
	buffer.Height = buffer.DepthOrArraySize = buffer.MipLevels = buffer.SampleDesc.Count = 1;
	buffer.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;

	D3D12_HEAP_PROPERTIES heap = {};
	heap.Type = D3D12_HEAP_TYPE_READBACK;

	if (FAILED(device->CreateCommittedResource(&heap, D3D12_HEAP_FLAG_NONE, &buffer, D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&readback))))
		return false;

	auto view = views->GetCPUDescriptorHandleForHeapStart();
	ID3D12Resource* previous = nullptr;

	for (int i = 0; i < 2; ++i) {
		auto resource = limen_d3d12_memory_resource(i ? owners.second : owners.first);
		D3D12_RESOURCE_BARRIER barrier = {};
		barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_ALIASING;
		barrier.Aliasing.pResourceBefore = previous;
		barrier.Aliasing.pResourceAfter = resource;
		list->ResourceBarrier(1, &barrier);

		device->CreateRenderTargetView(resource, nullptr, view);
		const float color[4] = { i ? 0.f : 1.f, i ? 1.f : 0.f, 0.f, 1.f };
		list->ClearRenderTargetView(view, color, 0, nullptr);

		barrier = {};
		barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
		barrier.Transition.pResource = resource;
		barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
		barrier.Transition.StateBefore = D3D12_RESOURCE_STATE_RENDER_TARGET;
		barrier.Transition.StateAfter = D3D12_RESOURCE_STATE_COPY_SOURCE;
		list->ResourceBarrier(1, &barrier);

		D3D12_TEXTURE_COPY_LOCATION src = {}, dst = {};
		src.pResource = resource;
		src.Type = D3D12_TEXTURE_COPY_TYPE_SUBRESOURCE_INDEX;
		dst.pResource = readback.Get();
		dst.Type = D3D12_TEXTURE_COPY_TYPE_PLACED_FOOTPRINT;
		dst.PlacedFootprint = footprint;
		dst.PlacedFootprint.Offset = i * total;
		list->CopyTextureRegion(&dst, 0, 0, 0, &src, nullptr);

		previous = resource;
		view.ptr += device->GetDescriptorHandleIncrementSize(D3D12_DESCRIPTOR_HEAP_TYPE_RTV);
	}

	if (FAILED(list->Close()))
		return false;

	ID3D12CommandList* submitted[] = { list.Get() };
	queue->ExecuteCommandLists(1, submitted);

	if (FAILED(queue->Signal(fence.Get(), 1)))
		std::abort();

	HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
	if (!event)
		std::abort();

	const auto waitResult = fence->SetEventOnCompletion(1, event);
	const auto waited = SUCCEEDED(waitResult) ? WaitForSingleObject(event, 30000) : WAIT_FAILED;
	CloseHandle(event);

	if (waited != WAIT_OBJECT_0)
		std::abort();

	unsigned char* mapped;
	if (FAILED(readback->Map(0, nullptr, (void**)&mapped)))
		return false;

	bool matches = true;

	for (int i = 0; i < 2; ++i)
		for (UINT y = 0; y < 64; ++y)
			for (UINT x = 0; x < 64; ++x) {
				const auto p = mapped + i * total + y * footprint.Footprint.RowPitch + x * 4;
				matches &= p[0] == (i ? 0 : 255) && p[1] == (i ? 255 : 0) && p[2] == 0 && p[3] == 255;
			}

	D3D12_RANGE written = {};
	readback->Unmap(0, &written);

	// Releasing the original first must not invalidate the second owner.
	limen_d3d12_memory_release(owners.first);
	owners.first = nullptr;
	matches &= limen_d3d12_memory_resource(owners.second) != nullptr;

	return matches;
}

int main() {
	hl_global_init();
	int stackTop;
	hl_register_thread(&stackTop);

	IDXGIFactory4* factory = nullptr;
	IDXGIAdapter* adapter = nullptr;
	ID3D12Device* device = nullptr;
	MemoryAllocator* allocator = nullptr;
	MemoryAllocation* allocation = nullptr;
	int result = 0;
	int blocks = 0, count = 0;
	int64 blockBytes = 0, allocationBytes = 0;
	int status = 1;

	D3D12_RESOURCE_DESC desc = {};
	desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
	desc.Width = 65536;
	desc.Height = 1;
	desc.DepthOrArraySize = 1;
	desc.MipLevels = 1;
	desc.SampleDesc.Count = 1;
	desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
	{
		Microsoft::WRL::ComPtr<ID3D12Debug> debug;
		if (FAILED(D3D12GetDebugInterface(IID_PPV_ARGS(&debug)))) {
			std::printf("D3D12 debug layer unavailable\n");
			goto cleanup;
		}
		debug->EnableDebugLayer();
	}

	if (FAILED(CreateDXGIFactory1(IID_PPV_ARGS(&factory))) || FAILED(factory->EnumWarpAdapter(IID_PPV_ARGS(&adapter))) || FAILED(D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_11_0, IID_PPV_ARGS(&device))))
		goto cleanup;

	allocator = limen_d3d12_memory_create(device, adapter, &result);
	if (!allocator || FAILED(result))
		goto cleanup;

	allocation = limen_d3d12_memory_allocate(allocator, D3D12_HEAP_TYPE_UPLOAD, &desc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, &result);
	if (!allocation || FAILED(result))
		goto cleanup;
	{
		auto resource = limen_d3d12_memory_resource(allocation);
		void* mapped = nullptr;
		if (FAILED(resource->Map(0, nullptr, &mapped)))
			goto cleanup;
		*(unsigned char*)mapped = 42;
		resource->Unmap(0, nullptr);
	}

	limen_d3d12_memory_statistics(allocator, 0, &blocks, &count, &blockBytes, &allocationBytes);
	if (count != 1 || allocationBytes < desc.Width)
		goto cleanup;

	limen_d3d12_memory_release(allocation);
	limen_d3d12_memory_release(allocation);

	limen_d3d12_memory_statistics(allocator, 0, &blocks, &count, &blockBytes, &allocationBytes);
	if (count != 0 || allocationBytes != 0)
		goto cleanup;

	if (!check_aliasing(device, allocator))
		goto cleanup;
	{
		Microsoft::WRL::ComPtr<ID3D12InfoQueue> info;
		if (FAILED(device->QueryInterface(IID_PPV_ARGS(&info))))
			goto cleanup;
		for (UINT64 i = 0; i < info->GetNumStoredMessages(); ++i) {
			SIZE_T size = 0;
			info->GetMessage(i, nullptr, &size);
			auto message = (D3D12_MESSAGE*)std::malloc(size);
			const auto hr = info->GetMessage(i, message, &size);
			const bool error = FAILED(hr) || message->Severity <= D3D12_MESSAGE_SEVERITY_ERROR;
			if (SUCCEEDED(hr) && error)
				std::printf("%s\n", message->pDescription);
			std::free(message);
			if (error)
				goto cleanup;
		}
	}

	limen_d3d12ma_dispose_device(device);
	status = 0;

cleanup:

	limen_d3d12_memory_release(allocation);
	limen_d3d12_memory_destroy(allocator);
	if (device && device->Release() != 0)
		status = 1;
	if (adapter && adapter->Release() != 0)
		status = 1;
	if (factory && factory->Release() != 0)
		status = 1;

	hl_unregister_thread();
	hl_global_free();
	std::printf("D3D12MA allocation and COM lifetime smoke test: %s\n", status ? "FAIL" : "PASS");

	return status;
}
