package limen.platform.system;

import limen.platform.internal.SdlBindings;

class MessageBox {
	public static function show(title:String, text:String, icon:MessageBoxIcon = None):Void {
		@:privateAccess SdlBindings.messageBox(title.toUtf8(), text.toUtf8(), cast icon);
	}
}
