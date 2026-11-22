package limen.input;

import limen.internal.SDLBindings;

class Keyboard {
	public static function layout():String {
		final layout = SDLBindings.detectKeyboardLayout();
		return layout == null ? null : @:privateAccess String.fromUTF8(layout);
	}
}
