package limen.platform.system;

import haxe.Int64;

import limen.platform.internal.SdlBindings;

class Time {
	/**
		Milliseconds elapsed since timer initialization.
	**/
	public static var ticks(get, never):Int64;

	/**
		High-resolution counter; only differences between readings are meaningful.
	**/
	public static var performanceCounter(get, never):Int64;

	/**
		High-resolution counter ticks per second.
	**/
	public static var performanceFrequency(get, never):Int64;

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

	@:noCompletion
	static inline function get_ticks():Int64 {
		return SdlBindings.getTicks();
	}

	@:noCompletion
	static inline function get_performanceCounter():Int64 {
		return SdlBindings.getPerformanceCounter();
	}

	@:noCompletion
	static inline function get_performanceFrequency():Int64 {
		return SdlBindings.getPerformanceFrequency();
	}
}
