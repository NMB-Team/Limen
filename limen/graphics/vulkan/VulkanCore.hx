package limen.graphics.vulkan;

import haxe.Int64;

abstract ArrayStruct<T>(hl.Bytes) {}

abstract IntArray<T>(hl.Bytes) {
	public function new(arr:Array<T>) {
		this = new hl.Bytes(arr.length << 2);
		for (i in 0...arr.length)
			this.setI32(i << 2, cast arr[i]);
	}
}

abstract NextPtr(hl.Bytes) {}
abstract UnusedFlags(Int) {}

abstract VkBool32(Int) {
	@:to function toBool()
		return this != 0 ? true : false;

	@:from static function fromBool(b:Bool):VkBool32 {
		return cast(b ? 1 : 0);
	}
}

@:struct class VkDeviceSize {
	public var low:Int;
	public var high:Int;

	public function new(v = 0) {
		low = v;
	}
}

enum abstract VkStructureType(Int) {
	final APPLICATION_INFO = 0;
	final INSTANCE_CREATE_INFO = 1;
	final DEVICE_QUEUE_CREATE_INFO = 2;
	final DEVICE_CREATE_INFO = 3;
	final SUBMIT_INFO = 4;
	final MEMORY_ALLOCATE_INFO = 5;
	final MAPPED_MEMORY_RANGE = 6;
	final BIND_SPARSE_INFO = 7;
	final FENCE_CREATE_INFO = 8;
	final SEMAPHORE_CREATE_INFO = 9;
	final EVENT_CREATE_INFO = 10;
	final QUERY_POOL_CREATE_INFO = 11;
	final BUFFER_CREATE_INFO = 12;
	final BUFFER_VIEW_CREATE_INFO = 13;
	final IMAGE_CREATE_INFO = 14;
	final IMAGE_VIEW_CREATE_INFO = 15;
	final SHADER_MODULE_CREATE_INFO = 16;
	final PIPELINE_CACHE_CREATE_INFO = 17;
	final PIPELINE_SHADER_STAGE_CREATE_INFO = 18;
	final PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO = 19;
	final PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO = 20;
	final PIPELINE_TESSELLATION_STATE_CREATE_INFO = 21;
	final PIPELINE_VIEWPORT_STATE_CREATE_INFO = 22;
	final PIPELINE_RASTERIZATION_STATE_CREATE_INFO = 23;
	final PIPELINE_MULTISAMPLE_STATE_CREATE_INFO = 24;
	final PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO = 25;
	final PIPELINE_COLOR_BLEND_STATE_CREATE_INFO = 26;
	final PIPELINE_DYNAMIC_STATE_CREATE_INFO = 27;
	final GRAPHICS_PIPELINE_CREATE_INFO = 28;
	final COMPUTE_PIPELINE_CREATE_INFO = 29;
	final PIPELINE_LAYOUT_CREATE_INFO = 30;
	final SAMPLER_CREATE_INFO = 31;
	final DESCRIPTOR_SET_LAYOUT_CREATE_INFO = 32;
	final DESCRIPTOR_POOL_CREATE_INFO = 33;
	final DESCRIPTOR_SET_ALLOCATE_INFO = 34;
	final WRITE_DESCRIPTOR_SET = 35;
	final COPY_DESCRIPTOR_SET = 36;
	final FRAMEBUFFER_CREATE_INFO = 37;
	final RENDER_PASS_CREATE_INFO = 38;
	final COMMAND_POOL_CREATE_INFO = 39;
	final COMMAND_BUFFER_ALLOCATE_INFO = 40;
	final COMMAND_BUFFER_INHERITANCE_INFO = 41;
	final COMMAND_BUFFER_BEGIN_INFO = 42;
	final RENDER_PASS_BEGIN_INFO = 43;
	final BUFFER_MEMORY_BARRIER = 44;
	final IMAGE_MEMORY_BARRIER = 45;
	final MEMORY_BARRIER = 46;
	final LOADER_INSTANCE_CREATE_INFO = 47;
	final LOADER_DEVICE_CREATE_INFO = 48;
}
