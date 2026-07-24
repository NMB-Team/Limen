package limen.graphics.d3d12.pipeline;

import limen.graphics.d3d12.shader.ShaderCompiler.ShaderVisibility;
import limen.graphics.d3d12.pipeline.Pipeline.Dx12AddressMode;
import limen.graphics.d3d12.pipeline.Pipeline.Dx12ComparisonFunc;
import limen.graphics.d3d12.pipeline.Pipeline.Dx12Filter;

@:struct class SoDeclarationEntry {
	public var stream:Int;
	public var semanticName:hl.Bytes;
	public var semanticIndex:Int;
	public var startComponent:hl.UI8;
	public var componentCount:hl.UI8;
	public var outputSlot:hl.UI8;

	public function new() {}
}

enum abstract StaticBorderColor(Int) {
	final TRANSPARENT_BLACK = 0;
	final OPAQUE_BLACK = 1;
	final OPAQUE_WHITE = 2;
}

@:struct class StaticSamplerDesc {
	public var filter:Dx12Filter;
	public var addressU:Dx12AddressMode;
	public var addressV:Dx12AddressMode;
	public var addressW:Dx12AddressMode;
	public var mipLODBias:Single;
	public var maxAnisotropy:Int;
	public var comparisonFunc:Dx12ComparisonFunc;
	public var borderColor:StaticBorderColor;
	public var minLOD:Single;
	public var maxLOD:Single;
	public var shaderRegister:Int;
	public var registerSpace:Int;
	public var shaderVisibility:ShaderVisibility;

	public function new() {}
}

@:struct class StreamOutputDesc {
	public var soDeclaration:hl.CArray<SoDeclarationEntry>;
	public var numEntries:Int;
	public var bufferStrides:hl.Bytes;
	public var numStrides:Int;
	public var rasterizedStream:Int;
}
