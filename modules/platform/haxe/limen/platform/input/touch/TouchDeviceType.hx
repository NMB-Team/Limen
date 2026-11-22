package limen.platform.input.touch;

/**
	Describes how a touch device maps contact positions to the display.

	Touch.type reports whether input comes from a touchscreen or an indirect
	surface, such as a trackpad, and which coordinate model it uses.
**/
enum abstract TouchDeviceType(Int) from Int to Int {
	/**
		The device ID is invalid or SDL could not determine its type.
	**/
	final Invalid = -1;

	/**
		A touchscreen with contact positions relative to the window being touched.
	**/
	final Direct = 0;

	/**
		An indirect surface, such as a trackpad, with absolute device coordinates.

		Positions describe where a finger touches the device's surface rather than
		where the screen cursor is located.
	**/
	final IndirectAbsolute = 1;

	/**
		An indirect surface, such as a trackpad, with screen cursor-relative coordinates.

		Input is interpreted relative to the cursor rather than as an absolute
		position on the device's surface.
	**/
	final IndirectRelative = 2;
}
