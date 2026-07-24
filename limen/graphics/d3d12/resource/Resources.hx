package limen.graphics.d3d12.resource;

import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.DX12Core.DxgiSampleDesc;
import limen.graphics.d3d12.DX12Core.Range;

import haxe.Int64;

enum abstract CpuPageProperty(Int) {
	final UNKNOWN = 0;
	final NOT_AVAILABLE = 1;
	final WRITE_COMBINE = 2;
	final WRITE_BACK = 3;
}

@:hlNative("limen_d3d12", "resource_")
abstract Dx12Resource(hl.Abstract<"dx_resource">) {
	public function release() {}

	public inline function setName(name:String) {
		set_name(@:privateAccess name.bytes);
	}

	@:noCompletion
	private function set_name(name:hl.Bytes) {}
}

enum abstract Dx12ResourceDimension(Int) {
	final UNKNOWN = 0;
	final BUFFER = 1;
	final TEXTURE1D = 2;
	final TEXTURE2D = 3;
	final TEXTURE3D = 4;
}

@:hlNative("limen_d3d12", "resource_") @:forward(release, setName)
abstract GpuResource(Dx12Resource) {
	@:hlNative("limen_d3d12", "resource_get_gpu_virtual_address")
	public function getGpuVirtualAddress():Int64 {
		return 0;
	}

	@:hlNative("limen_d3d12", "get_required_intermediate_size")
	public function getRequiredIntermediateSize(subRes:Int, resCount:Int):Int64 {
		return 0;
	}

	public function map(subResource:Int, range:Range):hl.Bytes {
		return null;
	}

	public function unmap(subResource:Int, writtenRange:Range) {}

	@:to
	inline function to():Dx12Resource {
		return cast this;
	}
}

enum HeapFlag {
	SHARED;
	__UNUSED;
	DENY_BUFFERS;
	ALLOW_DISPLAY;
	__UNUSED2;
	SHARED_CROSS_ADAPTER;
	DENY_RT_DS_TEXTURES;
	DENY_NON_RT_DS_TEXTURES;
	HARDWARE_PROTECTED;
	ALLOW_WRITE_WATCH;
	ALLOW_SHADER_ATOMICS;
	CREATE_NOT_RESIDENT;
	CREATE_NOT_ZEROED;
}

@:struct class HeapProperties {
	public var type:HeapType;
	public var cpuPageProperty:CpuPageProperty;
	public var memoryPoolReference:MemoryPool;
	public var creationNodeMask:Int;
	public var visibleNodeMask:Int;

	public function new() {}
}

enum abstract HeapType(Int) {
	final DEFAULT = 1;
	final UPLOAD = 2;
	final READBACK = 3;
	final CUSTOM = 4;
}

enum abstract MemoryPool(Int) {
	final UNKNOWN = 0;
	final L0 = 1;
	final L1 = 2;
}

@:struct class PlacedSubresourceFootprint {
	public var offset:Int64;
	@:packed public var footprint(default, null):SubresourceFootprint;

	public function new() {}
}

@:struct class ResourceBarrier {
	var type:ResourceBarrierType;

	public var flags:ResourceBarrierFlags;
	public var resource:Dx12Resource;
	public var subResource:Int;
	public var stateBefore:ResourceState;
	public var stateAfter:ResourceState;

	public function new() {
		type = TRANSITION;
	}
}

enum abstract ResourceBarrierFlags(Int) {
	final NONE = 0;
	final BEGIN_ONLY = 1;
	final END_ONLY = 2;
}

enum abstract ResourceBarrierType(Int) {
	final TRANSITION = 0;
	final ALIASING = 1;
	final UAV = 2;
}

@:struct class ResourceDesc {
	public var dimension:Dx12ResourceDimension;
	public var alignment:Int64;
	public var width:Int64;
	public var height:Int;
	public var depthOrArraySize:hl.UI16;
	public var mipLevels:hl.UI16;
	public var format:DxgiFormat;
	@:packed
	public var sampleDesc(default, null):DxgiSampleDesc;
	public var layout:TextureLayout;
	public var flags:haxe.EnumFlags<ResourceFlag>;

	public function new() {}
}

enum ResourceFlag {
	ALLOW_RENDER_TARGET;
	ALLOW_DEPTH_STENCIL;
	ALLOW_UNORDERED_ACCESS;
	DENY_SHADER_RESOURCE;
	ALLOW_CROSS_ADAPTER;
	ALLOW_SIMULTANEOUS_ACCESS;
	VIDEO_DECODE_REFERENCE_ONLY;
	VIDEO_ENCODE_REFERENCE_ONLY;
}

enum abstract ResourceState(Int) {
	public final COMMON = 0;
	public final VERTEX_AND_CONSTANT_BUFFER = 0x1;
	public final INDEX_BUFFER = 0x2;
	public final RENDER_TARGET = 0x4;
	public final UNORDERED_ACCESS = 0x8;
	public final DEPTH_WRITE = 0x10;
	public final DEPTH_READ = 0x20;
	public final NON_PIXEL_SHADER_RESOURCE = 0x40;
	public final PIXEL_SHADER_RESOURCE = 0x80;
	public final STREAM_OUT = 0x100;
	public final INDIRECT_ARGUMENT = 0x200;
	public final COPY_DEST = 0x400;
	public final COPY_SOURCE = 0x800;
	public final RESOLVE_DESC = 0x1000;
	public final RESOLVE_SOURCE = 0x2000;
	public final RAYTRACING_ACCELERATION_STRUCTURE = 0x400000;
	public final SHADING_RATE_SOURCE = 0x1000000;
	public final GENERIC_READ = 0x1 | 0x2 | 0x40 | 0x80 | 0x200 | 0x800;
	public final ALL_SHADER_RESOURCE = 0x40 | 0x80;
	public final PRESENT = #if (console && !xbogdk) 0x100000 #else 0 #end;
	public final PREDICATION = 0x200;
	public final VIDE_DECODE_READ = 0x10000;
	public final VIDE_DECODE_WRITE = 0x20000;
	public final VIDE_PROCESS_READ = 0x40000;
	public final VIDE_PROCESS_WRITE = 0x80000;
	public final VIDE_ENCODE_READ = 0x200000;
	public final VIDE_ENCODE_WRITE = 0x800000;

	@:op(a | b) function or(r:ResourceState):ResourceState;

	@:op(a & b) function and(r:ResourceState):ResourceState;
}

@:struct class SubResourceData {
	public var data:hl.Bytes;
	public var rowPitch:Int64;
	public var slicePitch:Int64;

	public function new() {}
}

@:struct class SubresourceFootprint {
	public var format:DxgiFormat;
	public var width:Int;
	public var height:Int;
	public var depth:Int;
	public var rowPitch:Int;

	public function new() {}
}

@:struct class TextureCopyLocation {
	public var res:GpuResource;
	public var type:TextureCopyType;

	var __unionPadding:Int;

	public var subResourceIndex(get, set):Int;

	@:noCompletion
	inline function get_subResourceIndex():Int {
		return placedFootprint.offset.low & 0xFF;
	}

	@:noCompletion
	inline function set_subResourceIndex(v:Int) {
		placedFootprint.offset = v;
		return v;
	}

	@:packed
	public var placedFootprint(default, null):PlacedSubresourceFootprint;

	public function new() {}
}

enum abstract TextureCopyType(Int) {
	final SUBRESOURCE_INDEX = 0;
	final PLACED_FOOTPRINT = 1;
}

enum abstract TextureLayout(Int) {
	final UNKNOWN = 0;
	final ROW_MAJOR = 1;
	final _64KB_UNDEFINED_SWIZZLE = 2;
	final _64KB_STANDARD_SWIZZLE = 3;
}
