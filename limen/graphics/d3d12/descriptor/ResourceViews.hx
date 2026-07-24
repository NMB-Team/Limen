package limen.graphics.d3d12.descriptor;

import limen.graphics.d3d12.DX12Core.Address;
import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;

import haxe.Int64;

@:struct class BufferSRV extends Dx12ShaderResourceViewDesc {
	public var firstElement:Int64;
	public var numElements:Int;
	public var structureByteStride:Int;
	public var flags:BufferSRVFlags;

	var unused:Int;

	public function new() {
		dimension = BUFFER;
	}
}

enum abstract BufferSRVFlags(Int) {
	final NONE = 0;
	final RAW = 1;
}

@:struct class ConstantBufferViewDesc {
	public var bufferLocation:Address;
	public var sizeInBytes:Int;

	public function new() {}
}

@:struct class DepthStencilViewDesc {
	public var format:DxgiFormat;
	public var viewDimension:DsvDimension;
	public var flags:haxe.EnumFlags<DsvFlags>;
	public var mipSlice:Int;
	public var firstArraySlice:Int;
	public var arraySize:Int;

	public function new() {}
}

enum abstract DsvDimension(Int) {
	final UNKNOWN = 0;
	final TEXTURE1D = 1;
	final TEXTURE1DARRAY = 2;
	final TEXTURE2D = 3;
	final TEXTURE2DARRAY = 4;
	final TEXTURE2DMS = 5;
	final TEXTURE2DMSARRAY = 6;
}

enum DsvFlags {
	READ_ONLY_DEPTH;
	READ_ONLY_STENCIL;
}

@:struct class Dx12ShaderResourceViewDesc {
	public var format:DxgiFormat;
	public var dimension:SrvDimension;
	public var shader4ComponentMapping:ShaderComponentMapping;

	var __unionPadding:Int;
}

@:struct class RenderTargetViewDesc {
	public var format:DxgiFormat;
	public var viewDimension:RtvDimension;

	var int0:Int;
	var int1:Int;
	var int2:Int;
	var int3:Int;

	public var mipSlice(get, set):Int;
	public var firstElement(get, set):Int;
	public var numElements(get, set):Int;
	public var firstArraySlice(get, set):Int;
	public var arraySize(get, set):Int;
	public var planeSlice(get, set):Int;

	@:noCompletion
	inline function get_firstElement() {
		return int0;
	}

	@:noCompletion
	inline function set_firstElement(v) {
		return int0 = v;
	}

	@:noCompletion
	inline function get_numElements() {
		return int1;
	}

	@:noCompletion
	inline function set_numElements(v) {
		return int1 = v;
	}

	@:noCompletion
	inline function get_mipSlice() {
		return int0;
	}

	@:noCompletion
	inline function set_mipSlice(v) {
		return int0 = v;
	}

	@:noCompletion
	inline function get_firstArraySlice() {
		return switch (viewDimension) {
			case TEXTURE2DMSARRAY: int0;
			default: int1;
		};
	}

	@:noCompletion
	inline function set_firstArraySlice(v) {
		return switch (viewDimension) {
			case TEXTURE2DMSARRAY: int0 = v;
			default: int1 = v;
		};
	}

	@:noCompletion
	inline function get_arraySize() {
		return switch (viewDimension) {
			case TEXTURE2DMSARRAY: int1;
			default: int2;
		};
	}

	@:noCompletion
	inline function set_arraySize(v) {
		return switch (viewDimension) {
			case TEXTURE2DMSARRAY: int1 = v;
			default: int2 = v;
		};
	}

	@:noCompletion
	inline function get_planeSlice() {
		return switch (viewDimension) {
			case TEXTURE2D: int1;
			default: int3;
		};
	}

	@:noCompletion
	inline function set_planeSlice(v) {
		return switch (viewDimension) {
			case TEXTURE2D: int1 = v;
			default: int3 = v;
		};
	}

	private function new() {}
}

enum abstract RtvDimension(Int) {
	final UNKNOWN = 0;
	final BUFFER = 1;
	final TEXTURE1D = 2;
	final TEXTURE1DARRAY = 3;
	final TEXTURE2D = 4;
	final TEXTURE2DARRAY = 5;
	final TEXTURE2DMS = 6;
	final TEXTURE2DMSARRAY = 7;
	final TEXTURE3D = 8;
}

abstract ShaderComponentMapping(Int) {
	public var red(get, set):ShaderComponentValue;
	public var green(get, set):ShaderComponentValue;
	public var blue(get, set):ShaderComponentValue;
	public var alpha(get, set):ShaderComponentValue;

	public function new() {
		this = 1 << 12;
	}

	@:noCompletion
	inline function get_red():ShaderComponentValue {
		return cast(this & 7);
	}

	@:noCompletion
	inline function get_green():ShaderComponentValue {
		return cast((this >> 3) & 7);
	}

	@:noCompletion
	inline function get_blue():ShaderComponentValue {
		return cast((this >> 6) & 7);
	}

	@:noCompletion
	inline function get_alpha():ShaderComponentValue {
		return cast((this >> 9) & 7);
	}

	@:noCompletion
	inline function set_red(v:ShaderComponentValue) {
		this = (this & ~(3 << 0)) | ((cast v : Int) << 0);
		return v;
	}

	@:noCompletion
	inline function set_green(v:ShaderComponentValue) {
		this = (this & ~(3 << 3)) | ((cast v : Int) << 3);
		return v;
	}

	@:noCompletion
	inline function set_blue(v:ShaderComponentValue) {
		this = (this & ~(3 << 6)) | ((cast v : Int) << 6);
		return v;
	}

	@:noCompletion
	inline function set_alpha(v:ShaderComponentValue) {
		this = (this & ~(3 << 9)) | ((cast v : Int) << 9);
		return v;
	}

	public static inline var DEFAULT:ShaderComponentMapping = cast 0x1688;
}

enum abstract ShaderComponentValue(Int) {
	final R = 0;
	final G = 1;
	final B = 2;
	final A = 3;
	final ZERO = 4;
	final ONE = 5;
}

enum abstract SrvDimension(Int) {
	final UNKNOWN = 0;
	final BUFFER = 1;
	final TEXTURE1D = 2;
	final TEXTURE1DARRAY = 3;
	final TEXTURE2D = 4;
	final TEXTURE2DARRAY = 5;
	final TEXTURE2DMS = 6;
	final TEXTURE2DMSARRAY = 7;
	final TEXTURE3D = 8;
	final TEXTURECUBE = 9;
	final TEXTURECUBEARRAY = 10;
	final RAYTRACING_ACCELERATION_STRUCTURE = 11;
}

@:struct class Tex1DArraySRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var firstArraySlice:Int;
	public var arraySize:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;

	public function new() {
		dimension = TEXTURE1DARRAY;
	}
}

@:struct class Tex1DSRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;
	var unused2:Int;
	var unused3:Int;

	public function new() {
		dimension = TEXTURE1D;
	}
}

@:struct class Tex2DArraySRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var firstArraySlice:Int;
	public var arraySize:Int;
	public var planeSlice:Int;
	public var resourceMinLODClamp:Single;

	public function new() {
		dimension = TEXTURE2DARRAY;
	}
}

@:struct class Tex2DSRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var planeSlice:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;
	var unused2:Int;

	public function new() {
		dimension = TEXTURE2D;
	}
}

@:struct class Tex3DSRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;
	var unused2:Int;
	var unused3:Int;

	public function new() {
		dimension = TEXTURE3D;
	}
}

@:struct class TexCubeArraySRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var first2DArrayFace:Int;
	public var numCubes:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;

	public function new() {
		dimension = TEXTURECUBEARRAY;
	}
}

@:struct class TexCubeSRV extends Dx12ShaderResourceViewDesc {
	public var mostDetailedMip:Int;
	public var mipLevels:Int;
	public var resourceMinLODClamp:Single;

	var unused1:Int;
	var unused2:Int;
	var unused3:Int;

	public function new() {
		dimension = TEXTURECUBE;
	}
}

enum UAVBufferFlags {
	RAW;
}

@:struct class UAVBufferViewDesc extends UnorderedAccessViewDesc {
	public var firstElement:hl.I64;
	public var numElements:Int;
	public var structureSizeInBytes:Int;
	public var counterOffsetInBytes:hl.I64;
	public var flags:haxe.EnumFlags<UAVBufferFlags>;

	public function new() {
		viewDimension = BUFFER;
	}
}

enum abstract UAVDimension(Int) {
	public final UNKNOWN = 0;
	public final BUFFER = 1;
	public final TEXTURE1D = 2;
	public final TEXTURE1DARRAY = 3;
	public final TEXTURE2D = 4;
	public final TEXTURE2DARRAY = 5;
	public final TEXTURE3D = 8;
}

@:struct class UAVTextureViewDesc extends UnorderedAccessViewDesc {
	var int0:Int;
	var int1:Int;
	var int2:Int;
	var int3:Int;
	var padding1:hl.I64;
	var padding2:Int;

	public function new(dim) {
		viewDimension = dim;
	}

	public var mipSlice(get, set):Int;
	public var firstArraySlice(get, set):Int;
	public var firstWSlice(get, set):Int;
	public var arraySize(get, set):Int;
	public var planeSlice(get, set):Int;
	public var wSlice(get, set):Int;

	@:noCompletion
	inline function get_mipSlice() {
		return int0;
	}

	@:noCompletion
	inline function set_mipSlice(v) {
		return int0 = v;
	}

	@:noCompletion
	inline function get_planeSlice() {
		return switch (viewDimension) {
			case TEXTURE2DARRAY: int3;
			default: int1;
		}
	}

	@:noCompletion
	inline function set_planeSlice(v) {
		return switch (viewDimension) {
			case TEXTURE2DARRAY: int3 = v;
			default: int1 = v;
		}
	}

	@:noCompletion
	inline function get_firstArraySlice() {
		return int1;
	}

	@:noCompletion
	inline function set_firstArraySlice(v) {
		return int1 = v;
	}

	@:noCompletion
	inline function get_arraySize() {
		return int2;
	}

	@:noCompletion
	inline function set_arraySize(v) {
		return int2 = v;
	}

	@:noCompletion
	inline function get_firstWSlice() {
		return int1;
	}

	@:noCompletion
	inline function set_firstWSlice(v) {
		return int1 = v;
	}

	@:noCompletion
	inline function get_wSlice() {
		return int2;
	}

	@:noCompletion
	inline function set_wSlice(v) {
		return int2 = v;
	}
}

@:struct class UnorderedAccessViewDesc {
	public var format:DxgiFormat;
	public var viewDimension:UAVDimension;
}
