package limen.graphics.d3d12.descriptor;

import limen.graphics.d3d12.DX12Core.Address;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;

@:hlNative("?limen_d3d12", "descriptor_heap_")
abstract DescriptorHeap(Dx12Resource) to Dx12Resource {
	public function new(desc) {
		this = create(desc);
	}

	@:hlNative("?limen_d3d12", "descriptor_heap_get_handle")
	public function getHandle(gpu:Bool):Address {
		return cast null;
	}

	static function create(desc:DescriptorHeapDesc):Dx12Resource {
		return null;
	}
}

@:struct class DescriptorHeapDesc {
	public var type:DescriptorHeapType;
	public var numDescriptors:Int;
	public var flags:DescriptorHeapFlags;
	public var nodeMask:Int;

	public function new() {}
}

enum abstract DescriptorHeapFlags(Int) {
	final NONE = 0;
	final SHADER_VISIBLE = 1;
}

enum abstract DescriptorHeapType(Int) {
	final CBV_SRV_UAV = 0;
	final SAMPLER = 1;
	final RTV = 2;
	final DSV = 3;
}

@:struct class DescriptorRange {
	public var rangeType:DescriptorRangeType;
	public var numDescriptors:Int;
	public var baseShaderRegister:Int;
	public var registerSpace:Int;
	public var offsetInDescriptorsFromTableStart:Int;

	public function new() {}
}

enum abstract DescriptorRangeType(Int) {
	final SRV = 0;
	final UAV = 1;
	final CBV = 2;
	final SAMPLER = 3;
}
