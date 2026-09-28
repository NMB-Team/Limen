package limen.platform.input.joystick;

import limen.platform.Platform;
import limen.platform.internal.SDLBindings;
import limen.platform.internal.types.JoystickPtr;

class Joystick {
	var ptr:JoystickPtr;

	public var id(get, never):Int;
	public var name(get, never):String;
	public var isOpen(get, never):Bool;

	public static function available():Array<Int> {
		final ids = SDLBindings.getJoysticks();
		return ids == null ? [] : [for (id in ids) id];
	}

	public static inline function count():Int {
		return SDLBindings.joyCount();
	}

	public function new(id:Int) {
		ptr = SDLBindings.joyOpen(id);
		if (ptr == null)
			throw 'Failed to open joystick $id (${Platform.getError()})';
	}

	public inline function getAxis(axisId:Int) {
		return SDLBindings.joyGetAxis(ptr, axisId);
	}

	public inline function getHat(hatId:Int) {
		return SDLBindings.joyGetHat(ptr, hatId);
	}

	public inline function getButton(btnId:Int) {
		return SDLBindings.joyGetButton(ptr, btnId);
	}

	public function close() {
		destroy();
	}

	public function destroy() {
		if (ptr == null)
			return;
		SDLBindings.joyClose(ptr);
		ptr = null;
	}

	@:noCompletion
	inline function get_id():Int {
		return SDLBindings.joyGetId(ptr);
	}

	@:noCompletion
	inline function get_name():String {
		final value = SDLBindings.joyGetName(ptr);
		return value == null ? "" : @:privateAccess String.fromUTF8(value);
	}

	@:noCompletion
	inline function get_isOpen():Bool {
		return ptr != null;
	}
}
