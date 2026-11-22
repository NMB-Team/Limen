package limen.graphics.renderer.opengl.vertex;

abstract VertexArray(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class VertexArrays {
	public static function enableVertexAttribArray(attrib:Int) {}

	public static function disableVertexAttribArray(attrib:Int) {}

	public static function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, position:Int) {}

	public static function vertexAttribIPointer(index:Int, size:Int, type:Int, stride:Int, position:Int) {}

	public static function vertexAttribDivisor(index:Int, divisor:Int) {}

	public static function createVertexArray():VertexArray {
		return null;
	}

	public static function bindVertexArray(a:VertexArray):Void {}

	public static function deleteVertexArray(a:VertexArray):Void {}

	public static inline final CURRENT_VERTEX_ATTRIB = 0x8626;
	public static inline final VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
	public static inline final VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
	public static inline final VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
	public static inline final VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
	public static inline final VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
	public static inline final VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
	public static inline final VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
}
