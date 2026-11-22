package limen.input;

import limen.internal.SDLBindings;

class TextInput {
	public static inline function isShown():Bool {
		return SDLBindings.isTextInputShown();
	}
}
