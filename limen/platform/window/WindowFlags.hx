package limen.platform.window;

import haxe.Int64;

/**
	The flags on a window.

	These cover a lot of true/false, or on/off, window state. Some of it is
	immutable after being set through `SDL_CreateWindow()`, some of it can be
	changed on existing windows by the app, and some of it might be altered by
	the user or system outside of the app's control.

	When creating windows with `SDL_WINDOW_RESIZABLE`, SDL will constrain
	resizable windows to the dimensions recommended by the compositor to fit it
	within the usable desktop space, although some compositors will do this
	automatically without intervention as well. Use `SDL_SetWindowResizable`
	after creation instead if you wish to create a window with a specific size.
**/
abstract WindowFlags(Int64) from Int64 to Int64 {
	/**
		Window is in fullscreen mode.
	**/
	public static final SDL_WINDOW_FULLSCREEN:WindowFlags = 0x00000001;

	/**
		Window usable with OpenGL context.
	**/
	public static final SDL_WINDOW_OPENGL:WindowFlags = 0x00000002;

	/**
		Window is occluded.
	**/
	public static final SDL_WINDOW_OCCLUDED:WindowFlags = 0x00000004;

	/**
		Window is neither mapped onto the desktop nor shown in the taskbar/dock/window list.
	**/
	public static final SDL_WINDOW_HIDDEN:WindowFlags = 0x00000008;

	/**
		No window decoration.
	**/
	public static final SDL_WINDOW_BORDERLESS:WindowFlags = 0x00000010;

	/**
		Window can be resized.
	**/
	public static final SDL_WINDOW_RESIZABLE:WindowFlags = 0x00000020;

	/**
		Window is minimized.
	**/
	public static final SDL_WINDOW_MINIMIZED:WindowFlags = 0x00000040;

	/**
		Window is maximized.
	**/
	public static final SDL_WINDOW_MAXIMIZED:WindowFlags = 0x00000080;

	/**
		Window has grabbed mouse input.
	**/
	public static final SDL_WINDOW_MOUSE_GRABBED:WindowFlags = 0x00000100;

	/**
		Window has input focus.
	**/
	public static final SDL_WINDOW_INPUT_FOCUS:WindowFlags = 0x00000200;

	/**
		Window has mouse focus.
	**/
	public static final SDL_WINDOW_MOUSE_FOCUS:WindowFlags = 0x00000400;

	/**
		Window not created by SDL.
	**/
	public static final SDL_WINDOW_EXTERNAL:WindowFlags = 0x00000800;

	/**
		Window is modal.
	**/
	public static final SDL_WINDOW_MODAL:WindowFlags = 0x00001000;

	/**
		Window uses high pixel density back buffer if possible.
	**/
	public static final SDL_WINDOW_HIGH_PIXEL_DENSITY:WindowFlags = 0x00002000;

	/**
		Window has mouse captured (unrelated to MOUSE_GRABBED).
	**/
	public static final SDL_WINDOW_MOUSE_CAPTURE:WindowFlags = 0x00004000;

	/**
		Window has relative mode enabled.
	**/
	public static final SDL_WINDOW_MOUSE_RELATIVE_MODE:WindowFlags = 0x00008000;

	/**
		Window should always be above others.
	**/
	public static final SDL_WINDOW_ALWAYS_ON_TOP:WindowFlags = 0x00010000;

	/**
		Window should be treated as a utility window, not showing in the task bar and window list.
	**/
	public static final SDL_WINDOW_UTILITY:WindowFlags = 0x00020000;

	/**
		Window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window.
	**/
	public static final SDL_WINDOW_TOOLTIP:WindowFlags = 0x00040000;

	/**
		Window should be treated as a popup menu, requires a parent window.
	**/
	public static final SDL_WINDOW_POPUP_MENU:WindowFlags = 0x00080000;

	/**
		Window has grabbed keyboard input.
	**/
	public static final SDL_WINDOW_KEYBOARD_GRABBED:WindowFlags = 0x00100000;

	/**
		Window is in fill-document mode on Emscripten.
	**/
	public static final SDL_WINDOW_FILL_DOCUMENT:WindowFlags = 0x00200000;

	/**
		Window usable for Vulkan surface.
	**/
	public static final SDL_WINDOW_VULKAN:WindowFlags = 0x10000000;

	/**
		Window usable for Metal view.
	**/
	public static final SDL_WINDOW_METAL:WindowFlags = 0x20000000;

	/**
		Window with transparent buffer.
	**/
	public static final SDL_WINDOW_TRANSPARENT:WindowFlags = 0x40000000;

	/**
		Window should not be focusable.
	**/
	public static final SDL_WINDOW_NOT_FOCUSABLE:WindowFlags = Int64.make(0, 0x80000000);

	/**
		Used to indicate that you don't care what the window position/display is.
		This always uses the primary display.
	**/
	public static final SDL_WINDOWPOS_UNDEFINED:Int = 0x1FFF0000;

	/**
		Used to indicate that the window position should be centered.
		This always uses the primary display.
	**/
	public static final SDL_WINDOWPOS_CENTERED:Int = 0x2FFF0000;

	// ^ masks realizations for working this abstract WindowFlags with Int64

	@:from
	public static inline function fromInt(value:Int):WindowFlags {
		return cast Int64.make(0, value);
	}

	@:op(a | b)
	public static inline function or(a:WindowFlags, b:WindowFlags):WindowFlags {
		return cast((a : Int64) | (b : Int64));
	}

	@:op(a & b)
	public static inline function and(a:WindowFlags, b:WindowFlags):WindowFlags {
		return cast((a : Int64) & (b : Int64));
	}

	@:op(a ^ b)
	public static inline function xor(a:WindowFlags, b:WindowFlags):WindowFlags {
		return cast((a : Int64) ^ (b : Int64));
	}

	@:op(~a)
	public static inline function complement(value:WindowFlags):WindowFlags {
		return cast ~(value : Int64);
	}

	@:op(a << b)
	public static inline function shiftLeft(value:WindowFlags, bits:Int):WindowFlags {
		return cast((value : Int64) << bits);
	}

	@:op(a >> b)
	public static inline function shiftRight(value:WindowFlags, bits:Int):WindowFlags {
		return cast((value : Int64) >> bits);
	}

	@:op(a >>> b)
	public static inline function shiftRightUnsigned(value:WindowFlags, bits:Int):WindowFlags {
		return cast((value : Int64) >>> bits);
	}

	public inline function has(flags:WindowFlags):Bool {
		return ((this : Int64) & (flags : Int64)) != (0 : Int64);
	}
}
