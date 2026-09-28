package limen.graphics.renderer.d3d11.descriptor;

import limen.graphics.renderer.d3d11.DX11Core.Format;
import limen.graphics.renderer.d3d11.DX11Core.Pointer;
import limen.graphics.renderer.d3d11.resource.Resources;
import limen.graphics.renderer.d3d11.resource.Resources.Resource;

enum abstract ResourceDimension(Int) {
	final Unknown = 0;
	final Buffer = 1;
	final Texture1D = 2;
	final Texture1DArray = 3;
	final Texture2D = 4;
	final Texture2DArray = 5;
	final Texture2DMS = 6;
	final Texture2DMSArray = 7;
	final Texture3D = 8;
	final TextureCube = 9;
	final TextureCubeArray = 10;
	final TextureBufferEx = 11;
}

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

abstract RenderTargetView(Pointer) {
	public inline function release() {
		Resources.releasePointer(this);
	}
}

abstract ShaderResourceView(Pointer) {
	public inline function release() {
		Resources.releasePointer(this);
	}
}

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

abstract DepthStencilView(Pointer) {
	public inline function release() {
		Resources.releasePointer(this);
	}
}

@:hlNative("limen", "d3d11_")
class ResourceViews {
	public static function createRenderTargetView(r:Resource, ?desc:RenderTargetDesc):RenderTargetView {
		return dxCreateRenderTargetView(r, desc);
	}

	@:hlNative("limen", "d3d11_create_render_target_view")
	static function dxCreateRenderTargetView(r:Resource, desc:Dynamic):RenderTargetView {
		return null;
	}

	public static function createShaderResourceView(res:Resource, desc:ShaderResourceViewDesc):ShaderResourceView {
		return dxCreateShaderResourceView(res, desc);
	}

	@:hlNative("limen", "d3d11_create_shader_resource_view")
	static function dxCreateShaderResourceView(res:Resource, desc:Dynamic):ShaderResourceView {
		return null;
	}

	public static function createDepthStencilView(texture:Resource, format:Format, readOnly:Bool):DepthStencilView {
		return null;
	}
}
