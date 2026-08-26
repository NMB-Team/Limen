package limen.graphics.d3d11;

import haxe.Int64;

enum abstract Format(Int) {
	final UNKNOWN = 0;
	final R32G32B32A32_TYPELESS = 1;
	final R32G32B32A32_FLOAT = 2;
	final R32G32B32A32_UINT = 3;
	final R32G32B32A32_SINT = 4;
	final R32G32B32_TYPELESS = 5;
	final R32G32B32_FLOAT = 6;
	final R32G32B32_UINT = 7;
	final R32G32B32_SINT = 8;
	final R16G16B16A16_TYPELESS = 9;
	final R16G16B16A16_FLOAT = 10;
	final R16G16B16A16_UNORM = 11;
	final R16G16B16A16_UINT = 12;
	final R16G16B16A16_SNORM = 13;
	final R16G16B16A16_SINT = 14;
	final R32G32_TYPELESS = 15;
	final R32G32_FLOAT = 16;
	final R32G32_UINT = 17;
	final R32G32_SINT = 18;
	final R32G8X24_TYPELESS = 19;
	final D32_FLOAT_S8X24_UINT = 20;
	final R32_FLOAT_X8X24_TYPELESS = 21;
	final X32_TYPELESS_G8X24_UINT = 22;
	final R10G10B10A2_TYPELESS = 23;
	final R10G10B10A2_UNORM = 24;
	final R10G10B10A2_UINT = 25;
	final R11G11B10_FLOAT = 26;
	final R8G8B8A8_TYPELESS = 27;
	final R8G8B8A8_UNORM = 28;
	final R8G8B8A8_UNORM_SRGB = 29;
	final R8G8B8A8_UINT = 30;
	final R8G8B8A8_SNORM = 31;
	final R8G8B8A8_SINT = 32;
	final R16G16_TYPELESS = 33;
	final R16G16_FLOAT = 34;
	final R16G16_UNORM = 35;
	final R16G16_UINT = 36;
	final R16G16_SNORM = 37;
	final R16G16_SINT = 38;
	final R32_TYPELESS = 39;
	final D32_FLOAT = 40;
	final R32_FLOAT = 41;
	final R32_UINT = 42;
	final R32_SINT = 43;
	final R24G8_TYPELESS = 44;
	final D24_UNORM_S8_UINT = 45;
	final R24_UNORM_X8_TYPELESS = 46;
	final X24_TYPELESS_G8_UINT = 47;
	final R8G8_TYPELESS = 48;
	final R8G8_UNORM = 49;
	final R8G8_UINT = 50;
	final R8G8_SNORM = 51;
	final R8G8_SINT = 52;
	final R16_TYPELESS = 53;
	final R16_FLOAT = 54;
	final D16_UNORM = 55;
	final R16_UNORM = 56;
	final R16_UINT = 57;
	final R16_SNORM = 58;
	final R16_SINT = 59;
	final R8_TYPELESS = 60;
	final R8_UNORM = 61;
	final R8_UINT = 62;
	final R8_SNORM = 63;
	final R8_SINT = 64;
	final A8_UNORM = 65;
	final R1_UNORM = 66;
	final R9G9B9E5_SHAREDEXP = 67;
	final R8G8_B8G8_UNORM = 68;
	final G8R8_G8B8_UNORM = 69;
	final BC1_TYPELESS = 70;
	final BC1_UNORM = 71;
	final BC1_UNORM_SRGB = 72;
	final BC2_TYPELESS = 73;
	final BC2_UNORM = 74;
	final BC2_UNORM_SRGB = 75;
	final BC3_TYPELESS = 76;
	final BC3_UNORM = 77;
	final BC3_UNORM_SRGB = 78;
	final BC4_TYPELESS = 79;
	final BC4_UNORM = 80;
	final BC4_SNORM = 81;
	final BC5_TYPELESS = 82;
	final BC5_UNORM = 83;
	final BC5_SNORM = 84;
	final B5G6R5_UNORM = 85;
	final B5G5R5A1_UNORM = 86;
	final B8G8R8A8_UNORM = 87;
	final B8G8R8X8_UNORM = 88;
	final R10G10B10_XR_BIAS_A2_UNORM = 89;
	final B8G8R8A8_TYPELESS = 90;
	final B8G8R8A8_UNORM_SRGB = 91;
	final B8G8R8X8_TYPELESS = 92;
	final B8G8R8X8_UNORM_SRGB = 93;
	final BC6H_TYPELESS = 94;
	final BC6H_UF16 = 95;
	final BC6H_SF16 = 96;
	final BC7_TYPELESS = 97;
	final BC7_UNORM = 98;
	final BC7_UNORM_SRGB = 99;
	final AYUV = 100;
	final Y410 = 101;
	final Y416 = 102;
	final NV12 = 103;
	final P010 = 104;
	final P016 = 105;
	final _420_OPAQUE = 106;
	final YUY2 = 107;
	final Y210 = 108;
	final Y216 = 109;
	final NV11 = 110;
	final AI44 = 111;
	final IA44 = 112;
	final P8 = 113;
	final A8P8 = 114;
	final B4G4R4A4_UNORM = 115;
	final P208 = 130;
	final V208 = 131;
	final V408 = 132;
}

#if (!gfx_dx12 || gfx_dx11)
typedef Pointer = hl.Abstract<"dx_pointer">;
#end

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

#if (!gfx_dx12 || gfx_dx11)
enum abstract ResourceAccess(Int) {
	final None = 0;
	final CpuWrite = 0x10000;
	final CpuRead = 0x20000;

	@:op(a | b)
	static function or(a:ResourceAccess, b:ResourceAccess):ResourceAccess;
}
#end

#if (!gfx_dx12 || gfx_dx11)
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
#end

#if (!gfx_dx12 || gfx_dx11)
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
#end

#if (!gfx_dx12 || gfx_dx11)
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
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract ResourceUsage(Int) {
	final Default = 0;
	final Immutable = 1;
	final Dynamic = 2;
	final Staging = 3;
}
#end
