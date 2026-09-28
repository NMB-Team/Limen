package limen.platform.system.tray;

import limen.platform.Platform;
import limen.platform.Surface;
import limen.platform.internal.SdlBindings;
import limen.platform.internal.types.TrayPtr;

/**
	A system tray icon.
	Use on the main thread after Platform.init().
**/
class Tray {
	public var menu(default, null):Null<TrayMenu>;

	static final trays:Array<Tray> = [];

	// this registry keeps callback closures alive until their entries are removed
	static final callbacks:Map<Int, TrayEntry> = [];
	static var nextCallbackId = 1;

	var handle:TrayPtr;

	private function new(handle:TrayPtr) {
		this.handle = handle;
		trays.push(this);
	}

	public static function create(icon:Surface, ?tooltip:String):Tray {
		final handle = SdlBindings.trayCreate(cast icon, tooltip == null ? null : @:privateAccess tooltip.toUtf8());
		if (handle == null)
			throw 'Failed to create tray (${Platform.getError()})';
		return new Tray(handle);
	}

	public function setIcon(icon:Surface):Void {
		requireAlive();
		SdlBindings.traySetIcon(handle, cast icon);
	}

	public function setTooltip(tooltip:String):Void {
		requireAlive();
		SdlBindings.traySetTooltip(handle, tooltip == null ? null : @:privateAccess tooltip.toUtf8());
	}

	public function createMenu():TrayMenu {
		requireAlive();
		if (menu == null) {
			final nativeMenu = SdlBindings.trayCreateMenu(handle);
			if (nativeMenu == null)
				throw 'Failed to create tray menu (${Platform.getError()})';
			menu = new TrayMenu(nativeMenu, this, null);
		}
		return menu;
	}

	public function destroy():Void {
		if (handle == null)
			return;

		menu?.invalidate();

		SdlBindings.trayDestroy(handle);
		handle = null;
		menu = null;
		trays.remove(this);
	}

	/**
		Pump trays and dispatch callbacks when not using Platform.pollEvent().
	**/
	public static function update():Void {
		SdlBindings.trayUpdate();
		dispatchCallbacks();
	}

	private function requireAlive():Void {
		if (handle == null)
			throw "Tray has been destroyed";
	}

	@:allow(limen.platform.system.tray.TrayEntry)
	static function register(entry:TrayEntry):Int {
		if (nextCallbackId == 0x7FFFFFFF)
			throw "Too many tray callbacks";
		final id = nextCallbackId++;
		callbacks.set(id, entry);
		return id;
	}

	@:allow(limen.platform.system.tray.TrayEntry)
	static function unregister(id:Int):Void {
		callbacks.remove(id);
	}

	@:allow(limen.platform.Platform)
	static function dispatchCallbacks():Void {
		var checked = false;
		while (true) {
			final id = SdlBindings.trayPollCallback(checked);
			if (id == 0)
				break;
			final entry = callbacks.get(id);
			if (entry != null)
				entry.invoke(checked);
		}
	}

	@:allow(limen.platform.Platform)
	static function destroyAll():Void {
		while (trays.length > 0)
			trays[trays.length - 1].destroy();
	}

	@:allow(limen.platform.system.tray.TrayMenu)
	private function releaseMenu():Void {
		menu = null;
	}
}
