package limen.platform;

import haxe.Int64;

import limen.platform.window.Window;
import limen.graphics.GraphicsDriver;
import limen.platform.display.Display;
import limen.platform.display.DisplayId;
import limen.platform.display.DisplayInfo;
import limen.platform.display.DisplayMode;
import limen.platform.event.Event;
import limen.platform.input.Keyboard;
import limen.platform.input.Mouse;
import limen.platform.input.TextInput;
import limen.platform.internal.SDLBindings;
import limen.platform.system.Clipboard;
import limen.platform.system.dialog.MessageBox;
import limen.platform.system.dialog.MessageBoxIcon;
import limen.platform.system.Paths;
import limen.platform.system.Time;
import limen.platform.system.tray.Tray;

class Platform {
	public static var graphicsDriver(default, null):GraphicsDriver = None;
	public static var videoBackend(default, null):VideoBackend = Unknown;
	public static var isMobile(default, null):Bool = false;

	static var initDone = false;
	static var isWin32 = false;
	static var isLinuxPlatform = false;

	static final event = new Event();
	static final watchEvent = new Event();

	public static function init(preferredGraphicsDriver:GraphicsDriver = OpenGL, ?supportedGraphicsDrivers:Array<GraphicsDriver>):Void {
		if (initDone)
			return;
		if (!SDLBindings.initOnce())
			throw "Failed to init SDL";

		videoBackend = detectVideoBackend();

		if (preferredGraphicsDriver != None) {
			var supported = 0;

			if (supportedGraphicsDrivers == null)
				supported = 0x1E; // opengl
			else
				for (driver in supportedGraphicsDrivers)
					supported |= 1 << (driver : Int);

			graphicsDriver = SDLBindings.selectGraphicsDriver(preferredGraphicsDriver, supported);

			if (graphicsDriver == None) {
				SDLBindings.quit();
				throw "No LIMEN graphics driver was found";
			}
		} else
			graphicsDriver = None;

		initDone = true;

		// detecting for actual system
		isWin32 = SDLBindings.detectWin32();
		isLinuxPlatform = SDLBindings.detectLinux();
		isMobile = SDLBindings.detectMobile();
	}

	public static function setHint(name:SDLHint, value:String):Bool {
		return @:privateAccess SDLBindings.hintValue((name : String).toUtf8(), value.toUtf8());
	}

	public static function watchWindowEvents(onEvent:Null<Event -> Void>):Void {
		SDLBindings.setWindowEventWatch(onEvent, watchEvent);
	}

	public static function processEvents(onEvent:Event -> Bool):Bool {
		while (pollEvent(event)) {
			final handled = onEvent(event);
			if (event.type == Quit && handled)
				return false;
		}
		return true;
	}

	public static function pollEvent(target:Event):Bool {
		final available = SDLBindings.eventLoop(target);
		Tray.dispatchCallbacks();
		return available;
	}

	public static function quit():Void {
		if (!initDone)
			return;
		Tray.destroyAll();
		SDLBindings.quit();

		graphicsDriver = None;
		videoBackend = Unknown;

		initDone = false;
	}

	public static inline function delay(milliseconds:Int):Void {
		Time.delay(milliseconds);
	}

	public static inline function getTime():Float {
		return Time.now();
	}

	public static inline function getTimestamp():Int64 {
		return Time.timestamp();
	}

	public static function getScreenWidth(?window:Window):Int {
		return window == null ? SDLBindings.getScreenWidth() : SDLBindings.getScreenWidthOfWindow(@:privateAccess window.win);
	}

	public static function getScreenHeight(?window:Window):Int {
		return window == null ? SDLBindings.getScreenHeight() : SDLBindings.getScreenHeightOfWindow(@:privateAccess window.win);
	}

	public static inline function message(title:String, text:String, icon:MessageBoxIcon = None):Void {
		MessageBox.show(title, text, icon);
	}

	public static inline function getDisplayModes(display:DisplayId):Array<DisplayMode> {
		return Display.modes(display);
	}

	public static inline function getCurrentDisplayMode(display:DisplayId, desktop:Bool = false):Null<DisplayMode> {
		return Display.currentMode(display, desktop);
	}

	public static inline function getDisplays():Array<DisplayInfo> {
		return Display.all();
	}

	public static function getDevices():Array<String> {
		final devices = [];
		final nativeDevices = SDLBindings.getDevices();
		final names = new Map<String, Bool>();
		for (value in nativeDevices) {
			if (value == null)
				break;
			final name = StringTools.trim(@:privateAccess String.fromUCS2(value));
			if (names.exists(name) || StringTools.startsWith(name, "RDP"))
				continue;
			names.set(name, true);
			devices.push(name);
		}
		return devices;
	}

	public static inline function setRelativeMouseMode(enabled:Bool):Int {
		return Mouse.setRelative(enabled);
	}

	public static inline function getRelativeMouseMode():Bool {
		return Mouse.isRelative();
	}

	public static inline function getGlobalMouseState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return Mouse.globalState(x, y);
	}

	public static inline function getRelativeMouseState(x:hl.Ref<Int>, y:hl.Ref<Int>):Int {
		return Mouse.relativeState(x, y);
	}

	public static inline function warpMouseGlobal(x:Int, y:Int):Int {
		return Mouse.warpGlobal(x, y);
	}

	public static inline function setMouseMotionEvents(enabled:Bool):Void {
		Mouse.setMotionEvents(enabled);
	}

	public static inline function setClipboardText(text:String):Bool {
		return Clipboard.setText(text);
	}

	public static inline function getClipboardText():String {
		return Clipboard.getText();
	}

	public static function getError():String {
		final error = SDLBindings.getError();
		return error == null ? null : @:privateAccess String.fromUTF8(error);
	}

	public static inline function getPrefPath(organization:String, application:String):String {
		return Paths.preference(organization, application);
	}

	public static inline function isTextInputShown():Bool {
		return TextInput.isShown();
	}

	public static inline function detectKeyboardLayout():String {
		return Keyboard.layout();
	}

	public static inline function getRefreshRate(window:Window):Int {
		return SDLBindings.getRefreshRate(window.nativeHandle);
	}

	public static inline function setDragAndDropEnabled(enabled:Bool):Void {
		SDLBindings.setDragAndDropEnabled(enabled);
	}

	public static inline function getDragAndDropEnabled():Bool {
		return SDLBindings.getDragAndDropEnabled();
	}

	public static function getJoysticks():Array<Int> {
		final native = SDLBindings.getJoysticks();
		return [for (index in 0...native.length) native[index]];
	}

	public static inline function isWindows():Bool {
		return isWin32;
	}

	public static inline function isLinux():Bool {
		return isLinuxPlatform;
	}

	static function detectVideoBackend():VideoBackend {
		return SDLBindings.getVideoBackend();
	}
}
