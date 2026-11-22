package limen.platform.input;

import limen.platform.internal.SDLBindings;

class Mouse {
	public static inline function setRelative(enabled:Bool):Int {
		return SDLBindings.setRelativeMouseMode(enabled);
	}

	public static inline function isRelative():Bool {
		return SDLBindings.getRelativeMouseMode();
	}

	public static inline function globalState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return SDLBindings.getGlobalMouseState(x, y);
	}

	public static inline function relativeState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return SDLBindings.getRelativeMouseState(x, y);
	}

	public static inline function warpGlobal(x:Int, y:Int):Int {
		return SDLBindings.warpMouseGlobal(x, y);
	}

	public static inline function setMotionEvents(enabled:Bool):Void {
		SDLBindings.setMouseMotionEvents(enabled);
	}

	public static inline function capture(enabled:Bool):Int {
		return SDLBindings.captureMouse(enabled);
	}
}
