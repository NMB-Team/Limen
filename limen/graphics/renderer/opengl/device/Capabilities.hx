package limen.graphics.renderer.opengl.device;

@:hlNative("limen", "opengl_gl_")
class Capabilities {
	@:hlNative("limen", "opengl_gl_set_debug")
	public static function setDebug(enable:Bool):Bool {
		return false;
	}

	public static function getConfigParameter(v:Int):Int {
		return 0;
	}

	public static function hasExtension(name:String):Bool {
		return false;
	}

	public static function isContextLost():Bool {
		return false;
	}

	public static function getError():Int {
		return 0;
	}

	public static inline function getString(name:Int):String {
		return @:privateAccess String.fromUTF8(getStringBytes(name));
	}

	@:hlNative("limen", "opengl_gl_get_string")
	static function getStringBytes(name:Int):hl.Bytes {
		return null;
	}

	public static inline final NO_ERROR = 0;
	public static inline final INVALID_ENUM = 0x0500;
	public static inline final INVALID_VALUE = 0x0501;
	public static inline final INVALID_OPERATION = 0x0502;
	public static inline final OUT_OF_MEMORY = 0x0505;
	public static inline final MAX_TEXTURE_SIZE = 0x0D33;
	public static inline final MAX_VIEWPORT_DIMS = 0x0D3A;
	public static inline final SUBPIXEL_BITS = 0x0D50;
	public static inline final RED_BITS = 0x0D52;
	public static inline final GREEN_BITS = 0x0D53;
	public static inline final BLUE_BITS = 0x0D54;
	public static inline final ALPHA_BITS = 0x0D55;
	public static inline final DEPTH_BITS = 0x0D56;
	public static inline final STENCIL_BITS = 0x0D57;
	public static inline final MAX_VERTEX_ATTRIBS = 0x8869;
	public static inline final MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
	public static inline final MAX_VARYING_VECTORS = 0x8DFC;
	public static inline final MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
	public static inline final MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
	public static inline final MAX_TEXTURE_IMAGE_UNITS = 0x8872;
	public static inline final MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
	public static inline final SHADING_LANGUAGE_VERSION = 0x8B8C;
	public static inline final VENDOR = 0x1F00;
	public static inline final RENDERER = 0x1F01;
	public static inline final VERSION = 0x1F02;
	public static inline final MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
	public static inline final MAX_RENDERBUFFER_SIZE = 0x84E8;
	public static inline final INVALID_FRAMEBUFFER_OPERATION = 0x0506;
	public static inline final CONTEXT_LOST_WEBGL = 0x9242;
}
