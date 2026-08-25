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
		Fills the entire display using a borderless Win32 window
		while remaining in windowed presentation mode.

		On Windows, this avoids fullscreen presentation throttling
		across graphics backends, which may improve performance.
	**/
	final WindowedFullscreen:WindowMode = 2;

	/**
		Uses SDL-managed borderless fullscreen at the current desktop resolution.

		The desktop display mode is preserved.
	**/
	final DesktopFullscreen:WindowMode = 3;
}
