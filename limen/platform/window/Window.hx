package limen.platform.window;

import limen.platform.Surface;
import limen.platform.display.DisplayId;
import limen.platform.display.DisplaySetting;
import limen.platform.internal.SDLBindings;
import limen.platform.window.WindowFlags.*;
import limen.platform.internal.types.WinPtr;

class Window {
	public var id(get, never):Int;

	/**
		The internal `SDL_Window*`. This is not an OS-native HWND, X11 Window, or Wayland surface.
		Use `getNativeWindowInfo()` to query the current platform-native handles.
	**/
	public var nativeHandle(get, never):WinPtr;

	public var title(default, set):String;
	public var width(get, never):Int;
	public var height(get, never):Int;
	public var pixelWidth(get, never):Int;
	public var pixelHeight(get, never):Int;
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
		var flags:WindowFlags = options.flags ?? 0;
		if (options.resizable != false)
			flags |= SDL_WINDOW_RESIZABLE;
		if (options.visible == false)
			flags |= SDL_WINDOW_HIDDEN;
		return new Window(options.title, options.width, options.height, options.x ?? SDL_WINDOWPOS_CENTERED, options.y ?? SDL_WINDOWPOS_CENTERED, flags);
	}

	public function new(title:String, width:Int, height:Int, ?x:Int, ?y:Int, ?flags:WindowFlags) {
		final actualX = x ?? SDL_WINDOWPOS_CENTERED;
		final actualY = y ?? SDL_WINDOWPOS_CENTERED;
		final actualFlags = flags ?? SDL_WINDOW_RESIZABLE;

		final nativeFlags:hl.I64 = (actualFlags : haxe.Int64);
		win = SDLBindings.winCreateEx(actualX, actualY, width, height, nativeFlags);
		if (win == null)
			throw "Failed to create window (" + getNativeError() + ")";
		this.title = title;
		visible = !flags.has(SDL_WINDOW_HIDDEN);
		windows.push(this);
	}

	public inline function setIcon(surface:Surface):Void {
		SDLBindings.winSetIcon(win, cast surface);
	}

	public inline function resize(width:Int, height:Int):Void {
		SDLBindings.winSetSize(win, width, height);
	}

	public inline function setMinSize(width:Int, height:Int):Void {
		SDLBindings.winSetMinSize(win, width, height);
	}

	public inline function setMaxSize(width:Int, height:Int):Void {
		SDLBindings.winSetMaxSize(win, width, height);
	}

	public function isMaximized() {
		return SDLBindings.winMaximized(win);
	}

	public function setMaximized(maximized:Bool):Void {
		SDLBindings.winSetMaximized(win, maximized);
	}

	public inline function setDisplayMode(width:Int, height:Int, refreshRate:Float):Bool {
		return SDLBindings.winSetDisplayMode(win, width, height, refreshRate);
	}

	public inline function setPosition(x:Int, y:Int):Void {
		SDLBindings.winSetPosition(win, x, y);
	}

	public inline function center(centerPrimary:Bool = true):Void {
		SDLBindings.winCenter(win, centerPrimary);
	}

	public inline function show():Void {
		visible = true;
	}

	public inline function hide():Void {
		visible = false;
	}

	public inline function raise():Void {
		SDLBindings.winRaise(win);
	}

	public inline function setDarkMode(enabled:Bool):Bool {
		return SDLBindings.winSetDarkMode(win, enabled);
	}

	public inline function warpMouse(x:Int, y:Int):Void {
		SDLBindings.warpMouseInWindow(win, x, y);
	}

	public inline function captureMouseEvents(enable:Bool):Int {
		return SDLBindings.captureMouse(enable);
	}

	public function destroy():Void {
		if (win == null)
			return;
		SDLBindings.windowDestroy(win);
		win = null;
		windows.remove(this);
	}

	public inline function maximize():Void {
		SDLBindings.winResize(win, 0);
	}

	public inline function minimize():Void {
		SDLBindings.winResize(win, 1);
	}

	public inline function restore():Void {
		SDLBindings.winResize(win, 2);
	}

	public inline function setAlwaysOnTop(enabled:Bool):Bool {
		return SDLBindings.winSetAlwaysOnTop(win, enabled);
	}

	public function getNativeWindowInfo():Null<WindowNativeInfo> {
		if (win == null)
			return null;

		var type = 0;
		var display:haxe.Int64 = 0;
		var handle:haxe.Int64 = 0;
		var extra:haxe.Int64 = 0;
		if (!SDLBindings.winGetNativeWindowInfo(win, type, display, handle, extra))
			return null;

		return switch (type) {
			case 1: Win32(handle, extra);
			case 2: Cocoa(handle);
			case 3: X11(display, handle);
			case 4: Wayland(display, handle);
			case 5: Android(handle);
			default: null;
		};
	}

	@:noCompletion
	private function set_title(name:String):String {
		SDLBindings.winSetTitle(win, @:privateAccess name.toUtf8());
		return title = name;
	}

	@:noCompletion
	private function set_displayMode(mode:WindowMode):WindowMode {
		if (mode == ExclusiveFullscreen && displaySetting != null)
			SDLBindings.winSetDisplayMode(win, displaySetting.width, displaySetting.height, displaySetting.refreshRate);
		if (SDLBindings.winSetFullscreen(win, mode))
			displayMode = mode;
		return displayMode;
	}

	@:noCompletion
	private function set_visible(value:Bool):Bool {
		if (visible != value)
			SDLBindings.winResize(win, value ? 3 : 4);
		return visible = value;
	}

	@:noCompletion
	private function get_width():Int {
		var value = 0;
		SDLBindings.winGetSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_height():Int {
		var value = 0;
		SDLBindings.winGetSize(win, null, value);
		return value;
	}

	@:noCompletion
	private function get_pixelWidth():Int {
		var value = 0;
		SDLBindings.winGetPixelSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_pixelHeight():Int {
		var value = 0;
		SDLBindings.winGetPixelSize(win, null, value);
		return value;
	}

	@:noCompletion
	private function get_windowToPixelRatio():Float {
		var pixelHeight = 0;
		SDLBindings.winGetPixelSize(win, null, pixelHeight);
		return height / pixelHeight;
	}

	@:noCompletion
	private function get_minWidth():Int {
		var value = 0;
		SDLBindings.winGetMinSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_minHeight():Int {
		var value = 0;
		SDLBindings.winGetMinSize(win, null, value);
		return value;
	}

	@:noCompletion
	private function get_maxWidth():Int {
		var value = 0;
		SDLBindings.winGetMaxSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_maxHeight():Int {
		var value = 0;
		SDLBindings.winGetMaxSize(win, null, value);
		return value;
	}

	@:noCompletion
	inline function get_displayScale():Float {
		return SDLBindings.winGetDisplayScale(win);
	}

	@:noCompletion
	private function get_x():Int {
		var value = 0;
		SDLBindings.winGetPosition(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_y():Int {
		var value = 0;
		SDLBindings.winGetPosition(win, null, value);
		return value;
	}

	@:noCompletion
	inline function get_currentMonitor():DisplayId {
		return SDLBindings.winDisplayHandle(win);
	}

	@:noCompletion
	inline function get_opacity():Float {
		return SDLBindings.winGetOpacity(win);
	}

	@:noCompletion
	private function set_opacity(value:Float):Float {
		SDLBindings.winSetOpacity(win, value);
		return value;
	}

	@:noCompletion
	inline function get_grab():Bool {
		return SDLBindings.getWindowGrab(win);
	}

	@:noCompletion
	private function set_grab(value:Bool):Bool {
		SDLBindings.setWindowGrab(win, value);
		return value;
	}

	@:noCompletion
	inline function get_id():Int {
		return SDLBindings.winGetId(win);
	}

	@:noCompletion
	inline function get_nativeHandle():WinPtr {
		return win;
	}

	@:noCompletion
	static function getNativeError():String {
		final error = SDLBindings.winError();
		return error == null ? "unknown error" : @:privateAccess String.fromUTF8(error);
	}
}
