package limen.graphics.renderer.d3d11.shader;

import limen.graphics.renderer.d3d11.DX11Core.Pointer;
import limen.graphics.renderer.d3d11.resource.Resources;

abstract Shader(Pointer) {
	public inline function release() {
		Resources.releasePointer(this);
	}
}

@:hlNative("limen", "d3d11_")
class Shaders {
	public static function createVertexShader(bytes:haxe.io.Bytes):Shader {
		return dxCreateVertexShader(bytes, bytes.length);
	}

	@:hlNative("limen", "d3d11_create_vertex_shader")
	static function dxCreateVertexShader(data:hl.Bytes, size:Int):Shader {
		return null;
	}

	public static function createPixelShader(bytes:haxe.io.Bytes):Shader {
		return dxCreatePixelShader(bytes, bytes.length);
	}

	@:hlNative("limen", "d3d11_create_pixel_shader")
	static function dxCreatePixelShader(data:hl.Bytes, size:Int):Shader {
		return null;
	}
}
