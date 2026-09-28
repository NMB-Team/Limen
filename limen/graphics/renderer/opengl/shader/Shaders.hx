package limen.graphics.renderer.opengl.shader;

abstract Uniform(Null<Int>) {}
abstract Program(Null<Int>) {}
abstract Shader(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class Shaders {
	public static function createProgram():Program {
		return null;
	}

	public static function deleteProgram(p:Program) {}

	public static function bindFragDataLocation(p:Program, colorNumber:Int, name:String):Void {}

	public static function attachShader(p:Program, s:Shader) {}

	public static function linkProgram(p:Program) {}

	public static function getProgramParameter(p:Program, param:Int):Dynamic {
		return null;
	}

	public static inline function getProgramInfoLog(p:Program):String {
		return @:privateAccess String.fromUTF8(getProgramInfoBytes(p));
	}

	static function getProgramInfoBytes(p:Program):hl.Bytes {
		return null;
	}

	public static function getUniformLocation(p:Program, name:String):Uniform {
		return null;
	}

	public static function getAttribLocation(p:Program, name:String):Int {
		return -1;
	}

	public static function useProgram(p:Program) {}

	public static function createShader(type:Int):Shader {
		return null;
	}

	public static function shaderSource(s:Shader, src:String) {}

	public static function compileShader(s:Shader) {}

	public static inline function getShaderInfoLog(s:Shader):String {
		return @:privateAccess String.fromUTF8(getShaderInfoBytes(s));
	}

	static function getShaderInfoBytes(s:Shader):hl.Bytes {
		return null;
	}

	public static function getShaderParameter(s:Shader, param:Int):Dynamic {
		return null;
	}

	public static function deleteShader(s:Shader) {}

	public static function uniform1i(u:Uniform, i:Int) {}

	public static function uniform3fv(u:Uniform, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniform4fv(u:Uniform, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniformMatrix3fv(u:Uniform, transpose:Bool, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniformMatrix4fv(u:Uniform, transpose:Bool, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniform1f(u:Uniform, x:Float) {}

	public static function uniform2f(u:Uniform, x:Float, y:Float) {}

	public static function uniform3f(u:Uniform, x:Float, y:Float, z:Float) {}

	public static function uniform4f(u:Uniform, x:Float, y:Float, z:Float, w:Float) {}

	public static function getUniformBlockIndex(p:Program, name:String):Int {
		return 0;
	}

	public static function uniformBlockBinding(p:Program, blockIndex:Int, blockBinding:Int):Void {}

	/** Requires OpenGL 4.3+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_get_program_resource_index")
	public static function getProgramResourceIndex(p:Program, type:Int, name:String):Int {
		return 0;
	}

	/** Requires OpenGL 4.3+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_shader_storage_block_binding")
	public static function shaderStorageBlockBinding(p:Program, blockIndex:Int, blockBinding:Int):Void {}

	public static inline final SHADER_STORAGE_BLOCK = 0x92E6;
	public static inline final FRAGMENT_SHADER = 0x8B30;
	public static inline final VERTEX_SHADER = 0x8B31;
	public static inline final GEOMETRY_SHADER = 0x8DD9;
	public static inline final COMPUTE_SHADER = 0x91B9;
	public static inline final SHADER_TYPE = 0x8B4F;
	public static inline final DELETE_STATUS = 0x8B80;
	public static inline final LINK_STATUS = 0x8B82;
	public static inline final VALIDATE_STATUS = 0x8B83;
	public static inline final ATTACHED_SHADERS = 0x8B85;
	public static inline final ACTIVE_UNIFORMS = 0x8B86;
	public static inline final ACTIVE_ATTRIBUTES = 0x8B89;
	public static inline final CURRENT_PROGRAM = 0x8B8D;
	public static inline final FLOAT_VEC2 = 0x8B50;
	public static inline final FLOAT_VEC3 = 0x8B51;
	public static inline final FLOAT_VEC4 = 0x8B52;
	public static inline final INT_VEC2 = 0x8B53;
	public static inline final INT_VEC3 = 0x8B54;
	public static inline final INT_VEC4 = 0x8B55;
	public static inline final BOOL = 0x8B56;
	public static inline final BOOL_VEC2 = 0x8B57;
	public static inline final BOOL_VEC3 = 0x8B58;
	public static inline final BOOL_VEC4 = 0x8B59;
	public static inline final FLOAT_MAT2 = 0x8B5A;
	public static inline final FLOAT_MAT3 = 0x8B5B;
	public static inline final FLOAT_MAT4 = 0x8B5C;
	public static inline final SAMPLER_2D = 0x8B5E;
	public static inline final SAMPLER_CUBE = 0x8B60;
	public static inline final COMPILE_STATUS = 0x8B81;
	public static inline final LOW_FLOAT = 0x8DF0;
	public static inline final MEDIUM_FLOAT = 0x8DF1;
	public static inline final HIGH_FLOAT = 0x8DF2;
	public static inline final LOW_INT = 0x8DF3;
	public static inline final MEDIUM_INT = 0x8DF4;
	public static inline final HIGH_INT = 0x8DF5;
}
