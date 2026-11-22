package limen.graphics.renderer.vulkan.memory;

import haxe.Int64;
import limen.graphics.renderer.vulkan.internal.VulkanBindings.VkContext;
import limen.graphics.renderer.vulkan.memory.Memory;

typedef AllocatorHandle = hl.Abstract<"vma_allocator">;
typedef AllocationHandle = hl.Abstract<"vma_allocation">;

@:noCompletion
@:hlNative("limen", "vulkan_memory_")
class VmaMemoryAllocator {
	public static function create(context:VkContext, result:hl.Ref<Int>):AllocatorHandle { return null; }
	public static function destroy(allocator:AllocatorHandle):Void {}
	public static function allocate_buffer(allocator:AllocatorHandle, buffer:VkBuffer, required:Int, preferred:Int, dedicated:Bool, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function allocate_image(allocator:AllocatorHandle, image:VkImage, required:Int, preferred:Int, dedicated:Bool, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function allocate_transient_image(allocator:AllocatorHandle, image:VkImage, required:Int, preferred:Int, result:hl.Ref<Int>):AllocationHandle { return null; }
	public static function bind_transient_image(allocation:AllocationHandle, image:VkImage):Int { return 0; }
	public static function bind_buffer(allocation:AllocationHandle, buffer:VkBuffer):Int { return 0; }
	public static function bind_image(allocation:AllocationHandle, image:VkImage):Int { return 0; }
	public static function release(allocation:AllocationHandle):Void {}
	public static function info(allocation:AllocationHandle, memoryType:hl.Ref<Int>, memory:hl.Ref<VkDeviceMemory>, offset:hl.Ref<Int64>, size:hl.Ref<Int64>):Void {}
	public static function map(allocation:AllocationHandle, result:hl.Ref<Int>):hl.Bytes { return null; }
	public static function unmap(allocation:AllocationHandle):Void {}
	public static function flush(allocation:AllocationHandle, offset:Int64, size:Int64):Int { return 0; }
	public static function invalidate(allocation:AllocationHandle, offset:Int64, size:Int64):Int { return 0; }
	public static inline function setName(allocation:AllocationHandle, name:String):Void {
		set_name(allocation, name == null ? null : @:privateAccess name.toUtf8());
	}
	private static function set_name(allocation:AllocationHandle, name:hl.Bytes):Void {}
	public static function statistics(allocator:AllocatorHandle, blocks:hl.Ref<Int>, allocations:hl.Ref<Int>, blockBytes:hl.Ref<Int64>, allocationBytes:hl.Ref<Int64>):Void {}
	@:native("heap_statistics")
	public static function heapStatistics(allocator:AllocatorHandle, heap:Int, blocks:hl.Ref<Int>, allocations:hl.Ref<Int>, blockBytes:hl.Ref<Int64>, allocationBytes:hl.Ref<Int64>):Void {}
	public static function budget(allocator:AllocatorHandle, heap:Int, usage:hl.Ref<Int64>, budget:hl.Ref<Int64>):Void {}
}
