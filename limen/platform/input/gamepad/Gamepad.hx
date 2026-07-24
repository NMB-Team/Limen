package limen.platform.input.gamepad;

import limen.platform.Platform;
import limen.platform.internal.SdlBindings;
import limen.platform.internal.NativeTypes.GamepadPtr;

class Gamepad {
	var ptr:GamepadPtr;

	public var id(get, never):Int;
	public var name(get, never):String;
	public var isOpen(get, never):Bool;

	public static inline function count():Int {
		return SdlBindings.gctrlCount();
	}

	public function new(id:Int) {
		ptr = SdlBindings.gctrlOpen(id);
		if (ptr == null)
			throw 'Failed to open gamepad $id (${Platform.getError()})';
	}

	public inline function getAxis(axis:Int):Int {
		return SdlBindings.gctrlGetAxis(ptr, axis);
	}

	public inline function getButton(button:Int):Bool {
		return SdlBindings.gctrlGetButton(ptr, button);
	}

	public function rumble(strength:Float, duration:Int):Bool {
		return SdlBindings.gctrlRumble(ptr, strength, duration);
	}

	public function close() {
		destroy();
	}

	public function destroy() {
		if (ptr == null)
			return;
		SdlBindings.gctrlClose(ptr);
		ptr = null;
	}

	inline function get_id():Int {
		return SdlBindings.gctrlGetId(ptr);
	}

	inline function get_name():String {
		final value = SdlBindings.gctrlGetName(ptr);
		return value == null ? "" : @:privateAccess String.fromUTF8(value);
	}

	inline function get_isOpen():Bool {
		return ptr != null;
	}
}
