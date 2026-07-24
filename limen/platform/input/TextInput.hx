package limen.platform.input;

import limen.platform.internal.SdlBindings;

class TextInput {
	public static inline function isShown():Bool {
		return SdlBindings.isTextInputShown();
	}
}
