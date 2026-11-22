package limen.platform;

/**
	Identifies the SDL video backend used for windows, displays, and window input.

	Platform.videoBackend reports the backend detected during Platform.init().
	The video backend handles platform integration; GraphicsDriver identifies
	the separate API used for GPU rendering.
**/
enum abstract VideoBackend(Int) from Int to Int {
	/**
		No video backend is active or the active backend is not recognized.

		This is the initial value before platform initialization. It is also returned
		when SDL reports a video driver that is not represented by this enum.
	**/
	final Unknown = 0;

	/**
		Windows video backend.

		Uses the native Windows windowing system for windows, display management,
		and window input events.
	**/
	final Windows = 1;

	/**
		X11 video backend.

		Uses the X Window System for windows, display management, and input.
		Requires an X server, which may also be provided by XWayland
		on a Wayland desktop.
	**/
	final X11 = 2;

	/**
		Wayland video backend.

		Communicates with a Wayland compositor to create windows and receive input.
		The compositor controls window placement and presentation.
	**/
	final Wayland = 3;

	/**
		Cocoa video backend.

		Uses the native macOS windowing system for windows, display management,
		and window input events.
	**/
	final Cocoa = 4;

	/**
		Android video backend.

		Uses the Android application window and platform input handling.
		Window behavior follows the Android activity lifecycle.
	**/
	final Android = 5;

	/**
		Linux KMS/DRM video backend.

		Uses kernel mode setting and the Direct Rendering Manager to manage
		display output directly, without an X server or Wayland compositor.
		Requires access to the appropriate display devices.
	**/
	final KMSDRM = 6;

	/**
		Offscreen video backend.

		Creates rendering surfaces without showing desktop windows.
		Useful for rendering tasks that do not need visible window output.
	**/
	final Offscreen = 7;

	/**
		Dummy video backend.

		Provides a minimal video environment without visible windows or display output.
		Useful for automated runs that need video initialization without a real display.
	**/
	final Dummy = 8;

	/**
		Returns a human-readable name for this video backend.
		Unknown numeric values are returned in the form `Unknown(value)`.
	**/
	public function toString():String {
		return switch (this) {
			case Unknown: "Unknown";

			case Windows: "Windows";
			case X11: "X11";
			case Wayland: "Wayland";
			case Cocoa: "Cocoa";

			case Android: "Android";

			case KMSDRM: "KMSDRM";

			case Offscreen: "Offscreen";
			case Dummy: "Dummy";

			default: 'Unknown($this)';
		}
	}
}
