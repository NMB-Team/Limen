package limen.platform.window;

enum abstract WindowMode(Int) {
	/**
		Runs the application in a regular resizable window.
	**/
	final Windowed:WindowMode = 0;

	/**
		Uses exclusive fullscreen mode.

		The display mode may be changed to match the requested
		resolution and refresh rate.
	**/
	final ExclusiveFullscreen:WindowMode = 1;

	/**
		Fills the entire display while remaining in windowed presentation mode.

		On Windows, this uses the native Win32 borderless-windowed implementation,
		which avoids fullscreen presentation throttling across graphics backends.
		On Wayland, this aliases to `DesktopFullscreen` because the compositor
		controls top-level window placement. X11 currently uses the same fallback;
		native EWMH support may be added later.
	**/
	final WindowedFullscreen:WindowMode = 2;

	/**
		Uses SDL-managed borderless fullscreen at the current desktop resolution.

		The desktop display mode is preserved.
	**/
	final DesktopFullscreen:WindowMode = 3;
}
