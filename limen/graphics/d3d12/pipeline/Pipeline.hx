package limen.graphics.d3d12.pipeline;

import limen.graphics.d3d12.DX12Core.Bool32;
import limen.graphics.d3d12.DX12Core.Color;
import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.DX12Core.DxgiSampleDesc;
import limen.graphics.d3d12.DX12Core.IndexBufferStripCutValue;
import limen.graphics.d3d12.DX12Core.PrimitiveTopologyType;
import limen.graphics.d3d12.descriptor.DescriptorHeap.DescriptorRange;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.d3d12.shader.ShaderCompiler.ShaderBytecode;
import limen.graphics.d3d12.shader.ShaderCompiler.ShaderVisibility;
import limen.graphics.d3d12.pipeline.InputLayout.InputElementDesc;
import limen.graphics.d3d12.pipeline.RootSignature.RootSignature;
import limen.graphics.d3d12.pipeline.StreamOutput.StreamOutputDesc;

import haxe.Int64;

@:struct class BlendDesc {
	public var alphaToCoverage:Bool32;
	public var independentBlendEnable:Bool32;
	public var renderTargets(get, never):BlendDescRenderTargets;

	@:noCompletion
	inline function get_renderTargets() {
		return new BlendDescRenderTargets(this);
	}

	@:packed
	var renderTarget0:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget1:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget2:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget3:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget4:Dx12RenderTargetBlendDesc;

	@:packed
	var renderTarget5:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget6:Dx12RenderTargetBlendDesc;
	@:packed
	var renderTarget7:Dx12RenderTargetBlendDesc;

	public function new() {}
}

abstract BlendDescRenderTargets(BlendDesc) {
	public inline function new(d) {
		this = d;
	}

	@:arrayAccess
	inline function get(index:Int) {
		return @:privateAccess switch (index) {
			case 0: this.renderTarget0;
			case 1: this.renderTarget1;
			case 2: this.renderTarget2;
			case 3: this.renderTarget3;
			case 4: this.renderTarget4;
			case 5: this.renderTarget5;

			case 6: this.renderTarget6;
			case 7: this.renderTarget7;
			default: throw "assert";
		}
	}
}

@:struct class CachedPipelineState {
	public var cachedBlob:hl.Bytes;
	public var cachedBlobSizeInBytes:hl.I64;

	public function new() {}
}

abstract ComputePipelineState(Dx12Resource) {
	@:to
	inline function toPS():PipelineState {
		return cast this;
	}
}

@:struct class ComputePipelineStateDesc {
	public var rootSignature:RootSignature;

	@:packed
	public var cs(default, null):ShaderBytecode;
	public var nodeMask:Int;

	@:packed
	public var cachedPSO(default, null):CachedPipelineState;
	public var flags:PipelineStateFlags;

	public function new() {}
}

enum abstract ConservativeRasterMode(Int) {
	final OFF = 0;
	final ON = 1;
}

@:struct class DepthStencilOpDesc {
	public var stencilFailOp:Dx12StencilOp;
	public var stencilDepthFailOp:Dx12StencilOp;
	public var stencilPassOp:Dx12StencilOp;
	public var stencilFunc:Dx12ComparisonFunc;

	public function new() {}
}

enum abstract DepthWriteMask(Int) {
	final ZERO = 0;
	final ALL = 1;
}

enum abstract Dx12AddressMode(Int) {
	final WRAP = 1;
	final MIRROR = 2;
	final CLAMP = 3;
	final BORDER = 4;
	final ONCE = 5;
}

enum abstract Dx12Blend(Int) {
	final ZERO = 1;
	final ONE = 2;
	final SRC_COLOR = 3;
	final INV_SRC_COLOR = 4;
	final SRC_ALPHA = 5;
	final INV_SRC_ALPHA = 6;
	final DEST_ALPHA = 7;
	final INV_DEST_ALPHA = 8;
	final DEST_COLOR = 9;
	final INV_DEST_COLOR = 10;
	final SRC_ALPHA_SAT = 11;
	final BLEND_FACTOR = 14;
	final INV_BLEND_FACTOR = 15;
	final SRC1_COLOR = 16;
	final INV_SRC1_COLOR = 17;
	final SRC1_ALPHA = 18;
	final INV_SRC1_ALPHA = 19;
}

enum abstract Dx12BlendOp(Int) {
	final ADD = 1;
	final SUBTRACT = 2;
	final REV_SUBTRACT = 3;
	final MIN = 4;
	final MAX = 5;
}

enum abstract Dx12ComparisonFunc(Int) {
	final NEVER = 1;
	final LESS = 2;
	final EQUAL = 3;
	final LESS_EQUAL = 4;
	final GREATER = 5;
	final NOT_EQUAL = 6;
	final GREATER_EQUAL = 7;
	final ALWAYS = 8;
}

enum abstract Dx12CullMode(Int) {
	final NONE = 1;
	final FRONT = 2;
	final BACK = 3;
}

@:struct class Dx12DepthStencilDesc {
	public var depthEnable:Bool32;
	public var depthWriteMask:DepthWriteMask;
	public var depthFunc:Dx12ComparisonFunc;
	public var stencilEnable:Bool32;
	public var stencilReadMask:hl.UI8;
	public var stencilWriteMask:hl.UI8;
	@:packed
	public var frontFace(default, null):DepthStencilOpDesc;
	@:packed
	public var backFace(default, null):DepthStencilOpDesc;

	public function new() {}
}

enum abstract Dx12FillMode(Int) {
	final WIREFRAME = 2;
	final SOLID = 3;
}

enum abstract Dx12Filter(Int) {
	final MIN_MAG_MIP_POINT = 0;
	final MIN_MAG_POINT_MIP_LINEAR = 0x1;
	final MIN_POINT_MAG_LINEAR_MIP_POINT = 0x4;
	final MIN_POINT_MAG_MIP_LINEAR = 0x5;
	final MIN_LINEAR_MAG_MIP_POINT = 0x10;
	final MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x11;
	final MIN_MAG_LINEAR_MIP_POINT = 0x14;
	final MIN_MAG_MIP_LINEAR = 0x15;
	final ANISOTROPIC = 0x55;
	final COMPARISON_MIN_MAG_MIP_POINT = 0x80;
	final COMPARISON_MIN_MAG_POINT_MIP_LINEAR = 0x81;
	final COMPARISON_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x84;
	final COMPARISON_MIN_POINT_MAG_MIP_LINEAR = 0x85;
	final COMPARISON_MIN_LINEAR_MAG_MIP_POINT = 0x90;
	final COMPARISON_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x91;
	final COMPARISON_MIN_MAG_LINEAR_MIP_POINT = 0x94;
	final COMPARISON_MIN_MAG_MIP_LINEAR = 0x95;
	final COMPARISON_ANISOTROPIC = 0xd5;
	final MINIMUM_MIN_MAG_MIP_POINT = 0x100;
	final MINIMUM_MIN_MAG_POINT_MIP_LINEAR = 0x101;
	final MINIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x104;
	final MINIMUM_MIN_POINT_MAG_MIP_LINEAR = 0x105;
	final MINIMUM_MIN_LINEAR_MAG_MIP_POINT = 0x110;
	final MINIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x111;
	final MINIMUM_MIN_MAG_LINEAR_MIP_POINT = 0x114;
	final MINIMUM_MIN_MAG_MIP_LINEAR = 0x115;
	final MINIMUM_ANISOTROPIC = 0x155;
	final MAXIMUM_MIN_MAG_MIP_POINT = 0x180;
	final MAXIMUM_MIN_MAG_POINT_MIP_LINEAR = 0x181;
	final MAXIMUM_MIN_POINT_MAG_LINEAR_MIP_POINT = 0x184;
	final MAXIMUM_MIN_POINT_MAG_MIP_LINEAR = 0x185;
	final MAXIMUM_MIN_LINEAR_MAG_MIP_POINT = 0x190;
	final MAXIMUM_MIN_LINEAR_MAG_POINT_MIP_LINEAR = 0x191;
	final MAXIMUM_MIN_MAG_LINEAR_MIP_POINT = 0x194;
	final MAXIMUM_MIN_MAG_MIP_LINEAR = 0x195;
	final MAXIMUM_ANISOTROPIC = 0x1d5;
}

@:struct class Dx12RasterizerDesc {
	public var fillMode:Dx12FillMode;
	public var cullMode:Dx12CullMode;
	public var frontCounterClockwise:Bool32;
	public var depthBias:Int;
	public var depthBiasClamp:Single;
	public var slopeScaledDepthBias:Single;
	public var depthClipEnable:Bool32;
	public var multisampleEnable:Bool32;
	public var antialiasedLineEnable:Bool32;
	public var forcedSampleCount:Int;
	public var conservativeRaster:ConservativeRasterMode;

	public function new() {}
}

@:struct class Dx12RenderTargetBlendDesc {
	public var blendEnable:Bool32;
	public var logicOpEnable:Bool32;
	public var srcBlend:Dx12Blend;
	public var dstBlend:Dx12Blend;
	public var blendOp:Dx12BlendOp;
	public var srcBlendAlpha:Dx12Blend;
	public var dstBlendAlpha:Dx12Blend;
	public var blendOpAlpha:Dx12BlendOp;
	public var logicOp:LogicOp;
	public var renderTargetWriteMask:hl.UI8;

	public function new() {}
}

@:struct class Dx12SamplerDesc {
	public var filter:Dx12Filter;
	public var addressU:Dx12AddressMode;
	public var addressV:Dx12AddressMode;
	public var addressW:Dx12AddressMode;
	public var mipLODBias:Single;
	public var maxAnisotropy:Int;
	public var comparisonFunc:Dx12ComparisonFunc;
	@:packed
	public var borderColor(default, never):Color;
	public var minLod:Single;
	public var maxLod:Single;

	public function new() {}
}

enum abstract Dx12StencilOp(Int) {
	final KEEP = 1;
	final ZERO = 2;
	final REPLACE = 3;
	final INCR_SAT = 4;
	final DECR_SAT = 5;
	final INVERT = 6;
	final INCR = 7;
	final DECR = 8;
}

abstract GraphicsPipelineState(Dx12Resource) {
	@:to
	inline function toPS():PipelineState {
		return cast this;
	}
}

@:struct class GraphicsPipelineStateDesc {
	public var rootSignature:RootSignature;
	@:packed
	public var vs(default, null):ShaderBytecode;
	@:packed
	public var ps(default, null):ShaderBytecode;
	@:packed
	public var ds(default, null):ShaderBytecode;
	@:packed
	public var hs(default, null):ShaderBytecode;
	@:packed
	public var gs(default, null):ShaderBytecode;
	@:packed
	public var streamOutput(default, null):StreamOutputDesc;
	@:packed
	public var blendState(default, null):BlendDesc;
	public var sampleMask:Int;
	@:packed
	public var rasterizerState(default, null):Dx12RasterizerDesc;
	@:packed
	public var depthStencilDesc(default, null):Dx12DepthStencilDesc;
	public var inputElementDescs:hl.CArray<InputElementDesc>;
	public var numInputElements:Int;
	public var __inputLayoutPadding:Int;
	public var ibStripCutValue:IndexBufferStripCutValue;
	public var primitiveTopologyType:PrimitiveTopologyType;
	public var numRenderTargets:Int;
	public var rtvFormats(get, never):GraphicsRTVFormats;

	inline function get_rtvFormats() {
		return new GraphicsRTVFormats(this);
	}

	var rtvFormat0:DxgiFormat;
	var rtvFormat1:DxgiFormat;
	var rtvFormat2:DxgiFormat;
	var rtvFormat3:DxgiFormat;
	var rtvFormat4:DxgiFormat;
	var rtvFormat5:DxgiFormat;
	var rtvFormat6:DxgiFormat;
	var rtvFormat7:DxgiFormat;

	public var dsvFormat:DxgiFormat;

	@:packed
	public var sampleDesc(default, null):DxgiSampleDesc;
	public var nodeMask:Int;

	@:packed
	public var cachedPSO(default, null):CachedPipelineState;
	public var flags:PipelineStateFlags;

	public function new() {}
}

abstract GraphicsRTVFormats(GraphicsPipelineStateDesc) {
	public inline function new(g) {
		this = g;
	}

	@:arrayAccess
	inline function get(index:Int) {
		return @:privateAccess switch (index) {
			case 0: this.rtvFormat0;
			case 1: this.rtvFormat1;
			case 2: this.rtvFormat2;
			case 3: this.rtvFormat3;
			case 4: this.rtvFormat4;

			case 5: this.rtvFormat5;
			case 6: this.rtvFormat6;
			case 7: this.rtvFormat7;
			default: throw "assert";
		}
	}

	@:arrayAccess
	inline function set(index:Int, v:DxgiFormat) {
		@:privateAccess switch (index) {
			case 0:
				this.rtvFormat0 = v;
			case 1:
				this.rtvFormat1 = v;
			case 2:
				this.rtvFormat2 = v;
			case 3:
				this.rtvFormat3 = v;
			case 4:
				this.rtvFormat4 = v;
			case 5:
				this.rtvFormat5 = v;
			case 6:
				this.rtvFormat6 = v;
			case 7:
				this.rtvFormat7 = v;
			default:
				throw "assert";
		}
	}
}

enum abstract LogicOp(Int) {
	final CLEAR;
	final SET;
	final COPY;
	final COPY_INVERTED;
	final NOOP;
	final INVERT;
	final AND;
	final NAND;
	final OR;
	final NOR;
	final XOR;
	final EQUIV;
	final AND_REVERSE;
	final AND_INVERTED;
	final OR_REVERSE;
	final OR_INVERTED;
}

abstract PipelineState(Dx12Resource) {}

enum abstract PipelineStateFlags(Int) {
	final NONE = 0;
	final TOOL_DEBUG = 1;
}
