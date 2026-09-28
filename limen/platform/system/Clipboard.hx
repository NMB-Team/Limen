package limen.platform.system;

import haxe.io.Bytes;
import limen.platform.internal.SdlBindings;

class Clipboard {
	public static function setText(text:String):Bool {
		return text != null && @:privateAccess SdlBindings.setClipboardText(text.toUtf8());
	}

	public static function getText():String {
		final text = SdlBindings.getClipboardText();
		return text == null ? null : @:privateAccess String.fromUTF8(text);
	}

	public static function hasText():Bool {
		return SdlBindings.hasClipboardText();
	}

	public static function hasData(mimeType:String):Bool {
		return mimeType != null && mimeType.length > 0 && mimeType.indexOf("\x00") < 0
			&& @:privateAccess SdlBindings.hasClipboardData(mimeType.toUtf8());
	}

	public static function getData(mimeType:String):Bytes {
		if (mimeType == null || mimeType.length == 0 || mimeType.indexOf("\x00") >= 0)
			return null;
		var size = 0;
		final data = @:privateAccess SdlBindings.getClipboardData(mimeType.toUtf8(), size);
		return data == null ? null : data.toBytes(size);
	}

	public static function setData(mimeType:String, data:Bytes):Bool {
		return mimeType != null && mimeType.length > 0 && mimeType.indexOf("\x00") < 0 && data != null
			&& @:privateAccess SdlBindings.setClipboardData(mimeType.toUtf8(), hl.Bytes.fromBytes(data), data.length);
	}

	public static function mimeTypes():Array<String> {
		final types = SdlBindings.getClipboardMimeTypes();
		return types == null ? [] : [for (index in 0...types.length) @:privateAccess String.fromUTF8(types[index])];
	}
}
