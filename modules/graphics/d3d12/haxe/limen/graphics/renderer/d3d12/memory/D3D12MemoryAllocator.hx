package limen.graphics.renderer.d3d12.memory;

import haxe.Int64;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Device;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Adapter;
import limen.graphics.renderer.d3d12.DX12Core.ClearValue;
import limen.graphics.renderer.d3d12.resource.Resources;

typedef AllocatorHandle = hl.Abstract<"dx_memory_allocator">;
typedef AllocationHandle = hl.Abstract<"dx_memory_allocation">;

@:noCompletion
@:hlNative("limen", "d3d12_memory_")
class D3D12MemoryAllocator {
	public static function create(device:Device, adapter:Adapter, result:hl.Ref<Int>):AllocatorHandle { return null; }
	public static function destroy(allocator:AllocatorHandle):Void {}
	public static function allocate(allocator:AllocatorHandle, heapType:HeapType, desc:ResourceDesc, state:ResourceState,
		clear:ClearValue, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function resource(allocation:AllocationHandle):GpuResource { return null; }
	/** Release these owners only after all queues using their resources have completed. */
	public static function allocate_transient(allocator:AllocatorHandle, desc:ResourceDesc, state:ResourceState,
		clear:ClearValue, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function alias(source:AllocationHandle, desc:ResourceDesc, state:ResourceState,
		clear:ClearValue, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function release(allocation:AllocationHandle):Void {}
	public static function size(allocation:AllocationHandle):Int64 { return 0; }
	public static inline function setName(allocation:AllocationHandle, name:String):Void {
		set_name(allocation, name == null ? null : @:privateAccess name.bytes);
	}
	private static function set_name(allocation:AllocationHandle, name:hl.Bytes):Void {}
	public static function statistics(allocator:AllocatorHandle, heapType:Int, blocks:hl.Ref<Int>, allocations:hl.Ref<Int>,
		blockBytes:hl.Ref<Int64>, allocationBytes:hl.Ref<Int64>):Void {}
}
