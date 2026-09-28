package limen.platform.input.pen;

/**
	Describes the surface a pen interacts with, as reported by Pen.deviceType().

	This can help an application decide whether to draw a cursor: a pen on a
	separate tablet needs an on-screen position indicator, while a pen touching
	the display already points at that position directly.
**/
enum abstract PenDeviceType(Int) from Int to Int {
	/**
		The pen ID is invalid or SDL could not query the device.
	**/
	final Invalid = -1;

	/**
		The pen is valid, but the platform does not report its surface type.
	**/
	final Unknown = 0;

	/**
		The pen touches a display directly, such as a stylus used on a touchscreen.
	**/
	final Direct = 1;

	/**
		The pen touches a separate surface that is not a display, such as a drawing tablet.
	**/
	final Indirect = 2;
}
