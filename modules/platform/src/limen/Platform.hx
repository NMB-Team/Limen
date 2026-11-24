package limen;

import haxe.Int64;

import limen.GraphicsDriver;
import limen.display.Display;
import limen.display.DisplayId;
import limen.display.DisplayInfo;
import limen.display.DisplayMode;
import limen.input.Keyboard;
import limen.input.Mouse;
import limen.input.TextInput;
import limen.internal.SDLBindings;
import limen.system.Clipboard;
import limen.system.dialog.MessageBox;
import limen.system.dialog.MessageBoxIcon;
import limen.system.Paths;
import limen.system.Time;
import limen.system.tray.Tray;

private typedef ListenerFailure = {
	final value:Dynamic;
}

class Platform {
	public static var graphicsDriver(default, null):GraphicsDriver = None;
	public static var videoBackend(default, null):VideoBackend = Unknown;
	public static var isMobile(default, null):Bool = false;

	static var initDone = false;
	static var isWin32 = false;
	static var isLinuxPlatform = false;

	static inline final EVENT_READY = 1;
	static inline final EVENT_DEFERRED = 2;

	static final event = new Event();
	static var pendingErrors = new sys.thread.Deque<ListenerFailure>();
	static final retryEvents:Array<Event> = [];
	static var spareEvent:Null<Event> = new Event();
	static final listenerMutex = new sys.thread.Mutex();
	static var eventWatchListeners:Array<Event -> Void> = [];

	public static function init(preferredGraphicsDriver:GraphicsDriver = OpenGL, ?supportedGraphicsDrivers:Array<GraphicsDriver>):Void {
		if (initDone)
			return;
		if (!SDLBindings.initEventQueue(dispatchEventWatch, event))
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

	/* listeners run on the SDL event producer thread */
	public static function addEventWatchListener(listener:Event -> Void):Void {
		listenerMutex.acquire();
		eventWatchListeners = eventWatchListeners.concat([listener]);
		if (eventWatchListeners.length == 1)
			SDLBindings.setEventWatchEnabled(true);
		listenerMutex.release();
	}

	public static function removeEventWatchListener(listener:Event -> Void):Void {
		listenerMutex.acquire();
		eventWatchListeners = eventWatchListeners.filter(value -> !Reflect.compareMethods(value, listener));
		if (eventWatchListeners.length == 0)
			SDLBindings.setEventWatchEnabled(false);
		listenerMutex.release();
	}

	static function dispatchEventWatch(source:Event):Void {
		listenerMutex.acquire();
		final listeners = eventWatchListeners;
		listenerMutex.release();

		for (listener in listeners) {
			try {
				listener(source);
			} catch (error:Dynamic) {
				pendingErrors.add({value: error});
				SDLBindings.markEventWatchError();
			}
		}
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
		final retryEvent = retryEvents.pop();
		final queued = retryEvent ?? spareEvent ?? new Event();
		if (queued == spareEvent)
			spareEvent = null;

		var result:Int;
		try {
			result = retryEvent != null ? EVENT_READY | EVENT_DEFERRED : SDLBindings.nextEvent(target, queued);
			if ((result & EVENT_DEFERRED) != 0)
				Tray.dispatchCallbacks();
		} catch (error:Dynamic) {
			spareEvent = queued;
			throw error;
		}

		final received = (result & EVENT_READY) != 0;
		if ((result & EVENT_DEFERRED) != 0) {
			final error = pendingErrors.pop(false);
			if (error != null) {
				if (received)
					retryEvents.push(queued);
				else
					spareEvent = queued;

				throw error.value;
			}

			if (received) {
				SDLBindings.copyEvent(queued, target);
				queued.inputChar = queued.dropFile = null;
			}
		}

		spareEvent = queued;
		return received;
	}

	public static function quit():Void {
		if (!initDone)
			return;
		SDLBindings.validateEventShutdown();
		Tray.destroyAll();
		SDLBindings.quit();
		retryEvents.resize(0);
		spareEvent = new Event();
		pendingErrors = new sys.thread.Deque<ListenerFailure>();

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

	/**
		Allow polling to merge consecutive queued mouse movements for the same window,
		device and button state. Uses the latest position and timestamp and sums the
		relative movement. Event Watch still receives each event. Defaults to false.
		Call on the main thread after init. Quit restores the default.
	**/
	public static inline function setMouseMotionCoalescing(enabled:Bool):Void {
		SDLBindings.setMouseMotionCoalescing(enabled);
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

	public static inline function getRefreshRate(window:Window):Float {
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
