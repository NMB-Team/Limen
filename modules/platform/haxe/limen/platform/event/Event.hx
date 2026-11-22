package limen.platform.event;

import haxe.Int64;
import limen.platform.input.pen.PenAxis;
import limen.platform.input.pen.PenInputFlags;

@:keep
class Event {
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

	public var touchId:Int64;
	public var fingerId:Int64;
	/** Normalized touch coordinates, movement and pressure. **/
	public var touchX:Float;
	public var touchY:Float;
	public var touchDX:Float;
	public var touchDY:Float;
	public var pressure:Float;
	public var penId:Int;
	public var penState:PenInputFlags;
	/** Pen coordinates in window units; valid for motion, tip, button and axis events. **/
	public var penX:Float;
	public var penY:Float;
	/** The changed axis and its value, valid only for PenAxis events. **/
	public var penAxis:PenAxis;
	public var penValue:Float;
	/** Whether the eraser tip is used, valid only for PenDown and PenUp. **/
	public var penEraser:Bool;

	/**
		Convenience conversion for display and simple gameplay use.

		For precise timing differences, subtract Int64 nanosecond timestamps first,
		then convert the resulting delta to milliseconds.
	**/
	public var timestampMs(get, never):Float;

	// for compile-time backward compatibility
	public var controller(get, never):Int;
	public var joystick(get, never):Int;

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
	inline function get_timestampMs():Float { // haxe 4 fix
		final high = timestamp.high;
		final low = timestamp.low;
		final value = high * 4294967296.0 + (low < 0 ? 4294967296.0 + low : low);
		return value * 0.000001;
	}
}
