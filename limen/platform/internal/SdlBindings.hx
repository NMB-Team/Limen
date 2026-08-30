package limen.platform.internal;

import haxe.Int64;

import limen.platform.Platform.DisplayId;
import limen.platform.internal.NativeTypes.WinPtr;
import limen.platform.internal.NativeTypes.CursorPtr;
import limen.platform.internal.NativeTypes.GamepadPtr;
import limen.platform.internal.NativeTypes.JoystickPtr;
import limen.platform.internal.NativeTypes.SurfacePtr;
import limen.platform.window.WindowMode;

@:hlNative("limen")
class SdlBindings {
	public static function initOnce():Bool {
		return false;
	}

	public static function selectGraphicsDriver(preferred:Int, supported:Int):Int {
		return 0;
	}

	public static function getVideoBackend():Int {
		return 0;
	}

	public static function isDlssAvailable():Bool {
		return false;
	}

	public static function quit():Void {}

	public static function delay(milliseconds:Int):Void {}

	public static function detectWin32():Bool {
		return false;
	}

	public static function detectLinux():Bool {
		return false;
	}

	public static function eventLoop(event:Dynamic):Bool {
		return false;
	}

	public static function setWindowEventWatch(onEvent:Dynamic, event:Dynamic):Void {}

	public static function hintValue(name:hl.Bytes, value:hl.Bytes):Bool {
		return false;
	}

	public static function getTime():Float {
		return 0.;
	}

	@:hlNative("limen", "get_timestamp") // runtime validation showed getTimestamp() was not resolved and executed its fallback body 0
	public static function getTimestamp():Int64 {
		return 0;
	}

	public static function getPrefPath(org:hl.Bytes, app:hl.Bytes):hl.Bytes {
		return null;
	}

	public static function getDevices():hl.NativeArray<hl.Bytes> {
		return null;
	}

	public static function detectKeyboardLayout():hl.Bytes {
		return null;
	}

	public static function getRefreshRate(win:WinPtr):Int {
		return 0;
	}

	public static function getGlobalMouseState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return 0;
	}

	public static function getRelativeMouseState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return 0;
	}

	public static function setRelativeMouseMode(enable:Bool):Int {
		return 0;
	}

	public static function getRelativeMouseMode():Bool {
		return false;
	}

	public static function warpMouseGlobal(x:Int, y:Int):Int {
		return 0;
	}

	public static function setMouseMotionEvents(enabled:Bool):Void {}

	public static function setDragAndDropEnabled(enabled:Bool):Void {}

	public static function getDragAndDropEnabled():Bool {
		return false;
	}

	public static function captureMouse(enable:Bool):Int {
		return 0;
	}

	public static function getScreenWidth():Int {
		return 0;
	}

	public static function getScreenHeight():Int {
		return 0;
	}

	public static function getScreenWidthOfWindow(win:WinPtr):Int {
		return 0;
	}

	public static function getScreenHeightOfWindow(win:WinPtr):Int {
		return 0;
	}

	public static function getDisplayModes(display:DisplayId):hl.NativeArray<Dynamic> {
		return null;
	}

	public static function getCurrentDisplayMode(display:DisplayId, desktop:Bool):Dynamic {
		return null;
	}

	public static function getDisplays():hl.NativeArray<Dynamic> {
		return null;
	}

	public static function setClipboardText(text:hl.Bytes):Bool {
		return false;
	}

	public static function getClipboardText():hl.Bytes {
		return null;
	}

	public static function getError():hl.Bytes {
		return null;
	}

	public static function isTextInputShown():Bool {
		return false;
	}

	public static function messageBox(title:hl.Bytes, text:hl.Bytes, icon:Int):Void {}

	public static function winCreateEx(x:Int, y:Int, width:Int, height:Int, flags:hl.I64):WinPtr {
		return null;
	}

	public static function winSetTitle(win:WinPtr, title:hl.Bytes):Void {}

	public static function winSetPosition(win:WinPtr, x:Int, y:Int):Void {}

	public static function winGetPosition(win:WinPtr, x:hl.Ref<Int>, y:hl.Ref<Int>):Void {}

	public static function winSetFullscreen(win:WinPtr, mode:WindowMode):Bool {
		return false;
	}

	public static function winSetSize(win:WinPtr, width:Int, height:Int):Void {}

	public static function winResize(win:WinPtr, mode:Int):Void {}

	public static function winSetMinSize(win:WinPtr, width:Int, height:Int):Void {}

	public static function winSetMaxSize(win:WinPtr, width:Int, height:Int):Void {}

	public static function winGetSize(win:WinPtr, width:hl.Ref<Int>, height:hl.Ref<Int>):Void {}

	public static function winGetPixelSize(win:WinPtr, width:hl.Ref<Int>, height:hl.Ref<Int>):Void {}

	public static function winGetMinSize(win:WinPtr, width:hl.Ref<Int>, height:hl.Ref<Int>):Void {}

	public static function winGetMaxSize(win:WinPtr, width:hl.Ref<Int>, height:hl.Ref<Int>):Void {}

	public static function winGetOpacity(win:WinPtr):Float {
		return 0.;
	}

	public static function windowDestroy(win:WinPtr):Void {}

	public static function winError():hl.Bytes {
		return null;
	}

	public static function setWindowGrab(win:WinPtr, grab:Bool):Void {}

	public static function getWindowGrab(win:WinPtr):Bool {
		return false;
	}

	public static function warpMouseInWindow(win:WinPtr, x:Int, y:Int):Void {}

	public static function winSetOpacity(win:WinPtr, opacity:Float):Bool {
		return false;
	}

	public static function winGetDisplayScale(win:WinPtr):Float {
		return 0.;
	}

	public static function winSetIcon(win:WinPtr, surface:SurfacePtr):Void {}

	public static function winCenter(win:WinPtr, centerPrimary:Bool):Void {}

	public static function winSetDisplayMode(win:WinPtr, width:Int, height:Int, framerate:Int):Bool {
		return false;
	}

	public static function winDisplayHandle(win:WinPtr):Int {
		return 0;
	}

	public static function winGetId(win:WinPtr):Int {
		return 0;
	}

	public static function winRaise(win:WinPtr):Void {}

	public static function winSetDarkMode(win:WinPtr, enabled:Bool):Bool {
		return false;
	}

	public static function winSetAlwaysOnTop(win:WinPtr, enabled:Bool):Bool {
		return false;
	}

	public static function surfaceFrom(pixels:hl.Bytes, width:Int, height:Int, depth:Int, pitch:Int, rmask:Int, gmask:Int, bmask:Int, amask:Int):SurfacePtr {
		return null;
	}

	public static function freeSurface(surface:SurfacePtr):Void {}

	public static function cursorCreate(surface:SurfacePtr, hotX:Int, hotY:Int):CursorPtr {
		return null;
	}

	public static function cursorCreateSystem(kind:Int):CursorPtr {
		return null;
	}

	public static function freeCursor(cursor:CursorPtr):Void {}

	public static function showCursor(visible:Bool):Void {}

	public static function isCursorVisible():Bool {
		return false;
	}

	public static function setCursor(cursor:CursorPtr):Void {}

	public static function gctrlCount():Int {
		return 0;
	}

	public static function gctrlOpen(id:Int):GamepadPtr {
		return null;
	}

	public static function gctrlClose(gamepad:GamepadPtr):Void {}

	public static function gctrlGetAxis(gamepad:GamepadPtr, axis:Int):Int {
		return 0;
	}

	public static function gctrlGetButton(gamepad:GamepadPtr, button:Int):Bool {
		return false;
	}

	public static function gctrlGetId(gamepad:GamepadPtr):Int {
		return -1;
	}

	public static function gctrlGetName(gamepad:GamepadPtr):hl.Bytes {
		return null;
	}

	public static function gctrlRumble(gamepad:GamepadPtr, strength:Float, duration:Int):Bool {
		return false;
	}

	public static function joyCount():Int {
		return 0;
	}

	public static function joyOpen(id:Int):JoystickPtr {
		return null;
	}

	public static function joyClose(joystick:JoystickPtr):Void {}

	public static function joyGetAxis(joystick:JoystickPtr, axis:Int):Int {
		return 0;
	}

	public static function joyGetHat(joystick:JoystickPtr, hat:Int):Int {
		return 0;
	}

	public static function joyGetButton(joystick:JoystickPtr, button:Int):Bool {
		return false;
	}

	public static function joyGetId(joystick:JoystickPtr):Int {
		return -1;
	}

	public static function joyGetName(joystick:JoystickPtr):hl.Bytes {
		return null;
	}

	public static function getJoysticks():hl.NativeArray<Int> {
		return null;
	}
}
