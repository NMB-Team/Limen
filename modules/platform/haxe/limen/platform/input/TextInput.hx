package limen.platform.input;

import limen.platform.internal.SDLBindings;

class TextInput {
	public static inline function isShown():Bool {
		return SDLBindings.isTextInputShown();
	}
}
