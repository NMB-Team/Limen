package limen.platform.system.tray;

import limen.platform.Platform;
import limen.platform.internal.SDLBindings;
import limen.platform.internal.types.TrayMenuPtr;

/**
	A menu owned by a tray or submenu entry.
	All operations use the main thread.
**/
class TrayMenu {
	public var parentEntry(default, null):Null<TrayEntry>;

	var handle:TrayMenuPtr;
	var tray:Tray;
	final entries:Array<TrayEntry> = [];

	@:allow(limen.platform.system.tray)
	private function new(handle:TrayMenuPtr, tray:Tray, parent:TrayEntry) {
		this.handle = handle;
		this.tray = tray;
		this.parentEntry = parent;
	}

	public function add(label:String, ?callback:Void -> Void):TrayEntry {
		if (label == null)
			throw "Tray entry label cannot be null";
		return insert(label, 1, false, callback == null ? null : _ -> callback());
	}

	public function addCheck(label:String, checked:Bool, ?callback:Bool -> Void):TrayEntry {
		if (label == null)
			throw "Tray entry label cannot be null";
		return insert(label, 2, checked, callback);
	}

	public function addSeparator():TrayEntry {
		return insert(null, 1, false, null);
	}

	public function addSubmenu(label:String):TrayMenu {
		if (label == null)
			throw "Tray entry label cannot be null";

		final entry = insert(label, 4, false, null);
		try {
			return entry.createSubmenu();
		} catch (error:Dynamic) {
			entry.remove();
			throw error;
		}
	}

	public function clear():Void {
		requireAlive();
		while (entries.length > 0)
			entries[entries.length - 1].remove();
	}

	public function destroy():Void {
		if (handle == null)
			return;

		if (parentEntry != null)
			parentEntry.remove();
		else {
			clear();
			tray.releaseMenu();
			invalidate();
		}
	}

	private function insert(label:String, kind:Int, checked:Bool, callback:Bool -> Void):TrayEntry {
		requireAlive();
		final nativeEntry = SDLBindings.trayInsertEntry(handle, label == null ? null : @:privateAccess label.toUtf8(), kind, checked);
		if (nativeEntry == null)
			throw 'Failed to create tray entry (${Platform.getError()})';
		final entry = new TrayEntry(nativeEntry, this, kind == 2, label == null);
		entries.push(entry);
		entry.setCallback(callback);
		return entry;
	}

	private function requireAlive():Void {
		if (handle == null)
			throw "Tray menu has been destroyed";
	}

	@:allow(limen.platform.system.tray)
	private function invalidate():Void {
		for (entry in entries)
			entry.invalidate();
		entries.resize(0);
		handle = null;
		tray = null;
		parentEntry = null;
	}

	@:allow(limen.platform.system.tray.TrayEntry)
	private function remove(entry:TrayEntry):Void {
		entries.remove(entry);
	}
}
