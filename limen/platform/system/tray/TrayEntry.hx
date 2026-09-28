package limen.platform.system.tray;

import limen.platform.Platform;
import limen.platform.internal.SdlBindings;
import limen.platform.internal.types.TrayEntryPtr;

/**
	An owned menu entry.
	Removed entries and their submenus cannot be reused.
**/
class TrayEntry {
	public var label(get, set):Null<String>;
	public var enabled(get, set):Bool;
	public var checked(get, set):Bool;
	public var isCheckbox(default, null):Bool;
	public var isSeparator(default, null):Bool;
	public var submenu(default, null):Null<TrayMenu>;

	var handle:TrayEntryPtr;
	var menu:TrayMenu;
	var callback:Bool -> Void;
	var callbackId = 0;

	@:allow(limen.platform.system.tray.TrayMenu)
	private function new(handle:TrayEntryPtr, menu:TrayMenu, isCheckbox:Bool, isSeparator:Bool) {
		this.handle = handle;
		this.menu = menu;
		this.isCheckbox = isCheckbox;
		this.isSeparator = isSeparator;
	}

	public function remove():Void {
		if (handle == null)
			return;
		final nativeEntry = handle;
		menu.remove(this);
		invalidate();
		SdlBindings.trayRemoveEntry(nativeEntry);
	}

	@:allow(limen.platform.system.tray.TrayMenu)
	private function createSubmenu():TrayMenu {
		final nativeMenu = SdlBindings.trayCreateSubmenu(handle);
		if (nativeMenu == null)
			throw 'Failed to create tray submenu (${Platform.getError()})';
		submenu = new TrayMenu(nativeMenu, null, this);
		return submenu;
	}

	@:allow(limen.platform.system.tray.TrayMenu)
	private function setCallback(callback:Bool -> Void):Void {
		this.callback = callback;
		if (callback != null) {
			callbackId = Tray.register(this);
			SdlBindings.traySetEntryCallback(handle, callbackId, isCheckbox);
		}
	}

	@:allow(limen.platform.system.tray)
	private function invalidate():Void {
		submenu?.invalidate();

		if (callbackId != 0) {
			SdlBindings.traySetEntryCallback(handle, 0, isCheckbox);
			Tray.unregister(callbackId);
			callbackId = 0;
		}

		callback = null;
		submenu = null;
		menu = null;
		handle = null;
	}

	@:allow(limen.platform.system.tray.Tray)
	private function invoke(checked:Bool):Void {
		callback(checked);
	}

	@:noCompletion
	private function requireAlive():Void {
		if (handle == null)
			throw "Tray entry has been removed";
	}

	@:noCompletion
	private function get_label():Null<String> {
		requireAlive();
		final value = SdlBindings.trayGetEntryLabel(handle);
		return value == null ? null : @:privateAccess String.fromUTF8(value);
	}

	@:noCompletion
	private function set_label(value:Null<String>):Null<String> {
		requireAlive();
		if (isSeparator || value == null)
			throw "Cannot change an entry into or from a separator";
		SdlBindings.traySetEntryLabel(handle, @:privateAccess value.toUtf8());
		return value;
	}

	@:noCompletion
	private function get_enabled():Bool {
		requireAlive();
		return SdlBindings.trayGetEntryEnabled(handle);
	}

	@:noCompletion
	private function set_enabled(value:Bool):Bool {
		requireAlive();
		SdlBindings.traySetEntryEnabled(handle, value);
		return value;
	}

	@:noCompletion
	private function get_checked():Bool {
		requireAlive();
		if (!isCheckbox)
			throw "Tray entry is not a checkbox";
		return SdlBindings.trayGetEntryChecked(handle);
	}

	@:noCompletion
	private function set_checked(value:Bool):Bool {
		requireAlive();
		if (!isCheckbox)
			throw "Tray entry is not a checkbox";
		SdlBindings.traySetEntryChecked(handle, value);
		return value;
	}
}
