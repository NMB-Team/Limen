package limen.platform.window;

import limen.platform.Platform.DisplayId;
import limen.platform.Surface;
import limen.platform.display.DisplaySetting;
import limen.platform.internal.SdlBindings;
import limen.platform.window.WindowFlags.*;
import limen.platform.window.WindowMode.*;
import limen.platform.internal.NativeTypes.WinPtr;

class Window {
	public var id(get, never):Int;
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
		win = SdlBindings.winCreateEx(actualX, actualY, width, height, nativeFlags);
		if (win == null)
			throw "Failed to create window (" + getNativeError() + ")";
		this.title = title;
		visible = !flags.has(SDL_WINDOW_HIDDEN);
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
		if (mode == ExclusiveFullscreen && displaySetting != null)
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
	private function get_pixelWidth():Int {
		var value = 0;
		SdlBindings.winGetPixelSize(win, value, null);
		return value;
	}

	@:noCompletion
	private function get_pixelHeight():Int {
		var value = 0;
		SdlBindings.winGetPixelSize(win, null, value);
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
