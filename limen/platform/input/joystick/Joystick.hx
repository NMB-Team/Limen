package limen.platform.input.joystick;

import limen.platform.Platform;
import limen.platform.internal.SdlBindings;
import limen.platform.internal.NativeTypes.JoystickPtr;

class Joystick {
	var ptr:JoystickPtr;

	public var id(get, never):Int;
	public var name(get, never):String;
	public var isOpen(get, never):Bool;

	public static function available():Array<Int> {
		final ids = SdlBindings.getJoysticks();
		return ids == null ? [] : [for (id in ids) id];
	}

	public static inline function count():Int {
		return SdlBindings.joyCount();
	}

	public function new(id:Int) {
		ptr = SdlBindings.joyOpen(id);
		if (ptr == null)
			throw 'Failed to open joystick $id (${Platform.getError()})';
	}

	public inline function getAxis(axisId:Int) {
		return SdlBindings.joyGetAxis(ptr, axisId);
	}

	public inline function getHat(hatId:Int) {
		return SdlBindings.joyGetHat(ptr, hatId);
	}

	public inline function getButton(btnId:Int) {
		return SdlBindings.joyGetButton(ptr, btnId);
	}

	public function close() {
		destroy();
	}

	public function destroy() {
		if (ptr == null)
			return;
		SdlBindings.joyClose(ptr);
		ptr = null;
	}

	@:noCompletion
	inline function get_id():Int {
		return SdlBindings.joyGetId(ptr);
	}

	@:noCompletion
	inline function get_name():String {
		final value = SdlBindings.joyGetName(ptr);
		return value == null ? "" : @:privateAccess String.fromUTF8(value);
	}

	@:noCompletion
	inline function get_isOpen():Bool {
		return ptr != null;
	}
}
