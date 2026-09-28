package limen.platform.cursor;

import limen.platform.Surface;
import limen.platform.internal.SDLBindings;
import limen.platform.internal.types.CursorPtr;

abstract Cursor(CursorPtr) {
	public static function create(surface:Surface, hotX:Int, hotY:Int):Cursor {
		return cast SDLBindings.cursorCreate(cast surface, hotX, hotY);
	}

	public static function createSystem(kind:CursorKind):Cursor {
		return cast SDLBindings.cursorCreateSystem(cast kind);
	}

	public inline function free() {
		destroy();
	}

	public inline function destroy() {
		SDLBindings.freeCursor(this);
		this = null;
	}

	public function set() {
		SDLBindings.setCursor(this);
	}

	public static inline function show(visible:Bool) {
		SDLBindings.showCursor(visible);
	}

	public static inline function isVisible():Bool {
		return SDLBindings.isCursorVisible();
	}
}
