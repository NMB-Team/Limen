package limen.graphics.d3d11;

import limen.graphics.d3d11.DX11Core.Pointer;
import limen.graphics.d3d11.internal.D3D11Bindings;
import limen.graphics.d3d11.internal.D3D11Bindings.DxBool;

import haxe.Int64;

#if (!gfx_dx12 || gfx_dx11)
enum abstract AddressMode(Int) {
	final Wrap = 1;
	final Mirror = 2;
	final Clamp = 3;
	final Border = 4;
	final MirrorOnce = 5;
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract Blend(Int) {
	final Zero = 1; // (;_;)
	final One = 2;
	final SrcColor = 3;
	final InvSrcColor = 4;
	final SrcAlpha = 5;
	final InvSrcAlpha = 6;
	final DestAlpha = 7;
	final InvDestAlpha = 8;
	final DestColor = 9;
	final InvDestColor = 10;
	final SrcAlphaSat = 11;
	final BlendFactor = 14;
	final InvBlendFactor = 15;
	final Src1Color = 16;
	final InvSrc1Color = 17;
	final Src1Alpha = 18;
	final InvSrc1Alpha = 19;
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract BlendOp(Int) {
	final Add = 1;
	final Subtract = 2;
	final RevSubstract = 3;
	final Min = 4;
	final Max = 5;
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract BlendState(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract ComparisonFunc(Int) {
	final Never = 1;
	final Less = 2;
	final Equal = 3;
	final LessEqual = 4;
	final Greater = 5;
	final NotEqual = 6;
	final GreaterEqual = 7;
	final Always = 8;
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract CullMode(Int) {
	public final None = 1;
	public final Front = 2;
	public final Back = 3;
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class DepthStencilDesc {
	public var depthEnable:DxBool;
	public var depthWrite:DxBool;
	public var depthFunc:ComparisonFunc;

	public var stencilEnable:DxBool;
	public var stencilReadMask:hl.UI8;
	public var stencilWriteMask:hl.UI8;

	public var frontFaceFail:StencilOp;
	public var frontFaceDepthFail:StencilOp;
	public var frontFacePass:StencilOp;
	public var frontFaceFunc:ComparisonFunc;

	public var backFaceFail:StencilOp;
	public var backFaceDepthFail:StencilOp;
	public var backFacePass:StencilOp;
	public var backFaceFunc:ComparisonFunc;

	#if hlxbo
	public var backfaceEnable:DxBool;
	public var depthBoundsEnable:DxBool;
	public var colorWritesOnDepthFailEnable:DxBool;
	public var colorWritesOnDepthPassDisable:DxBool;

	public var stencilReadMaskBack:hl.UI8;
	public var stencilWriteMaskBack:hl.UI8;

	public var stencilTestRefValueFront:hl.UI8;
	public var stencilTestRefValueBack:hl.UI8;

	public var stencilOpRefValueFront:hl.UI8;
	public var stencilOpRefValueBack:hl.UI8;
	#end

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract DepthStencilState(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract DepthStencilView(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract FillMode(Int) {
	public final WireFrame = 2;
	public final Solid = 3;
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract Filter(Int) {
	final MinMagMipPoint = 0;
	final MinMagPointMipLinear = 0x1;
	final MinPointMagLinearMipPoint = 0x4;
	final MinPointMagMipLinear = 0x5;
	final MinLinearMagMipPoint = 0x10;
	final MinLinearMagPointMipLinear = 0x11;
	final MinMagLinearMipPoint = 0x14;
	final MinMagMipLinear = 0x15;
	final Anisotropic = 0x55;
	final ComparisonMinMagMipPoint = 0x80;
	final ComparisonMinMagPointMipLinear = 0x81;
	final ComparisonMinPointMagLinearMipPoint = 0x84;
	final ComparisonMinPointMagMipLinear = 0x85;
	final ComparisonMinLinearMagMipPoint = 0x90;
	final ComparisonMinLinearMagPointMipLinear = 0x91;
	final ComparisonMinMagLinearMipPoint = 0x94;
	final ComparisonMinMagMipLinear = 0x95;
	final ComparisonAnisotropic = 0xd5;
	final MininumMinMagMipPoint = 0x100;
	final MininumMinMagPointMipLinear = 0x101;
	final MininumMinPointMagLinearMipPoint = 0x104;
	final MininumMinPointMagMipLinear = 0x105;
	final MininumMinLinearMagMipPoint = 0x110;
	final MininumMinLinearMagPointMipLinear = 0x111;
	final MininumMinMagLinearMipPoint = 0x114;
	final MininumMinMagMipLinear = 0x115;
	final MininumAnisotropic = 0x155;
	final MaximumMinMagMipPoint = 0x180;
	final MaximumMinMagPointMipLinear = 0x181;
	final MaximumMinPointMagLinearMipPoint = 0x184;
	final MaximumMinPointMagMipLinear = 0x185;
	final MaximumMinLinearMagMipPoint = 0x190;
	final MaximumMinLinearMagPointMipLinear = 0x191;
	final MaximumMinMagLinearMipPoint = 0x194;
	final MaximumMinMagMipLinear = 0x195;
	final MaximumAnisotropic = 0x1d5;
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class RasterizerDesc {
	public var fillMode:FillMode;
	public var cullMode:CullMode;
	public var frontCounterClockwise:DxBool;
	public var depthBias:Int;
	public var depthBiasClamp:hl.F32;
	public var slopeScaledDepthBias:hl.F32;
	public var depthClipEnable:DxBool;
	public var scissorEnable:DxBool;
	public var multisampleEnable:DxBool;
	public var antialiasedLineEnable:DxBool;

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract RasterState(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class RenderTargetBlendDesc {
	public var blendEnable:DxBool;
	public var srcBlend:Blend;
	public var destBlend:Blend;
	public var blendOp:BlendOp;
	public var srcBlendAlpha:Blend;
	public var destBlendAlpha:Blend;
	public var blendOpAlpha:BlendOp;
	public var renderTargetWriteMask:hl.UI8;

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class SamplerDesc {
	public var filter:Filter;
	public var addressU:AddressMode;
	public var addressV:AddressMode;
	public var addressW:AddressMode;
	public var mipLodBias:hl.F32;
	public var maxAnisotropy:Int;
	public var comparisonFunc:ComparisonFunc;
	public var borderColorR:hl.F32;
	public var borderColorG:hl.F32;
	public var borderColorB:hl.F32;
	public var borderColorA:hl.F32;
	public var minLod:hl.F32;
	public var maxLod:hl.F32;

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract SamplerState(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract StencilOp(Int) {
	final Keep = 1;
	final Zero = 2;
	final Replace = 3;
	final IncrSat = 4;
	final DecrSat = 5;
	final Invert = 6;
	final Incr = 7;
	final Decr = 8;
}
#end
