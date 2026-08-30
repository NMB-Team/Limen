package limen.platform;

import haxe.Int64;

import limen.platform.window.Window;
import limen.platform.internal.NativeTypes.WinPtr;
import limen.graphics.GraphicsDriver;
import limen.platform.display.Display;
import limen.platform.event.Event;
import limen.platform.input.Keyboard;
import limen.platform.input.Mouse;
import limen.platform.input.TextInput;
import limen.platform.internal.SdlBindings;
import limen.platform.system.Clipboard;
import limen.platform.system.MessageBox;
import limen.platform.system.MessageBoxIcon;
import limen.platform.system.Paths;
import limen.platform.system.Time;

typedef DisplayId = limen.platform.display.Display.DisplayId;
typedef DisplayInfo = limen.platform.display.Display.DisplayInfo;
typedef DisplayMode = limen.platform.display.DisplayMode;

class Platform {
	public static var graphicsDriver(default, null):GraphicsDriver = None;
	public static var videoBackend(default, null):VideoBackend = Unknown;

	static var initDone = false;
	static var isWin32 = false;
	static var isGrubLinux = false;

	static final event = new Event();
	static final watchEvent = new Event();

	public static function init(preferredGraphicsDriver:GraphicsDriver = OpenGL, ?supportedGraphicsDrivers:Array<GraphicsDriver>):Void {
		if (initDone)
			return;
		if (!SdlBindings.initOnce())
			throw "Failed to init SDL";

		videoBackend = detectVideoBackend();

		if (preferredGraphicsDriver != None) {
			var supported = 0;

			if (supportedGraphicsDrivers == null)
				supported = 0x1E; // opengl
			else
				for (driver in supportedGraphicsDrivers)
					supported |= 1 << (driver : Int);

			graphicsDriver = SdlBindings.selectGraphicsDriver(preferredGraphicsDriver, supported);

			if (graphicsDriver == None) {
				SdlBindings.quit();
				throw "No LIMEN graphics driver was found";
			}
		} else
			graphicsDriver = None;

		initDone = true;

		// detecting for actual system
		isWin32 = SdlBindings.detectWin32();
		isGrubLinux = SdlBindings.detectLinux();
	}

	public static function setHint(name:String, value:String):Bool {
		return @:privateAccess SdlBindings.hintValue(name.toUtf8(), value.toUtf8());
	}

	public static function watchWindowEvents(onEvent:Null<Event -> Void>):Void {
		SdlBindings.setWindowEventWatch(onEvent, watchEvent);
	}

	public static function processEvents(onEvent:Event -> Bool):Bool {
		while (pollEvent(event)) {
			final handled = onEvent(event);
			if (event.type == Quit && handled)
				return false;
		}
		return true;
	}

	public static inline function pollEvent(target:Event):Bool {
		return SdlBindings.eventLoop(target);
	}

	public static function quit():Void {
		if (!initDone)
			return;
		SdlBindings.quit();
		graphicsDriver = None;
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
		return window == null ? SdlBindings.getScreenWidth() : SdlBindings.getScreenWidthOfWindow(@:privateAccess window.win);
	}

	public static function getScreenHeight(?window:Window):Int {
		return window == null ? SdlBindings.getScreenHeight() : SdlBindings.getScreenHeightOfWindow(@:privateAccess window.win);
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
		final nativeDevices = SdlBindings.getDevices();
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
		final error = SdlBindings.getError();
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

	public static inline function getRefreshRate(window:WinPtr):Int {
		return SdlBindings.getRefreshRate(window);
	}

	public static inline function setDragAndDropEnabled(enabled:Bool):Void {
		SdlBindings.setDragAndDropEnabled(enabled);
	}

	public static inline function getDragAndDropEnabled():Bool {
		return SdlBindings.getDragAndDropEnabled();
	}

	public static function getJoysticks():Array<Int> {
		final native = SdlBindings.getJoysticks();
		return [for (index in 0...native.length) native[index]];
	}

	public static inline function isWindows():Bool {
		return isWin32;
	}

	public static inline function isLinux():Bool {
		return isGrubLinux;
	}

	static function detectVideoBackend():VideoBackend {
		return SdlBindings.getVideoBackend();
	}
}

enum abstract SDLHint(String) from String to String {
	final SDL_HINT_FRAMEBUFFER_ACCELERATION = "SDL_FRAMEBUFFER_ACCELERATION";
	final SDL_HINT_RENDER_DRIVER = "SDL_RENDER_DRIVER";
	final SDL_HINT_RENDER_OPENGL_SHADERS = "SDL_RENDER_OPENGL_SHADERS";
	final SDL_HINT_RENDER_DIRECT3D_THREADSAFE = "SDL_RENDER_DIRECT3D_THREADSAFE";
	final SDL_HINT_RENDER_DIRECT3D11_DEBUG = "SDL_RENDER_DIRECT3D11_DEBUG";
	final SDL_HINT_RENDER_SCALE_QUALITY = "SDL_RENDER_SCALE_QUALITY";
	final SDL_HINT_RENDER_VSYNC = "SDL_RENDER_VSYNC";
	final SDL_HINT_VIDEO_ALLOW_SCREENSAVER = "SDL_VIDEO_ALLOW_SCREENSAVER";
	final SDL_HINT_VIDEO_X11_XVIDMODE = "SDL_VIDEO_X11_XVIDMODE";
	final SDL_HINT_VIDEO_X11_XINERAMA = "SDL_VIDEO_X11_XINERAMA";
	final SDL_HINT_VIDEO_X11_XRANDR = "SDL_VIDEO_X11_XRANDR";
	final SDL_HINT_VIDEO_X11_NET_WM_PING = "SDL_VIDEO_X11_NET_WM_PING";
	final SDL_HINT_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN = "SDL_WINDOW_FRAME_USABLE_WHILE_CURSOR_HIDDEN";
	final SDL_HINT_WINDOWS_ENABLE_MESSAGELOOP = "SDL_WINDOWS_ENABLE_MESSAGELOOP";
	final SDL_HINT_GRAB_KEYBOARD = "SDL_GRAB_KEYBOARD";
	final SDL_HINT_MOUSE_RELATIVE_MODE_WARP = "SDL_MOUSE_RELATIVE_MODE_WARP";
	final SDL_HINT_VIDEO_MINIMIZE_ON_FOCUS_LOSS = "SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS";
	final SDL_HINT_IDLE_TIMER_DISABLED = "SDL_IOS_IDLE_TIMER_DISABLED";
	final SDL_HINT_ORIENTATIONS = "SDL_IOS_ORIENTATIONS";
	final SDL_HINT_ACCELEROMETER_AS_JOYSTICK = "SDL_ACCELEROMETER_AS_JOYSTICK";
	final SDL_HINT_XINPUT_ENABLED = "SDL_XINPUT_ENABLED";
	final SDL_HINT_XINPUT_USE_OLD_JOYSTICK_MAPPING = "SDL_XINPUT_USE_OLD_JOYSTICK_MAPPING";
	final SDL_HINT_GAMECONTROLLERCONFIG = "SDL_GAMECONTROLLERCONFIG";
	final SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS = "SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS";
	final SDL_HINT_ALLOW_TOPMOST = "SDL_ALLOW_TOPMOST";
	final SDL_HINT_TIMER_RESOLUTION = "SDL_TIMER_RESOLUTION";
	final SDL_HINT_THREAD_STACK_SIZE = "SDL_THREAD_STACK_SIZE";
	final SDL_HINT_VIDEO_HIGHDPI_DISABLED = "SDL_VIDEO_HIGHDPI_DISABLED";
	final SDL_HINT_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK = "SDL_MAC_CTRL_CLICK_EMULATE_RIGHT_CLICK";
	final SDL_HINT_VIDEO_WIN_D3DCOMPILER = "SDL_VIDEO_WIN_D3DCOMPILER";
	final SDL_HINT_VIDEO_WINDOW_SHARE_PIXEL_FORMAT = "SDL_VIDEO_WINDOW_SHARE_PIXEL_FORMAT";
	final SDL_HINT_WINRT_PRIVACY_POLICY_URL = "SDL_WINRT_PRIVACY_POLICY_URL";
	final SDL_HINT_WINRT_PRIVACY_POLICY_LABEL = "SDL_WINRT_PRIVACY_POLICY_LABEL";
	final SDL_HINT_WINRT_HANDLE_BACK_BUTTON = "SDL_WINRT_HANDLE_BACK_BUTTON";
	final SDL_HINT_VIDEO_MAC_FULLSCREEN_SPACES = "SDL_VIDEO_MAC_FULLSCREEN_SPACES";
	final SDL_HINT_MAC_BACKGROUND_APP = "SDL_MAC_BACKGROUND_APP";
	final SDL_HINT_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION = "SDL_ANDROID_APK_EXPANSION_MAIN_FILE_VERSION";
	final SDL_HINT_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION = "SDL_ANDROID_APK_EXPANSION_PATCH_FILE_VERSION";
	final SDL_HINT_IME_INTERNAL_EDITING = "SDL_IME_INTERNAL_EDITING";
	final SDL_HINT_ANDROID_SEPARATE_MOUSE_AND_TOUCH = "SDL_ANDROID_SEPARATE_MOUSE_AND_TOUCH";
	final SDL_HINT_EMSCRIPTEN_KEYBOARD_ELEMENT = "SDL_EMSCRIPTEN_KEYBOARD_ELEMENT";
	final SDL_HINT_NO_SIGNAL_HANDLERS = "SDL_NO_SIGNAL_HANDLERS";
	final SDL_HINT_WINDOWS_NO_CLOSE_ON_ALT_F4 = "SDL_WINDOWS_NO_CLOSE_ON_ALT_F4";
}
