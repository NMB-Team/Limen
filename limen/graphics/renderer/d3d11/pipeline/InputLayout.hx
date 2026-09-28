package limen.graphics.renderer.d3d11.pipeline;

import limen.graphics.renderer.d3d11.DX11Core.Format;
import limen.graphics.renderer.d3d11.DX11Core.Pointer;
import limen.graphics.renderer.d3d11.resource.Resources;

abstract Layout(Pointer) {
	public inline function release() {
		Resources.releasePointer(this);
	}
}

enum abstract LayoutClassification(Int) {
	final PerVertexData = 0;
	final PerInstanceData = 1;
}

@:keep
class LayoutElement {
	public var semanticName:hl.Bytes;
	public var semanticIndex:Int;
	public var format:Format;
	public var inputSlot:Int;
	public var alignedByteOffset:Int;
	public var inputSlotClass:LayoutClassification;
	public var instanceDataStepRate:Int;

	public function new() {}
}

@:hlNative("limen", "d3d11_")
class InputLayout {
	public static function createInputLayout(elements:hl.NativeArray<LayoutElement>, shaderBytes:hl.Bytes, shaderSize:Int):Layout {
		return null;
	}
}
