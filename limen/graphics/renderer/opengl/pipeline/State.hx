package limen.graphics.renderer.opengl.pipeline;

@:hlNative("limen", "opengl_gl_")
class State {
	public static function scissor(x:Int, y:Int, width:Int, height:Int) {}

	public static function polygonMode(face:Int, mode:Int) {}

	public static function polygonOffset(factor:hl.F32, units:hl.F32) {}

	public static function enable(feature:Int) {}

	public static function disable(feature:Int) {}

	public static function cullFace(face:Int) {}

	public static function frontFace(direction:Int) {}

	public static function blendFunc(src:Int, dst:Int) {}

	public static function blendFuncSeparate(src:Int, dst:Int, alphaSrc:Int, alphaDst:Int) {}

	public static function blendEquation(op:Int) {}

	public static function blendEquationSeparate(op:Int, alphaOp:Int) {}

	public static function depthMask(mask:Bool) {}

	public static function depthFunc(f:Int) {}

	public static function colorMask(r:Bool, g:Bool, b:Bool, a:Bool) {}

	public static function colorMaski(i:Int, r:Bool, g:Bool, b:Bool, a:Bool) {}

	public static function stencilMaskSeparate(face:Int, mask:Int) {}

	public static function stencilFuncSeparate(face:Int, func:Int, ref:Int, mask:Int) {}

	public static function stencilOpSeparate(face:Int, sfail:Int, dpfail:Int, dppas:Int) {}

	public static inline final ZERO = 0;
	public static inline final ONE = 1;
	public static inline final SRC_COLOR = 0x0300;
	public static inline final ONE_MINUS_SRC_COLOR = 0x0301;
	public static inline final SRC_ALPHA = 0x0302;
	public static inline final ONE_MINUS_SRC_ALPHA = 0x0303;
	public static inline final DST_ALPHA = 0x0304;
	public static inline final ONE_MINUS_DST_ALPHA = 0x0305;
	public static inline final DST_COLOR = 0x0306;
	public static inline final ONE_MINUS_DST_COLOR = 0x0307;
	public static inline final SRC_ALPHA_SATURATE = 0x0308;
	public static inline final FUNC_ADD = 0x8006;
	public static inline final FUNC_MIN = 0x8007;
	public static inline final FUNC_MAX = 0x8008;
	public static inline final BLEND_EQUATION = 0x8009;
	public static inline final BLEND_EQUATION_RGB = 0x8009; // same as BLEND_EQUATION
	public static inline final BLEND_EQUATION_ALPHA = 0x883D;
	public static inline final FUNC_SUBTRACT = 0x800A;
	public static inline final FUNC_REVERSE_SUBTRACT = 0x800B;
	public static inline final BLEND_DST_RGB = 0x80C8;
	public static inline final BLEND_SRC_RGB = 0x80C9;
	public static inline final BLEND_DST_ALPHA = 0x80CA;
	public static inline final BLEND_SRC_ALPHA = 0x80CB;
	public static inline final CONSTANT_COLOR = 0x8001;
	public static inline final ONE_MINUS_CONSTANT_COLOR = 0x8002;
	public static inline final CONSTANT_ALPHA = 0x8003;
	public static inline final ONE_MINUS_CONSTANT_ALPHA = 0x8004;
	public static inline final BLEND_COLOR = 0x8005;
	public static inline final FRONT = 0x0404;
	public static inline final BACK = 0x0405;
	public static inline final FRONT_AND_BACK = 0x0408;
	public static inline final POINT = 0x1B00;
	public static inline final LINE = 0x1B01;
	public static inline final FILL = 0x1B02;
	public static inline final CULL_FACE = 0x0B44;
	public static inline final BLEND = 0x0BE2;
	public static inline final DITHER = 0x0BD0;
	public static inline final STENCIL_TEST = 0x0B90;
	public static inline final DEPTH_TEST = 0x0B71;
	public static inline final SCISSOR_TEST = 0x0C11;
	public static inline final POLYGON_OFFSET_FILL = 0x8037;
	public static inline final SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
	public static inline final SAMPLE_COVERAGE = 0x80A0;
	public static inline final MULTISAMPLE = 0x809D;
	public static inline final DEPTH_CLAMP = 0x864F;
	public static inline final CW = 0x0900;
	public static inline final CCW = 0x0901;
	public static inline final LINE_WIDTH = 0x0B21;
	public static inline final ALIASED_POINT_SIZE_RANGE = 0x846D;
	public static inline final ALIASED_LINE_WIDTH_RANGE = 0x846E;
	public static inline final CULL_FACE_MODE = 0x0B45;
	public static inline final FRONT_FACE = 0x0B46;
	public static inline final DEPTH_RANGE = 0x0B70;
	public static inline final DEPTH_WRITEMASK = 0x0B72;
	public static inline final DEPTH_CLEAR_VALUE = 0x0B73;
	public static inline final DEPTH_FUNC = 0x0B74;
	public static inline final STENCIL_CLEAR_VALUE = 0x0B91;
	public static inline final STENCIL_FUNC = 0x0B92;
	public static inline final STENCIL_FAIL = 0x0B94;
	public static inline final STENCIL_PASS_DEPTH_FAIL = 0x0B95;
	public static inline final STENCIL_PASS_DEPTH_PASS = 0x0B96;
	public static inline final STENCIL_REF = 0x0B97;
	public static inline final STENCIL_VALUE_MASK = 0x0B93;
	public static inline final STENCIL_WRITEMASK = 0x0B98;
	public static inline final STENCIL_BACK_FUNC = 0x8800;
	public static inline final STENCIL_BACK_FAIL = 0x8801;
	public static inline final STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
	public static inline final STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
	public static inline final STENCIL_BACK_REF = 0x8CA3;
	public static inline final STENCIL_BACK_VALUE_MASK = 0x8CA4;
	public static inline final STENCIL_BACK_WRITEMASK = 0x8CA5;
	public static inline final VIEWPORT = 0x0BA2;
	public static inline final SCISSOR_BOX = 0x0C10;
	public static inline final COLOR_CLEAR_VALUE = 0x0C22;
	public static inline final COLOR_WRITEMASK = 0x0C23;
	public static inline final POLYGON_OFFSET_UNITS = 0x2A00;
	public static inline final POLYGON_OFFSET_FACTOR = 0x8038;
	public static inline final SAMPLE_BUFFERS = 0x80A8;
	public static inline final SAMPLES = 0x80A9;
	public static inline final SAMPLE_COVERAGE_VALUE = 0x80AA;
	public static inline final SAMPLE_COVERAGE_INVERT = 0x80AB;
	public static inline final FRAMEBUFFER_SRGB = 0x8DB9;
	public static inline final NEVER = 0x0200;
	public static inline final LESS = 0x0201;
	public static inline final EQUAL = 0x0202;
	public static inline final LEQUAL = 0x0203;
	public static inline final GREATER = 0x0204;
	public static inline final NOTEQUAL = 0x0205;
	public static inline final GEQUAL = 0x0206;
	public static inline final ALWAYS = 0x0207;
	public static inline final KEEP = 0x1E00;
	public static inline final REPLACE = 0x1E01;
	public static inline final INCR = 0x1E02;
	public static inline final DECR = 0x1E03;
	public static inline final INVERT = 0x150A;
	public static inline final INCR_WRAP = 0x8507;
	public static inline final DECR_WRAP = 0x8508;
	public static inline final VERTEX_PROGRAM_POINT_SIZE = 0x8642;
	public static inline final POINT_SPRITE = 0x8861;
}
