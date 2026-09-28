package limen.platform.input.touch;

import haxe.Int64;
import limen.platform.Platform;
import limen.platform.internal.SdlBindings;

class Touch {
	public final id:Int64;
	public var name(get, never):String;
	public var type(get, never):TouchDeviceType;

	public static function available():Array<Int64> {
		final ids = SdlBindings.getTouchDevices();
		return ids == null ? [] : [for (id in ids) id];
	}

	public function new(id:Int64) {
		this.id = id;
	}

	public function fingers():Array<Finger> {
		final fingers = SdlBindings.getTouchFingers(id);
		if (fingers == null)
			throw 'Failed to get touch fingers (${Platform.getError()})';
		return [for (finger in fingers) finger];
	}

	@:noCompletion
	inline function get_name():String {
		final value = SdlBindings.getTouchDeviceName(id);
		return value == null ? "" : @:privateAccess String.fromUTF8(value);
	}

	@:noCompletion
	inline function get_type():TouchDeviceType {
		return SdlBindings.getTouchDeviceType(id);
	}
}
