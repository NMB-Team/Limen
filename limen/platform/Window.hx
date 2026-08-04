package limen.platform;

import limen.platform.Platform.DisplayId;
import limen.platform.internal.SdlBindings;

typedef WinPtr = hl.Abstract<"limen_window">;

enum abstract WindowMode(Int) {
	final Windowed = 0;
	final Fullscreen = 1;
	final BorderlessFixed = 2;
	final Borderless = 3;
}

typedef DisplaySetting = {
	var width:Int;
	var height:Int;
	var framerate:Int;
}

class Window {
	public static inline final SDL_WINDOWPOS_UNDEFINED = 0x1FFF0000;
	public static inline final SDL_WINDOWPOS_CENTERED = 0x2FFF0000;

	public static inline final SDL_WINDOW_FULLSCREEN = 0x00000001;
	public static inline final SDL_WINDOW_OPENGL = 0x00000002;
	public static inline final SDL_WINDOW_OCCLUDED = 0x00000004;
	public static inline final SDL_WINDOW_HIDDEN = 0x00000008;
	public static inline final SDL_WINDOW_BORDERLESS = 0x00000010;
	public static inline final SDL_WINDOW_RESIZABLE = 0x00000020;
	public static inline final SDL_WINDOW_MINIMIZED = 0x00000040;
	public static inline final SDL_WINDOW_MAXIMIZED = 0x00000080;
	public static inline final SDL_WINDOW_MOUSE_GRABBED = 0x00000100;
	public static inline final SDL_WINDOW_INPUT_FOCUS = 0x00000200;
	public static inline final SDL_WINDOW_MOUSE_FOCUS = 0x00000400;
	public static inline final SDL_WINDOW_FOREIGN = 0x00000800;
	public static inline final SDL_WINDOW_MODAL = 0x00001000;
	public static inline final SDL_WINDOW_ALLOW_HIGHDPI = 0x00002000;
	public static inline final SDL_WINDOW_MOUSE_CAPTURE = 0x00004000;
	public static inline final SDL_WINDOW_ALWAYS_ON_TOP = 0x00010000;
	public static inline final SDL_WINDOW_UTILITY = 0x00020000;
	public static inline final SDL_WINDOW_TOOLTIP = 0x00040000;
	public static inline final SDL_WINDOW_POPUP_MENU = 0x00080000;
	public static inline final SDL_WINDOW_VULKAN = 0x10000000;
	public static inline final SDL_WINDOW_METAL = 0x20000000;

	public static inline final SDL_WINDOW_SHOWN = 0x00000004;
	public static inline final SDL_WINDOW_INPUT_GRABBED = 0x00000100;
	public static inline final SDL_WINDOW_SKIP_TASKBAR = 0x00020000;

	public var id(get, never):Int;
	public var nativeHandle(get, never):WinPtr;
	public var title(default, set):String;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var windowToPixelRatio(get, never):Float;
	public var minWidth(get, never):Int;
	public var minHeight(get, never):Int;
	public var maxWidth(get, never):Int;
	public var maxHeight(get, never):Int;
	public var x(get, never):Int;
	public var y(get, never):Int;
	public var displayMode(default, set):WindowMode;
	public var displaySetting:DisplaySetting;
	public var currentMonitor(get, never):DisplayId;
	public var visible(default, set):Bool = true;
	public var opacity(get, set):Float;
	public var grab(get, set):Bool;
	public var displayScale(get, never):Float;

	static var windows:Array<Window> = [];

	var win:WinPtr;

	public static function create(options:WindowOptions):Window {
		var flags = options.flags ?? 0;
		if (options.resizable != false)
			flags |= SDL_WINDOW_RESIZABLE;
		if (options.visible == false)
			flags |= SDL_WINDOW_HIDDEN;
		return new Window(options.title, options.width, options.height, options.x ?? SDL_WINDOWPOS_CENTERED, options.y ?? SDL_WINDOWPOS_CENTERED, flags);
	}

	public function new(title:String, width:Int, height:Int, x:Int = SDL_WINDOWPOS_CENTERED, y:Int = SDL_WINDOWPOS_CENTERED, flags:Int = SDL_WINDOW_RESIZABLE) {
		win = SdlBindings.winCreateEx(x, y, width, height, flags);
		if (win == null)
			throw "Failed to create window (" + getNativeError() + ")";
		this.title = title;
		visible = (flags & SDL_WINDOW_HIDDEN) == 0;
		windows.push(this);
	}

	public inline function setIcon(surface:Surface):Void {
		SdlBindings.winSetIcon(win, cast surface);
	}

	public inline function resize(width:Int, height:Int):Void {
		SdlBindings.winSetSize(win, width, height);
	}

	public inline function setMinSize(width:Int, height:Int):Void {
		SdlBindings.winSetMinSize(win, width, height);
	}

	public inline function setMaxSize(width:Int, height:Int):Void {
		SdlBindings.winSetMaxSize(win, width, height);
	}

	public inline function setDisplayMode(width:Int, height:Int, framerate:Int):Bool {
		return SdlBindings.winSetDisplayMode(win, width, height, framerate);
	}

	public inline function setPosition(x:Int, y:Int):Void {
		SdlBindings.winSetPosition(win, x, y);
	}

	public inline function center(centerPrimary:Bool = true):Void {
		SdlBindings.winCenter(win, centerPrimary);
	}

	public inline function show():Void {
		visible = true;
	}

	public inline function hide():Void {
		visible = false;
	}

	public inline function raise():Void {
		SdlBindings.winRaise(win);
	}

	public inline function setDarkMode(enabled:Bool):Bool {
		return SdlBindings.winSetDarkMode(win, enabled);
	}

	public inline function warpMouse(x:Int, y:Int):Void {
		SdlBindings.warpMouseInWindow(win, x, y);
	}

	public inline function captureMouseEvents(enable:Bool):Int {
		return SdlBindings.captureMouse(enable);
	}

	public function destroy():Void {
		if (win == null)
			return;
		SdlBindings.windowDestroy(win);
		win = null;
		windows.remove(this);
	}

	public inline function maximize():Void {
		SdlBindings.winResize(win, 0);
	}

	public inline function minimize():Void {
		SdlBindings.winResize(win, 1);
	}

	public inline function restore():Void {
		SdlBindings.winResize(win, 2);
	}

	public inline function setAlwaysOnTop(enabled:Bool):Bool {
		return SdlBindings.winSetAlwaysOnTop(win, enabled);
	}

	@:noCompletion
	private function set_title(name:String):String {
		SdlBindings.winSetTitle(win, @:privateAccess name.toUtf8());
		return title = name;
	}

	@:noCompletion
	private function set_displayMode(mode:WindowMode):WindowMode {
		if (mode == Fullscreen && displaySetting != null)
			SdlBindings.winSetDisplayMode(win, displaySetting.width, displaySetting.height, displaySetting.framerate);
		if (SdlBindings.winSetFullscreen(win, mode))
			displayMode = mode;
		return displayMode;
	}

	@:noCompletion
	private function set_visible(value:Bool):Bool {
		if (visible != value)
			SdlBindings.winResize(win, value ? 3 : 4);
		return visible = value;
	}

	@:noCompletion
	private function get_width():Int {
		var value = 0;
		SdlBindings.winGetSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_height():Int {
		var value = 0;
		SdlBindings.winGetSize(win, null, value);
		return value;
	}

	@:noCompletion
	private function get_windowToPixelRatio():Float {
		var pixelHeight = 0;
		SdlBindings.winGetPixelSize(win, null, pixelHeight);
		return height / pixelHeight;
	}

	@:noCompletion
	private function get_minWidth():Int {
		var value = 0;
		SdlBindings.winGetMinSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_minHeight():Int {
		var value = 0;
		SdlBindings.winGetMinSize(win, null, value);
		return value;
	}

	@:noCompletion
	private function get_maxWidth():Int {
		var value = 0;
		SdlBindings.winGetMaxSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_maxHeight():Int {
		var value = 0;
		SdlBindings.winGetMaxSize(win, null, value);
		return value;
	}

	@:noCompletion
	inline function get_displayScale():Float {
		return SdlBindings.winGetDisplayScale(win);
	}

	@:noCompletion
	private function get_x():Int {
		var value = 0;
		SdlBindings.winGetPosition(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_y():Int {
		var value = 0;
		SdlBindings.winGetPosition(win, null, value);
		return value;
	}

	@:noCompletion
	inline function get_currentMonitor():DisplayId {
		return SdlBindings.winDisplayHandle(win);
	}

	@:noCompletion
	inline function get_opacity():Float {
		return SdlBindings.winGetOpacity(win);
	}

	@:noCompletion
	private function set_opacity(value:Float):Float {
		SdlBindings.winSetOpacity(win, value);
		return value;
	}

	@:noCompletion
	inline function get_grab():Bool {
		return SdlBindings.getWindowGrab(win);
	}

	@:noCompletion
	private function set_grab(value:Bool):Bool {
		SdlBindings.setWindowGrab(win, value);
		return value;
	}

	@:noCompletion
	inline function get_id():Int {
		return SdlBindings.winGetId(win);
	}

	@:noCompletion
	inline function get_nativeHandle():WinPtr {
		return win;
	}

	@:noCompletion
	static function getNativeError():String {
		final error = SdlBindings.winError();
		return error == null ? "unknown error" : @:privateAccess String.fromUTF8(error);
	}
}
