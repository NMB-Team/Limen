package limen.graphics.renderer.d3d11.resource;

import limen.graphics.renderer.d3d11.DX11Core.Format;
import limen.graphics.renderer.d3d11.DX11Core.Pointer;

enum abstract MapType(Int) {
	final Read = 1;
	final Write = 2;
	final ReadWrite = 3;
	final WriteDiscard = 4;
	final WriteNoOverwrite = 5;
}

class ResourceBox {
	public var left:Int;
	public var top:Int;
	public var front:Int;
	public var right:Int;
	public var bottom:Int;
	public var back:Int;

	public function new() {}

	public function reset() {
		left = top = front = right = bottom = back = 0;
	}
}

abstract Resource(hl.Abstract<"dx_resource">) {
	@:hlNative("limen", "d3d11_map")
	public function map(subResource:Int, type:MapType, waitGpu:Bool, pitch:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public inline function updateSubresource(subResource:Int, box:Null<ResourceBox>, data:hl.Bytes, srcRowPitch:Int, srcDepthPitch:Int):Void {
		dxUpdateSubresource(subResource, box, data, srcRowPitch, srcDepthPitch);
	}

	public inline function copySubresourceRegion(subResource:Int, dstX:Int, dstY:Int, dstZ:Int, src:Resource, srcSubResource:Int, srcBox:Null<ResourceBox>):Void {
		dxCopySubresourceRegion(subResource, dstX, dstY, dstZ, src, srcSubResource, srcBox);
	}

	@:hlNative("limen", "d3d11_copy_resource")
	public function copyResource(from:Resource) {}

	@:hlNative("limen", "d3d11_update_subresource")
	private function dxUpdateSubresource(subResource:Int, box:Dynamic, data:hl.Bytes, srcRowPitch:Int, srcDepthPitch:Int):Void {}

	@:hlNative("limen", "d3d11_copy_subresource_region")
	private function dxCopySubresourceRegion(subResource:Int, dstX:Int, dstY:Int, dstZ:Int, src:Resource, srcSubResource:Int, srcBox:Dynamic):Void {}

	@:hlNative("limen", "d3d11_unmap")
	public function unmap(subResource:Int):Void {}

	@:hlNative("limen", "d3d11_release_resource")
	public function release() {}
}

enum abstract ResourceAccess(Int) {
	final None = 0;
	final CpuWrite = 0x10000;
	final CpuRead = 0x20000;

	@:op(a | b)
	static function or(a:ResourceAccess, b:ResourceAccess):ResourceAccess;
}

enum abstract ResourceBind(Int) {
	final None = 0;
	final VertexBuffer = 1;
	final IndexBuffer = 2;
	final ConstantBuffer = 4;
	final ShaderResource = 8;
	final StreamOuput = 16;
	final RenderTarget = 32;
	final DepthStencil = 64;
	final UnorderedAccess = 128;
	final Decoder = 512;
	final VideoDecoder = 1024;

	@:op(a | b)
	static function or(a:ResourceBind, b:ResourceBind):ResourceBind;
}

enum abstract ResourceMisc(Int) {
	final None = 0;
	final GenerateMips = 1;
	final Shared = 2;
	final TextureCube = 4;
	final DrawIndirectArgs = 0x10;
	final BufferAllowRawView = 0x20;
	final BufferStructured = 0x40;
	final ResourceClamp = 0x80;
	final SharedKeyedMutex = 0x100;
	final GdiCompatible = 0x200;
	final SharedNTHandle = 0x800;
	final RestrictedContent = 0x1000;
	final RestrictSharedResource = 0x2000;
	final RestrictSharedResourceDriver = 0x4000;
	final Guarded = 0x8000;
	final TilePool = 0x20000;
	final Tiled = 0x40000;
	final HWProtected = 0x80000;

	@:op(a | b) static function or(a:ResourceMisc, b:ResourceMisc):ResourceMisc;
}

enum abstract ResourceUsage(Int) {
	final Default = 0;
	final Immutable = 1;
	final Dynamic = 2;
	final Staging = 3;
}

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

@:hlNative("limen", "d3d11_")
class Resources {
	public static function releasePointer(p:Pointer) {}

	public static function createBuffer(size:Int, usage:ResourceUsage, bind:ResourceBind, access:ResourceAccess, misc:ResourceMisc, stride:Int, data:hl.Bytes):Resource {
		return null;
	}

	public static function createTexture2d(desc:Texture2dDesc, ?data:hl.Bytes):Resource {
		return dxCreateTexture2d(desc, data);
	}

	@:hlNative("limen", "d3d11_create_texture_2d")
	static function dxCreateTexture2d(desc:Dynamic, data:hl.Bytes):Resource {
		return null;
	}
}
