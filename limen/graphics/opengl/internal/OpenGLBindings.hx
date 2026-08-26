package limen.graphics.opengl.internal;

import limen.graphics.opengl.OpenGLTypes.Buffer;
import limen.graphics.opengl.OpenGLTypes.Framebuffer;
import limen.graphics.opengl.OpenGLTypes.Program;
import limen.graphics.opengl.OpenGLTypes.Query;
import limen.graphics.opengl.OpenGLTypes.Renderbuffer;
import limen.graphics.opengl.OpenGLTypes.Shader;
import limen.graphics.opengl.OpenGLTypes.Texture;
import limen.graphics.opengl.OpenGLTypes.Uniform;
import limen.graphics.opengl.OpenGLTypes.VertexArray;

import haxe.Int64;

import limen.platform.window.Window.WinPtr;

abstract ContextHandle(hl.Abstract<"limen_gl">) {}

@:hlNative("limen", "opengl_gl_")
class OpenGLBindings {
	@:hlNative("limen", "opengl_win_get_glcontext")
	public static function createContext(window:WinPtr):ContextHandle {
		return null;
	}

	@:hlNative("limen", "opengl_gl_context_destroy")
	public static function destroyContext(context:ContextHandle):Void {}

	@:hlNative("limen", "opengl_win_render_to")
	public static function makeCurrent(window:WinPtr, context:ContextHandle):Void {}

	@:hlNative("limen", "opengl_win_swap_window")
	public static function swapWindow(window:WinPtr):Void {}

	@:hlNative("limen", "opengl_gl_options")
	public static function configureContext(major:Int, minor:Int, depth:Int, stencil:Int, flags:Int, samples:Int):Void {}

	@:hlNative("limen", "opengl_set_vsync")
	public static function setVsync(enabled:Bool):Void {}

	public static function init():Bool {
		return false;
	}

	@:hlNative("limen", "opengl_gl_set_debug")
	public static function setDebug(enable:Bool):Bool {
		return false;
	}

	// non standard
	public static function getConfigParameter(v:Int):Int {
		return 0;
	}

	public static function hasExtension(name:String):Bool {
		return false;
	}

	public static function isContextLost():Bool {
		return false;
	}

	public static function clear(bits:Int) {}

	public static function getError():Int {
		return 0;
	}

	public static function scissor(x:Int, y:Int, width:Int, height:Int) {}

	public static function clearColor(r:Float, g:Float, b:Float, a:Float) {}

	public static function clearDepth(value:Float) {}

	public static function clearStencil(value:Int) {}

	public static function viewport(x:Int, y:Int, width:Int, height:Int) {}

	public static function finish() {}

	public static function pixelStorei(key:Int, value:Int) {}

	public static function getParameter(name:Int):Dynamic {
		switch (name) {
			case VENDOR, VERSION, RENDERER, SHADING_LANGUAGE_VERSION:
				return @:privateAccess String.fromUTF8(getString(name));
			case _:
				throw "Not implemented";
				return null;
		}
	}

	static function getString(name:Int):hl.Bytes {
		return null;
	}

	// state changes

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

	// program

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

	public static function getProgramInfoLog(p:Program):String {
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

	// shader

	public static function createShader(type:Int):Shader {
		return null;
	}

	public static function shaderSource(s:Shader, src:String) {}

	public static function compileShader(s:Shader) {}

	public static function getShaderInfoLog(s:Shader):String {
		return @:privateAccess String.fromUTF8(getShaderInfoBytes(s));
	}

	static function getShaderInfoBytes(s:Shader):hl.Bytes {
		return null;
	}

	public static function getShaderParameter(s:Shader, param:Int):Dynamic {
		return null;
	}

	public static function deleteShader(s:Shader) {}

	// texture

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

	// framebuffer

	public static function blitFramebuffer(src_x0:Int, src_y0:Int, src_x1:Int, src_y1:Int, dst_x0:Int, dst_y0:Int, dst_x1:Int, dst_y1:Int, mask:Int, filter:Int) {}

	public static function createFramebuffer():Framebuffer {
		return null;
	}

	public static function bindFramebuffer(target:Int, f:Framebuffer) {}

	@:hlNative("limen", "opengl_gl_framebuffer_texture2d")
	public static function framebufferTexture2D(target:Int, attach:Int, texTarget:Int, t:Texture, level:Int) {}

	public static function framebufferTextureLayer(target:Int, attach:Int, t:Texture, level:Int, layer:Int) {}

	public static function framebufferTexture(target:Int, attach:Int, t:Texture, level:Int) {}

	public static function deleteFramebuffer(f:Framebuffer) {}

	public static function readBuffer(mode:Int) {}

	public static function readPixels(x:Int, y:Int, width:Int, height:Int, format:Int, type:Int, data:hl.Bytes) {}

	public static function drawBuffers(n:Int, buffers:hl.Bytes) {}

	// renderbuffer

	public static function createRenderbuffer():Renderbuffer {
		return null;
	}

	public static function bindRenderbuffer(target:Int, r:Renderbuffer) {}

	public static function renderbufferStorage(target:Int, format:Int, width:Int, height:Int) {}

	public static function renderbufferStorageMultisample(target:Int, samples:Int, format:Int, width:Int, height:Int) {}

	public static function framebufferRenderbuffer(frameTarget:Int, attach:Int, renderTarget:Int, b:Renderbuffer) {}

	public static function deleteRenderbuffer(b:Renderbuffer) {}

	// buffer

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

	public static function enableVertexAttribArray(attrib:Int) {}

	public static function disableVertexAttribArray(attrib:Int) {}

	public static function vertexAttribPointer(index:Int, size:Int, type:Int, normalized:Bool, stride:Int, position:Int) {}

	public static function vertexAttribIPointer(index:Int, size:Int, type:Int, stride:Int, position:Int) {}

	public static function vertexAttribDivisor(index:Int, divisor:Int) {}

	public static function deleteBuffer(b:Buffer) {}

	// uniforms

	public static function uniform1i(u:Uniform, i:Int) {}

	public static function uniform3fv(u:Uniform, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniform4fv(u:Uniform, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniformMatrix3fv(u:Uniform, transpose:Bool, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniformMatrix4fv(u:Uniform, transpose:Bool, buffer:hl.Bytes, bufPos:Int, count:Int) {}

	public static function uniform1f(u:Uniform, x:Float) {}

	public static function uniform2f(u:Uniform, x:Float, y:Float) {}

	public static function uniform3f(u:Uniform, x:Float, y:Float, z:Float) {}

	public static function uniform4f(u:Uniform, x:Float, y:Float, z:Float, w:Float) {}

	// compute

	public static function dispatchCompute(num_groups_x:Int, num_groups_y:Int, num_groups_z:Int) {}

	public static function memoryBarrier(barrier:Int) {}

	// draw

	public static function drawElements(mode:Int, count:Int, type:Int, start:Int) {}

	public static function drawElementsInstanced(mode:Int, count:Int, type:Int, start:Int, primcount:Int) {}

	public static function drawArrays(mode:Int, start:Int, count:Int) {}

	public static function drawArraysInstanced(mode:Int, start:Int, count:Int, primcount:Int) {}

	public static function multiDrawElementsIndirect(mode:Int, type:Int, data:hl.Bytes, count:Int, stride:Int) {}

	public static function multiDrawElementsIndirectCount(mode:Int, type:Int, data:hl.Bytes, drawcount:hl.Bytes, maxdrawcount:Int, stride:Int) {}

	// queries

	public static function createQuery():Query {
		return null;
	}

	public static function deleteQuery(q:Query) {}

	public static function beginQuery(target:Int, q:Query) {}

	public static function endQuery(target:Int) {}

	public static function queryResultAvailable(q:Query) {
		return false;
	}

	public static function queryResult(q:Query):Float {
		return 0.;
	}

	public static function queryCounter(q:Query, target:Int) {}

	// vertexarray
	public static function createVertexArray():VertexArray {
		return null;
	}

	public static function bindVertexArray(a:VertexArray):Void {}

	public static function deleteVertexArray(a:VertexArray):Void {}

	// uniform buffer

	public static function getUniformBlockIndex(p:Program, name:String):Int {
		return 0;
	}

	public static function uniformBlockBinding(p:Program, blockIndex:Int, blockBinding:Int):Void {}

	// ssbos

	/** Requires OpenGL 4.3+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_get_program_resource_index")
	public static function getProgramResourceIndex(p:Program, type:Int, name:String):Int {
		return 0;
	}

	/** Requires OpenGL 4.3+, therefore not supported on Apple platforms **/
	@:hlNative("limen", "opengl_gl_shader_storage_block_binding")
	public static function shaderStorageBlockBinding(p:Program, blockIndex:Int, blockBinding:Int):Void {}

	// ----- CONSTANTS -----
	// ClearBufferMask
	public static inline final DEPTH_BUFFER_BIT = 0x00000100;
	public static inline final STENCIL_BUFFER_BIT = 0x00000400;
	public static inline final COLOR_BUFFER_BIT = 0x00004000;

	// BeginMode
	public static inline final POINTS = 0x0000;
	public static inline final LINES = 0x0001;
	public static inline final LINE_LOOP = 0x0002;
	public static inline final LINE_STRIP = 0x0003;
	public static inline final TRIANGLES = 0x0004;
	public static inline final TRIANGLE_STRIP = 0x0005;
	public static inline final TRIANGLE_FAN = 0x0006;

	// AlphaFunction(not supported in ES20)
	//	  NEVER
	//	  LESS
	//	  EQUAL
	//	  LEQUAL
	//	  GREATER
	//	  NOTEQUAL
	//	  GEQUAL
	//	  ALWAYS
	// BlendingFactorDest
	public static inline final ZERO = 0;
	public static inline final ONE = 1;
	public static inline final SRC_COLOR = 0x0300;
	public static inline final ONE_MINUS_SRC_COLOR = 0x0301;
	public static inline final SRC_ALPHA = 0x0302;
	public static inline final ONE_MINUS_SRC_ALPHA = 0x0303;
	public static inline final DST_ALPHA = 0x0304;
	public static inline final ONE_MINUS_DST_ALPHA = 0x0305;

	// BlendingFactorSrc
	//	  ZERO
	//	  ONE
	public static inline final DST_COLOR = 0x0306;
	public static inline final ONE_MINUS_DST_COLOR = 0x0307;
	public static inline final SRC_ALPHA_SATURATE = 0x0308;
	//	  SRC_ALPHA
	//	  ONE_MINUS_SRC_ALPHA
	//	  DST_ALPHA
	//	  ONE_MINUS_DST_ALPHA
	// BlendEquationSeparate
	public static inline final FUNC_ADD = 0x8006;
	public static inline final FUNC_MIN = 0x8007;
	public static inline final FUNC_MAX = 0x8008;
	public static inline final BLEND_EQUATION = 0x8009;
	public static inline final BLEND_EQUATION_RGB = 0x8009; // same as BLEND_EQUATION
	public static inline final BLEND_EQUATION_ALPHA = 0x883D;

	// BlendSubtract
	public static inline final FUNC_SUBTRACT = 0x800A;
	public static inline final FUNC_REVERSE_SUBTRACT = 0x800B;

	// Separate Blend Functions
	public static inline final BLEND_DST_RGB = 0x80C8;
	public static inline final BLEND_SRC_RGB = 0x80C9;
	public static inline final BLEND_DST_ALPHA = 0x80CA;
	public static inline final BLEND_SRC_ALPHA = 0x80CB;
	public static inline final CONSTANT_COLOR = 0x8001;
	public static inline final ONE_MINUS_CONSTANT_COLOR = 0x8002;
	public static inline final CONSTANT_ALPHA = 0x8003;
	public static inline final ONE_MINUS_CONSTANT_ALPHA = 0x8004;
	public static inline final BLEND_COLOR = 0x8005;

	// GLBuffer Objects
	public static inline final ARRAY_BUFFER = 0x8892;
	public static inline final ELEMENT_ARRAY_BUFFER = 0x8893;
	public static inline final ARRAY_BUFFER_BINDING = 0x8894;
	public static inline final ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
	public static inline final SHADER_STORAGE_BUFFER = 0x90D2;
	public static inline final UNIFORM_BUFFER = 0x8A11;
	public static inline final QUERY_BUFFER = 0x9192;

	public static inline final SHADER_STORAGE_BLOCK = 0x92E6;

	public static inline final STREAM_DRAW = 0x88E0;
	public static inline final STATIC_DRAW = 0x88E4;
	public static inline final DYNAMIC_DRAW = 0x88E8;

	public static inline final BUFFER_SIZE = 0x8764;
	public static inline final BUFFER_USAGE = 0x8765;

	public static inline final CURRENT_VERTEX_ATTRIB = 0x8626;

	// CullFaceMode
	public static inline final FRONT = 0x0404;
	public static inline final BACK = 0x0405;
	public static inline final FRONT_AND_BACK = 0x0408;

	// PolygonMode
	public static inline final POINT = 0x1B00;
	public static inline final LINE = 0x1B01;
	public static inline final FILL = 0x1B02;

	// DepthFunction
	//	  NEVER
	//	  LESS
	//	  EQUAL
	//	  LEQUAL
	//	  GREATER
	//	  NOTEQUAL
	//	  GEQUAL
	//	  ALWAYS
	// EnableCap
	// TEXTURE_2D
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

	// ErrorCode
	public static inline final NO_ERROR = 0;
	public static inline final INVALID_ENUM = 0x0500;
	public static inline final INVALID_VALUE = 0x0501;
	public static inline final INVALID_OPERATION = 0x0502;
	public static inline final OUT_OF_MEMORY = 0x0505;

	// FrontFaceDirection
	public static inline final CW = 0x0900;
	public static inline final CCW = 0x0901;

	// GetPName
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
	//	  SCISSOR_TEST
	public static inline final COLOR_CLEAR_VALUE = 0x0C22;
	public static inline final COLOR_WRITEMASK = 0x0C23;
	public static inline final UNPACK_ALIGNMENT = 0x0CF5;
	public static inline final PACK_ALIGNMENT = 0x0D05;
	public static inline final MAX_TEXTURE_SIZE = 0x0D33;
	public static inline final MAX_VIEWPORT_DIMS = 0x0D3A;
	public static inline final SUBPIXEL_BITS = 0x0D50;
	public static inline final RED_BITS = 0x0D52;
	public static inline final GREEN_BITS = 0x0D53;
	public static inline final BLUE_BITS = 0x0D54;
	public static inline final ALPHA_BITS = 0x0D55;
	public static inline final DEPTH_BITS = 0x0D56;
	public static inline final STENCIL_BITS = 0x0D57;
	public static inline final POLYGON_OFFSET_UNITS = 0x2A00;
	//	  POLYGON_OFFSET_FILL
	public static inline final POLYGON_OFFSET_FACTOR = 0x8038;
	public static inline final TEXTURE_BINDING_2D = 0x8069;
	public static inline final SAMPLE_BUFFERS = 0x80A8;
	public static inline final SAMPLES = 0x80A9;
	public static inline final SAMPLE_COVERAGE_VALUE = 0x80AA;
	public static inline final SAMPLE_COVERAGE_INVERT = 0x80AB;

	// GetTextureParameter
	//	  TEXTURE_MAG_FILTER
	//	  TEXTURE_MIN_FILTER
	//	  TEXTURE_WRAP_S
	//	  TEXTURE_WRAP_T
	public static inline final COMPRESSED_TEXTURE_FORMATS = 0x86A3;

	// HintMode
	public static inline final DONT_CARE = 0x1100;
	public static inline final FASTEST = 0x1101;
	public static inline final NICEST = 0x1102;

	// HintTarget
	public static inline final GENERATE_MIPMAP_HINT = 0x8192;

	// DataType
	public static inline final BYTE = 0x1400;
	public static inline final UNSIGNED_BYTE = 0x1401;
	public static inline final SHORT = 0x1402;
	public static inline final UNSIGNED_SHORT = 0x1403;
	public static inline final INT = 0x1404;
	public static inline final UNSIGNED_INT = 0x1405;
	public static inline final FLOAT = 0x1406;

	public static inline final HALF_FLOAT = 0x140B;

	// PixelFormat
	public static inline final DEPTH_COMPONENT = 0x1902;
	public static inline final RED = 0x1903;
	public static inline final GREEN = 0x1904;
	public static inline final BLUE = 0x1905;
	public static inline final ALPHA = 0x1906;
	public static inline final RG = 0x8227;
	public static inline final RGB = 0x1907;
	public static inline final RGBA = 0x1908;
	public static inline final LUMINANCE = 0x1909;
	public static inline final LUMINANCE_ALPHA = 0x190A;

	public static inline final BGRA = 0x80E1;
	public static inline final RGBA8 = 0x8058;
	public static inline final RGB10_A2 = 0x8059;

	public static inline final RG16 = 0x822C;
	public static inline final RG16UI = 0x823A;
	public static inline final RG16F = 0x822F;
	public static inline final RG32F = 0x8230;
	public static inline final R8 = 0x8229;
	public static inline final RG8 = 0x822B;
	public static inline final R16F = 0x822D;
	public static inline final R32F = 0x822E;
	public static inline final UNSIGNED_INT_2_10_10_10_REV = 0x8368;
	public static inline final UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
	public static inline final UNSIGNED_INT_24_8 = 0x84FA;

	// PixelType
	//	  UNSIGNED_BYTE
	public static inline final UNSIGNED_SHORT_4_4_4_4 = 0x8033;
	public static inline final UNSIGNED_SHORT_5_5_5_1 = 0x8034;
	public static inline final UNSIGNED_SHORT_5_6_5 = 0x8363;

	public static inline final SRGB = 0x8C40;
	public static inline final SRGB8 = 0x8C41;
	public static inline final SRGB_ALPHA = 0x8C42;
	public static inline final SRGB8_ALPHA = 0x8C43;
	public static inline final FRAMEBUFFER_SRGB = 0x8DB9;

	public static inline final RGBA32F = 0x8814;
	public static inline final RGB32F = 0x8815;
	public static inline final RGBA16F = 0x881A;
	public static inline final RGB16F = 0x881B;
	public static inline final R11F_G11F_B10F = 0x8C3A;
	public static inline final ALPHA16F = 0x881C;
	public static inline final ALPHA32F = 0x8816;

	// Shaders
	public static inline final FRAGMENT_SHADER = 0x8B30;
	public static inline final VERTEX_SHADER = 0x8B31;
	public static inline final GEOMETRY_SHADER = 0x8DD9;
	public static inline final COMPUTE_SHADER = 0x91B9;
	public static inline final MAX_VERTEX_ATTRIBS = 0x8869;
	public static inline final MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
	public static inline final MAX_VARYING_VECTORS = 0x8DFC;
	public static inline final MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
	public static inline final MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
	public static inline final MAX_TEXTURE_IMAGE_UNITS = 0x8872;
	public static inline final MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
	public static inline final SHADER_TYPE = 0x8B4F;
	public static inline final DELETE_STATUS = 0x8B80;
	public static inline final LINK_STATUS = 0x8B82;
	public static inline final VALIDATE_STATUS = 0x8B83;
	public static inline final ATTACHED_SHADERS = 0x8B85;
	public static inline final ACTIVE_UNIFORMS = 0x8B86;
	public static inline final ACTIVE_ATTRIBUTES = 0x8B89;
	public static inline final SHADING_LANGUAGE_VERSION = 0x8B8C;
	public static inline final CURRENT_PROGRAM = 0x8B8D;

	// StencilFunction
	public static inline final NEVER = 0x0200;
	public static inline final LESS = 0x0201;
	public static inline final EQUAL = 0x0202;
	public static inline final LEQUAL = 0x0203;
	public static inline final GREATER = 0x0204;
	public static inline final NOTEQUAL = 0x0205;
	public static inline final GEQUAL = 0x0206;
	public static inline final ALWAYS = 0x0207;

	// StencilOp
	//	  ZERO
	public static inline final KEEP = 0x1E00;
	public static inline final REPLACE = 0x1E01;
	public static inline final INCR = 0x1E02;
	public static inline final DECR = 0x1E03;
	public static inline final INVERT = 0x150A;
	public static inline final INCR_WRAP = 0x8507;
	public static inline final DECR_WRAP = 0x8508;

	// StringName
	public static inline final VENDOR = 0x1F00;
	public static inline final RENDERER = 0x1F01;
	public static inline final VERSION = 0x1F02;

	// TextureMagFilter
	public static inline final NEAREST = 0x2600;
	public static inline final LINEAR = 0x2601;

	// TextureMinFilter
	//	  NEAREST
	//	  LINEAR
	public static inline final NEAREST_MIPMAP_NEAREST = 0x2700;
	public static inline final LINEAR_MIPMAP_NEAREST = 0x2701;
	public static inline final NEAREST_MIPMAP_LINEAR = 0x2702;
	public static inline final LINEAR_MIPMAP_LINEAR = 0x2703;

	// TextureParameterName
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

	// TextureTarget
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
	public static inline final MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;

	// Image
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

	// TextureUnit
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

	// TextureWrapMode
	public static inline final REPEAT = 0x2901;
	public static inline final CLAMP_TO_EDGE = 0x812F;
	public static inline final MIRRORED_REPEAT = 0x8370;

	// Uniform Types
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

	// Vertex Arrays
	public static inline final VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
	public static inline final VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
	public static inline final VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
	public static inline final VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
	public static inline final VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
	public static inline final VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
	public static inline final VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;

	// Point Size
	public static inline final VERTEX_PROGRAM_POINT_SIZE = 0x8642;
	public static inline final POINT_SPRITE = 0x8861;

	// GLShader Source
	public static inline final COMPILE_STATUS = 0x8B81;

	// GLShader Precision-Specified Types
	public static inline final LOW_FLOAT = 0x8DF0;
	public static inline final MEDIUM_FLOAT = 0x8DF1;
	public static inline final HIGH_FLOAT = 0x8DF2;
	public static inline final LOW_INT = 0x8DF3;
	public static inline final MEDIUM_INT = 0x8DF4;
	public static inline final HIGH_INT = 0x8DF5;

	// GLFramebuffer Object.
	public static inline final FRAMEBUFFER = 0x8D40;
	public static inline final RENDERBUFFER = 0x8D41;
	public static inline final READ_FRAMEBUFFER = 0x8CA8;
	public static inline final DRAW_FRAMEBUFFER = 0x8CA9;
	public static inline final DRAW_INDIRECT_BUFFER = 0x8F3F;
	public static inline final PARAMETER_BUFFER = 0x80ee;

	public static inline final RGBA4 = 0x8056;
	public static inline final RGB5_A1 = 0x8057;
	public static inline final RGB565 = 0x8D62;
	public static inline final DEPTH_COMPONENT16 = 0x81A5;
	public static inline final DEPTH_COMPONENT24 = 0x81A6;
	public static inline final DEPTH24_STENCIL8 = 0x88F0;
	public static inline final DEPTH_COMPONENT32F = 0x8cac;
	public static inline final STENCIL_INDEX = 0x1901;
	public static inline final STENCIL_INDEX8 = 0x8D48;
	public static inline final DEPTH_STENCIL = 0x84F9;

	public static inline final RENDERBUFFER_WIDTH = 0x8D42;
	public static inline final RENDERBUFFER_HEIGHT = 0x8D43;
	public static inline final RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
	public static inline final RENDERBUFFER_RED_SIZE = 0x8D50;
	public static inline final RENDERBUFFER_GREEN_SIZE = 0x8D51;
	public static inline final RENDERBUFFER_BLUE_SIZE = 0x8D52;
	public static inline final RENDERBUFFER_ALPHA_SIZE = 0x8D53;
	public static inline final RENDERBUFFER_DEPTH_SIZE = 0x8D54;
	public static inline final RENDERBUFFER_STENCIL_SIZE = 0x8D55;

	public static inline final FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
	public static inline final FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
	public static inline final FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
	public static inline final FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;

	public static inline final COLOR_ATTACHMENT0 = 0x8CE0;
	public static inline final DEPTH_ATTACHMENT = 0x8D00;
	public static inline final STENCIL_ATTACHMENT = 0x8D20;
	public static inline final DEPTH_STENCIL_ATTACHMENT = 0x821A;

	public static inline final NONE = 0;

	public static inline final FRAMEBUFFER_COMPLETE = 0x8CD5;
	public static inline final FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
	public static inline final FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
	public static inline final FRAMEBUFFER_INCOMPLETE_DIMENSIONS = 0x8CD9;
	public static inline final FRAMEBUFFER_UNSUPPORTED = 0x8CDD;

	public static inline final FRAMEBUFFER_BINDING = 0x8CA6;
	public static inline final RENDERBUFFER_BINDING = 0x8CA7;
	public static inline final MAX_RENDERBUFFER_SIZE = 0x84E8;

	public static inline final INVALID_FRAMEBUFFER_OPERATION = 0x0506;

	// WebGL-specific enums
	public static inline final UNPACK_FLIP_Y_WEBGL = 0x9240;
	public static inline final UNPACK_PREMULTIPLY_ALPHA_WEBGL = 0x9241;
	public static inline final CONTEXT_LOST_WEBGL = 0x9242;
	public static inline final UNPACK_COLORSPACE_CONVERSION_WEBGL = 0x9243;
	public static inline final BROWSER_DEFAULT_WEBGL = 0x9244;

	// Queries
	public static inline final SAMPLES_PASSED = 0x8914;
	public static inline final TIMESTAMP = 0x8E28;
	public static inline final TIME_ELAPSED = 0x88BF;

	// Barriers
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
