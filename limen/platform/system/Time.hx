package limen.platform.system;

import haxe.Int64;

import limen.platform.internal.SdlBindings;

class Time {
	public static inline function now():Float {
		return SdlBindings.getTime();
	}

	public static inline function timestamp():Int64 {
		return SdlBindings.getTimestamp();
	}

	public static function delay(milliseconds:Int):Void {
		if (milliseconds > 0)
			SdlBindings.delay(milliseconds);
	}
}
