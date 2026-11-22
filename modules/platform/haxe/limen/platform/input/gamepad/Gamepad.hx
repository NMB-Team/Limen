package limen.platform.input.gamepad;

import limen.platform.Platform;
import limen.platform.internal.SDLBindings;
import limen.platform.internal.types.GamepadPtr;

class Gamepad {
	var ptr:GamepadPtr;

	public var id(get, never):Int;
	public var name(get, never):String;
	public var isOpen(get, never):Bool;

	public static inline function count():Int {
		return SDLBindings.gctrlCount();
	}

	public function new(id:Int) {
		ptr = SDLBindings.gctrlOpen(id);
		if (ptr == null)
			throw 'Failed to open gamepad $id (${Platform.getError()})';
	}

	public inline function getAxis(axis:Int):Int {
		return SDLBindings.gctrlGetAxis(ptr, axis);
	}

	public inline function getButton(button:Int):Bool {
		return SDLBindings.gctrlGetButton(ptr, button);
	}

	public function rumble(strength:Float, duration:Int):Bool {
		return SDLBindings.gctrlRumble(ptr, strength, duration);
	}

	public function close() {
		destroy();
	}

	public function destroy() {
		if (ptr == null)
			return;
		SDLBindings.gctrlClose(ptr);
		ptr = null;
	}

	@:noCompletion
	inline function get_id():Int {
		return SDLBindings.gctrlGetId(ptr);
	}

	@:noCompletion
	inline function get_name():String {
		final value = SDLBindings.gctrlGetName(ptr);
		return value == null ? "" : @:privateAccess String.fromUTF8(value);
	}

	@:noCompletion
	inline function get_isOpen():Bool {
		return ptr != null;
	}
}
