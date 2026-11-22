package limen.system.dialog;

import limen.internal.SDLBindings;

class MessageBox {
	public static function show(title:String, text:String, icon:MessageBoxIcon = None):Void {
		@:privateAccess SDLBindings.messageBox(title.toUtf8(), text.toUtf8(), cast icon);
	}
}
