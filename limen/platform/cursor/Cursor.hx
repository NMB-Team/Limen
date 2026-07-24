package limen.platform.cursor;

import limen.platform.Surface;
import limen.platform.internal.SdlBindings;
import limen.platform.internal.NativeTypes.CursorPtr;

abstract Cursor(CursorPtr) {
	public static function create(surface:Surface, hotX:Int, hotY:Int):Cursor {
		return cast SdlBindings.cursorCreate(cast surface, hotX, hotY);
	}

	public static function createSystem(kind:CursorKind):Cursor {
		return cast SdlBindings.cursorCreateSystem(cast kind);
	}

	public inline function free() {
		destroy();
	}

	public inline function destroy() {
		SdlBindings.freeCursor(this);
		this = null;
	}

	public function set() {
		SdlBindings.setCursor(this);
	}

	public static inline function show(visible:Bool) {
		SdlBindings.showCursor(visible);
	}

	public static inline function isVisible():Bool {
		return SdlBindings.isCursorVisible();
	}
}
