package limen.platform.event;

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
		Monotonic timestamp of the native SDL event, in seconds.

		The value originates from SDL_Event.common.timestamp and shares the
		SDL_GetTicksNS() clock domain with Platform.getTime(). It is unrelated to
		wall-clock time and is not necessarily the hardware interrupt time.
	**/
	public var timestamp:Float;

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
}
