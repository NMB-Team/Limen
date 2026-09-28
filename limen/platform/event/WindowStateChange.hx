package limen.platform.event;

enum abstract WindowStateChange(Int) {
	/**
		The window has become visible.
	**/
	final Show = 0;

	/**
		The window has been hidden.
	**/
	final Hide = 1;

	/**
		The window needs to be redrawn, for example after an area becomes visible.
	**/
	final Expose = 2;

	/**
		The window has moved on the desktop.
		Event.mouseX and Event.mouseY contain the new window position.
	**/
	final Move = 3;

	/**
		The window size has changed in window coordinates.

		Event.mouseX and Event.mouseY contain the new width and height.
		These dimensions may differ from the pixel size on high-density displays.
	**/
	final Resize = 4;

	/**
		The window has been minimized.
	**/
	final Minimize = 5;

	/**
		The window has been maximized.
	**/
	final Maximize = 6;

	/**
		The window has returned to its normal size after being minimized or maximized.
	**/
	final Restore = 7;

	/**
		The mouse pointer has entered the window.
	**/
	final Enter = 8;

	/**
		The mouse pointer has left the window.
	**/
	final Leave = 9;

	/**
		The window has gained keyboard focus and can receive keyboard input.
	**/
	final Focus = 10;

	/**
		The window has lost keyboard focus.
	**/
	final Blur = 11;

	/**
		The user has requested that the window close, for example with its close button.
		This is a request; the application decides whether to close the window.
	**/
	final Close = 12;

	/**
		The window size in physical pixels has changed.

		Event.mouseX and Event.mouseY contain the new pixel width and height.
		This can also happen when the display scale changes without a change
		to the window size in window coordinates.
	**/
	final PixelResize = 13;
}
