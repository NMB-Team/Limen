package limen.graphics.renderer.opengl.internal;

import limen.platform.internal.types.WinPtr;

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
	public static function swapWindow(window:WinPtr):Bool {
		return false;
	}

	@:hlNative("limen", "opengl_gl_options")
	public static function configureContext(major:Int, minor:Int, depth:Int, stencil:Int, flags:Int, samples:Int):Bool {
		return false;
	}

	@:hlNative("limen", "opengl_gl_context_info")
	public static function getContextInfo():hl.Bytes {
		return null;
	}

	@:hlNative("limen", "opengl_set_swap_interval")
	public static function setSwapInterval(interval:Int):Bool {
		return false;
	}

	public static function init():Bool {
		return false;
	}
}
