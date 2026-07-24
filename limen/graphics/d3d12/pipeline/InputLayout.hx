package limen.graphics.d3d12.pipeline;

import limen.graphics.d3d12.DX12Core.DxgiFormat;

enum abstract InputClassification(Int) {
	final PER_VERTEX_DATA = 0;
	final PER_INSTANCE_DATA = 1;
}

@:struct class InputElementDesc {
	public var semanticName:hl.Bytes;
	public var semanticIndex:Int;
	public var format:DxgiFormat;
	public var inputSlot:Int;
	public var alignedByteOffset:Int;
	public var inputSlotClass:InputClassification;
	public var instanceDataStepRate:Int;

	public function new() {}
}

@:struct class InputLayoutDesc {
	public var inputElementDescs:hl.CArray<InputElementDesc>;
	public var numElements:Int;
	public var __padding:Int; // largest element

	public function new() {}
}
