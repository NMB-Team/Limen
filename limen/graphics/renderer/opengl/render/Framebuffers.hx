package limen.graphics.renderer.opengl.render;

import limen.graphics.renderer.opengl.resource.Textures.Texture;

abstract Framebuffer(Null<Int>) {}
abstract Renderbuffer(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class Framebuffers {
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

	public static function createRenderbuffer():Renderbuffer {
		return null;
	}

	public static function bindRenderbuffer(target:Int, r:Renderbuffer) {}

	public static function renderbufferStorage(target:Int, format:Int, width:Int, height:Int) {}

	public static function renderbufferStorageMultisample(target:Int, samples:Int, format:Int, width:Int, height:Int) {}

	public static function framebufferRenderbuffer(frameTarget:Int, attach:Int, renderTarget:Int, b:Renderbuffer) {}

	public static function deleteRenderbuffer(b:Renderbuffer) {}

	public static inline final FRAMEBUFFER = 0x8D40;
	public static inline final RENDERBUFFER = 0x8D41;
	public static inline final READ_FRAMEBUFFER = 0x8CA8;
	public static inline final DRAW_FRAMEBUFFER = 0x8CA9;
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
}
