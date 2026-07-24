package limen.platform.system;

import limen.platform.internal.SdlBindings;

class Clipboard {
	public static function setText(text:String):Bool {
		return text != null && @:privateAccess SdlBindings.setClipboardText(text.toUtf8());
	}

	public static function getText():String {
		final text = SdlBindings.getClipboardText();
		return text == null ? null : @:privateAccess String.fromUTF8(text);
	}
}
