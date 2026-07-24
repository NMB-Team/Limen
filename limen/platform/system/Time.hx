package limen.platform.system;

import limen.platform.internal.SdlBindings;

class Time {
	public static inline function now():Float {
		return SdlBindings.getTime();
	}

	public static function delay(milliseconds:Int):Void {
		if (milliseconds > 0)
			SdlBindings.delay(milliseconds);
	}
}
