package limen.platform.input;

import limen.platform.internal.SdlBindings;

class Mouse {
	public static inline function setRelative(enabled:Bool):Int {
		return SdlBindings.setRelativeMouseMode(enabled);
	}

	public static inline function isRelative():Bool {
		return SdlBindings.getRelativeMouseMode();
	}

	public static inline function globalState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return SdlBindings.getGlobalMouseState(x, y);
	}

	public static inline function relativeState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return SdlBindings.getRelativeMouseState(x, y);
	}

	public static inline function warpGlobal(x:Int, y:Int):Int {
		return SdlBindings.warpMouseGlobal(x, y);
	}

	public static inline function setMotionEvents(enabled:Bool):Void {
		SdlBindings.setMouseMotionEvents(enabled);
	}

	public static inline function capture(enabled:Bool):Int {
		return SdlBindings.captureMouse(enabled);
	}
}
