package limen.graphics.d3d11;

import limen.graphics.d3d11.DX11Core.Format;
import limen.graphics.d3d11.DX11Core.Pointer;
import limen.graphics.d3d11.DX11Core.ResourceAccess;
import limen.graphics.d3d11.DX11Core.ResourceBind;
import limen.graphics.d3d11.DX11Core.ResourceDimension;
import limen.graphics.d3d11.DX11Core.ResourceMisc;
import limen.graphics.d3d11.DX11Core.ResourceUsage;
import limen.graphics.d3d11.internal.D3D11Bindings;

import haxe.Int64;

#if (!gfx_dx12 || gfx_dx11)
@:keep
class RenderTargetDesc {
	public var format:Format;
	public var dimension:ResourceDimension;
	public var mipMap:Int;
	public var firstSlice:Int;
	public var sliceCount:Int;

	// for buffer
	public var firstElement(get, set):Int;
	public var elementCount(get, set):Int;

	public function new(format, dimension = Unknown) {
		this.format = format;
		this.dimension = dimension;
	}

	@:noCompletion
	inline function get_firstElement() {
		return mipMap;
	}

	@:noCompletion
	inline function set_firstElement(m) {
		return mipMap = m;
	}

	@:noCompletion
	inline function get_elementCount() {
		return firstSlice;
	}

	@:noCompletion
	inline function set_elementCount(m) {
		return firstSlice = m;
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract RenderTargetView(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract ShaderResourceView(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class ShaderResourceViewDesc {
	public var format:Format;
	public var dimension:ResourceDimension;
	public var start:Int;
	public var count:Int;
	public var firstArraySlice:Int;
	public var arraySize:Int;

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class Texture2dDesc {
	public var width:Int;
	public var height:Int;
	public var mipLevels:Int;
	public var arraySize:Int;
	public var format:Format;
	public var sampleCount:Int;
	public var sampleQuality:Int;
	public var usage:ResourceUsage;
	public var bind:ResourceBind;
	public var access:ResourceAccess;
	public var misc:ResourceMisc;

	#if hlxbo
	var esramOffset:Int;
	var esramUsage:Int;
	#end

	public function new() {
		mipLevels = arraySize = sampleCount = 1;
	}
}
#end
