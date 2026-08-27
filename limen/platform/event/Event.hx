package limen.platform.event;

import haxe.Int64;

@:keep class Event {
	public var type:EventType;
	public var mouseX:Int;
	public var mouseY:Int;
	public var mouseXRel:Int;
	public var mouseYRel:Int;
	public var button:Int;
	public var wheelDelta:Int;
	public var state:WindowStateChange;
	public var keyCode:Int;
	public var scanCode:Int;
	public var modifier:Int;
	public var keyRepeat:Bool;
	public var reference:Int;
	public var value:Int;
	public var __unused:Int;
	public var windowId:Int;
	public var dropFile:hl.Bytes;
	public var inputChar:hl.Bytes;

	/**
		Monotonic timestamp of the native SDL event, in nanoseconds.

		The value originates from SDL_Event.common.timestamp and shares the
		SDL_GetTicksNS() clock domain with Platform.getTimestamp(). It is intended
		for comparing timestamps and durations, not as wall-clock or Unix time.
	**/
	public var timestamp:Int64;

	/**
		Convenience conversion for display and simple gameplay use.

		For precise timing differences, subtract Int64 nanosecond timestamps first,
		then convert the resulting delta to milliseconds.
	**/
	public var timestampMs(get, never):Float;

	// for compile-time backward compatibility
	public var controller(get, never):Int;
	public var joystick(get, never):Int;
	public var fingerId(get, never):Int;

	public function new() {}

	@:noCompletion
	inline function get_controller() {
		return reference;
	}

	@:noCompletion
	inline function get_joystick() {
		return reference;
	}

	@:noCompletion
	inline function get_fingerId() {
		return reference;
	}

	@:noCompletion
	inline function get_timestampMs():Float {
		return timestamp.toFloat() / 1_000_000.0;
	}
}
