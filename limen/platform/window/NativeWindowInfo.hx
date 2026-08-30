package limen.platform.window;

import haxe.Int64;

enum NativeWindowInfo {
	Win32(hwnd:Int64, hinstance:Int64);
	Cocoa(window:Int64);
	X11(display:Int64, window:Int64);
	Wayland(display:Int64, surface:Int64);
	Android(window:Int64);
}
