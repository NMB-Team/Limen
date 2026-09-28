package limen.graphics.renderer.opengl.resource;

abstract Texture(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class Textures {
	public static function createTexture():Texture {
		return null;
	}

	public static function activeTexture(t:Int) {}

	public static function bindTexture(t:Int, texture:Texture) {}

	@:hlNative("limen", "opengl_gl_bind_image_texture")
	public static function bindImageTexture(unit:Int, texture:Int, level:Int, layered:Bool, layer:Int, access:Int, format:Int) {}

	public static function texParameteri(t:Int, key:Int, value:Int) {}

	public static function texParameterf(t:Int, key:Int, value:hl.F32) {}

	@:hlNative("limen", "opengl_gl_tex_image2d")
	public static function texImage2D(target:Int, level:Int, internalFormat:Int, width:Int, height:Int, border:Int, format:Int, type:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_tex_image3d")
	public static function texImage3D(target:Int, level:Int, internalFormat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_tex_image2d_multisample")
	public static function texImage2DMultisample(target:Int, samples:Int, internalFormat:Int, width:Int, height:Int, fixedsamplelocations:Bool) {}

	@:hlNative("limen", "opengl_gl_compressed_tex_image2d")
	public static function compressedTexImage2D(target:Int, level:Int, internalFormat:Int, width:Int, height:Int, border:Int, imageSize:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_compressed_tex_image3d")
	public static function compressedTexImage3D(target:Int, level:Int, internalFormat:Int, width:Int, height:Int, depth:Int, border:Int, imageSize:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_tex_sub_image2d")
	public static function texSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_tex_sub_image3d")
	public static function texSubImage3D(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_compressed_tex_sub_image2d")
	public static function compressedTexSubImage2D(target:Int, level:Int, xoffset:Int, yoffset:Int, width:Int, height:Int, format:Int, type:Int, image:hl.Bytes) {}

	@:hlNative("limen", "opengl_gl_compressed_tex_sub_image3d")
	public static function compressedTexSubImage3D(target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, image:hl.Bytes) {}

	/** Requires OpenGL 4.2+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_tex_storage2d")
	public static function texStorage2D(target:Int, levels:Int, internalFormat:Int, width:Int, height:Int) {}

	/** Requires OpenGL 4.2+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_tex_storage3d")
	public static function texStorage3D(target:Int, levels:Int, internalFormat:Int, width:Int, height:Int, depth:Int) {}

	public static function generateMipmap(t:Int) {}

	public static function deleteTexture(t:Texture) {}

	public static function pixelStorei(key:Int, value:Int) {}

	public static inline final UNPACK_ALIGNMENT = 0x0CF5;
	public static inline final PACK_ALIGNMENT = 0x0D05;
	public static inline final TEXTURE_BINDING_2D = 0x8069;
	public static inline final COMPRESSED_TEXTURE_FORMATS = 0x86A3;
	public static inline final DONT_CARE = 0x1100;
	public static inline final FASTEST = 0x1101;
	public static inline final NICEST = 0x1102;
	public static inline final GENERATE_MIPMAP_HINT = 0x8192;
	public static inline final NEAREST = 0x2600;
	public static inline final LINEAR = 0x2601;
	public static inline final NEAREST_MIPMAP_NEAREST = 0x2700;
	public static inline final LINEAR_MIPMAP_NEAREST = 0x2701;
	public static inline final NEAREST_MIPMAP_LINEAR = 0x2702;
	public static inline final LINEAR_MIPMAP_LINEAR = 0x2703;
	public static inline final TEXTURE_MAG_FILTER = 0x2800;
	public static inline final TEXTURE_MIN_FILTER = 0x2801;
	public static inline final TEXTURE_WRAP_R = 0x8072;
	public static inline final TEXTURE_WRAP_S = 0x2802;
	public static inline final TEXTURE_WRAP_T = 0x2803;
	public static inline final TEXTURE_LOD_BIAS = 0x8501;
	public static inline final TEXTURE_BASE_LEVEL = 0x813C;
	public static inline final TEXTURE_MAX_LEVEL = 0x813D;
	public static inline final TEXTURE_MAX_ANISOTROPY = 0x84FE;
	public static inline final TEXTURE_COMPARE_MODE = 0x884C;
	public static inline final TEXTURE_COMPARE_FUNC = 0x884D;
	public static inline final COMPARE_REF_TO_TEXTURE = 0x884E;
	public static inline final TEXTURE_2D = 0x0DE1;
	public static inline final TEXTURE_2D_MULTISAMPLE = 0x9100;
	public static inline final TEXTURE_3D = 0x806F;
	public static inline final TEXTURE = 0x1702;
	public static inline final TEXTURE_2D_ARRAY = 0x8C1A;
	public static inline final TEXTURE_1D = 0x0DE0;
	public static inline final TEXTURE_1D_ARRAY = 0x8C18;
	public static inline final TEXTURE_CUBE_MAP_ARRAY = 0x9009;
	public static inline final TEXTURE_CUBE_MAP_SEAMLESS = 0x884F;
	public static inline final TEXTURE_CUBE_MAP = 0x8513;
	public static inline final TEXTURE_BINDING_CUBE_MAP = 0x8514;
	public static inline final TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
	public static inline final TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
	public static inline final TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
	public static inline final TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
	public static inline final TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
	public static inline final TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
	public static inline final READ_ONLY = 0x88B8;
	public static inline final WRITE_ONLY = 0x88B9;
	public static inline final READ_WRITE = 0x88BA;
	public static inline final IMAGE_1D = 0x904C;
	public static inline final IMAGE_2D = 0x904D;
	public static inline final IMAGE_3D = 0x904E;
	public static inline final IMAGE_2D_RECT = 0x904F;
	public static inline final IMAGE_CUBE = 0x9050;
	public static inline final IMAGE_BUFFER = 0x9051;
	public static inline final IMAGE_1D_ARRAY = 0x9052;
	public static inline final IMAGE_2D_ARRAY = 0x9053;
	public static inline final IMAGE_CUBE_MAP_ARRAY = 0x9054;
	public static inline final TEXTURE0 = 0x84C0;
	public static inline final TEXTURE1 = 0x84C1;
	public static inline final TEXTURE2 = 0x84C2;
	public static inline final TEXTURE3 = 0x84C3;
	public static inline final TEXTURE4 = 0x84C4;
	public static inline final TEXTURE5 = 0x84C5;
	public static inline final TEXTURE6 = 0x84C6;
	public static inline final TEXTURE7 = 0x84C7;
	public static inline final TEXTURE8 = 0x84C8;
	public static inline final TEXTURE9 = 0x84C9;
	public static inline final TEXTURE10 = 0x84CA;
	public static inline final TEXTURE11 = 0x84CB;
	public static inline final TEXTURE12 = 0x84CC;
	public static inline final TEXTURE13 = 0x84CD;
	public static inline final TEXTURE14 = 0x84CE;
	public static inline final TEXTURE15 = 0x84CF;
	public static inline final TEXTURE16 = 0x84D0;
	public static inline final TEXTURE17 = 0x84D1;
	public static inline final TEXTURE18 = 0x84D2;
	public static inline final TEXTURE19 = 0x84D3;
	public static inline final TEXTURE20 = 0x84D4;
	public static inline final TEXTURE21 = 0x84D5;
	public static inline final TEXTURE22 = 0x84D6;
	public static inline final TEXTURE23 = 0x84D7;
	public static inline final TEXTURE24 = 0x84D8;
	public static inline final TEXTURE25 = 0x84D9;
	public static inline final TEXTURE26 = 0x84DA;
	public static inline final TEXTURE27 = 0x84DB;
	public static inline final TEXTURE28 = 0x84DC;
	public static inline final TEXTURE29 = 0x84DD;
	public static inline final TEXTURE30 = 0x84DE;
	public static inline final TEXTURE31 = 0x84DF;
	public static inline final ACTIVE_TEXTURE = 0x84E0;
	public static inline final REPEAT = 0x2901;
	public static inline final CLAMP_TO_EDGE = 0x812F;
	public static inline final MIRRORED_REPEAT = 0x8370;
	public static inline final UNPACK_FLIP_Y_WEBGL = 0x9240;
	public static inline final UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
	public static inline final UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
	public static inline final BROWSER_DEFAULT_WEBGL = 0x9244;
}
