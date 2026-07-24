package limen.platform.input;

import limen.platform.internal.SdlBindings;

class Keyboard {
	public static function layout():String {
		final layout = SdlBindings.detectKeyboardLayout();
		return layout == null ? null : @:privateAccess String.fromUTF8(layout);
	}
}
