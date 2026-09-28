package limen.graphics.renderer.opengl.resource;

abstract Buffer(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class Buffers {
	public static function createBuffer():Buffer {
		return null;
	}

	public static function bindBufferBase(target:Int, index:Int, buffer:Buffer) {}

	public static function bindBuffer(target:Int, b:Buffer) {}

	public static function bufferDataSize(target:Int, size:Int, param:Int) {}

	public static function bufferData(target:Int, size:Int, data:hl.Bytes, param:Int) {}

	public static function bufferSubData(target:Int, offset:Int, data:hl.Bytes, srcOffset:Int, srcLength:Int) {}

	@:hlNative("limen", "opengl_gl_get_buffer_sub_data")
	public static function getBufferSubData(target:Int, offset:Int, data:hl.Bytes, srcOffset:Int, srcLength:Int) {}

	public static function deleteBuffer(b:Buffer) {}

	public static inline final ARRAY_BUFFER = 0x8892;
	public static inline final ELEMENT_ARRAY_BUFFER = 0x8893;
	public static inline final ARRAY_BUFFER_BINDING = 0x8894;
	public static inline final ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
	public static inline final SHADER_STORAGE_BUFFER = 0x90D2;
	public static inline final UNIFORM_BUFFER = 0x8A11;
	public static inline final QUERY_BUFFER = 0x9192;
	public static inline final STREAM_DRAW = 0x88E0;
	public static inline final STATIC_DRAW = 0x88E4;
	public static inline final DYNAMIC_DRAW = 0x88E8;
	public static inline final BUFFER_SIZE = 0x8764;
	public static inline final BUFFER_USAGE = 0x8765;
	public static inline final DRAW_INDIRECT_BUFFER = 0x8F3F;
	public static inline final PARAMETER_BUFFER = 0x80ee;
}
