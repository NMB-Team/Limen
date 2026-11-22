package limen.graphics.renderer.opengl.command;

@:hlNative("limen", "opengl_gl_")
class Commands {
	public static function clear(bits:Int) {}

	public static function clearColor(r:Float, g:Float, b:Float, a:Float) {}

	public static function clearDepth(value:Float) {}

	public static function clearStencil(value:Int) {}

	public static function viewport(x:Int, y:Int, width:Int, height:Int) {}

	public static function finish() {}

	public static function dispatchCompute(num_groups_x:Int, num_groups_y:Int, num_groups_z:Int) {}

	public static function memoryBarrier(barrier:Int) {}

	public static function drawElements(mode:Int, count:Int, type:Int, start:Int) {}

	public static function drawElementsInstanced(mode:Int, count:Int, type:Int, start:Int, primcount:Int) {}

	public static function drawArrays(mode:Int, start:Int, count:Int) {}

	public static function drawArraysInstanced(mode:Int, start:Int, count:Int, primcount:Int) {}

	public static function multiDrawElementsIndirect(mode:Int, type:Int, data:hl.Bytes, count:Int, stride:Int) {}

	public static function multiDrawElementsIndirectCount(mode:Int, type:Int, data:hl.Bytes, drawcount:hl.Bytes, maxdrawcount:Int, stride:Int) {}

	public static inline final DEPTH_BUFFER_BIT = 0x00000100;
	public static inline final STENCIL_BUFFER_BIT = 0x00000400;
	public static inline final COLOR_BUFFER_BIT = 0x00004000;
	public static inline final POINTS = 0x0000;
	public static inline final LINES = 0x0001;
	public static inline final LINE_LOOP = 0x0002;
	public static inline final LINE_STRIP = 0x0003;
	public static inline final TRIANGLES = 0x0004;
	public static inline final TRIANGLE_STRIP = 0x0005;
	public static inline final TRIANGLE_FAN = 0x0006;
	public static inline final VERTEX_ATTRIB_ARRAY_BARRIER_BIT = 0x00000001;
	public static inline final ELEMENT_ARRAY_BARRIER_BIT = 0x00000002;
	public static inline final UNIFORM_BARRIER_BIT = 0x00000004;
	public static inline final TEXTURE_FETCH_BARRIER_BIT = 0x00000008;
	public static inline final SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020;
	public static inline final COMMAND_BARRIER_BIT = 0x00000040;
	public static inline final PIXEL_BUFFER_BARRIER_BIT = 0x00000080;
	public static inline final TEXTURE_UPDATE_BARRIER_BIT = 0x00000100;
	public static inline final BUFFER_UPDATE_BARRIER_BIT = 0x00000200;
	public static inline final FRAMEBUFFER_BARRIER_BIT = 0x00000400;
	public static inline final TRANSFORM_FEEDBACK_BARRIER_BIT = 0x00000800;
	public static inline final ATOMIC_COUNTER_BARRIER_BIT = 0x00001000;
	public static inline final SHADER_STORAGE_BARRIER_BIT = 0x00002000;
	public static inline final QUERY_BUFFER_BARRIER_BIT = 0x00008000;
	public static inline final ALL_BARRIER_BITS = 0xFFFFFFFF;
}
