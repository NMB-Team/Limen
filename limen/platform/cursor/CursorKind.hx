package limen.platform.cursor;

/**
	Selects a standard system cursor shape for Cursor.createSystem().

	Each shape communicates an interaction, such as selecting text, resizing,
	or waiting for an operation. Its appearance depends on the platform and
	the user's cursor theme. Use Cursor.set() to activate the created cursor.
**/
enum abstract CursorKind(Int) {
	/**
		The standard arrow pointer used for general pointing and selection.
	**/
	final Arrow = 0;

	/**
		An I-shaped pointer indicating that text can be selected or edited.
	**/
	final IBeam = 1;

	/**
		A busy pointer indicating that the application is working and input is unavailable.
	**/
	final Wait = 2;

	/**
		A crosshair pointer used for precise positioning, such as drawing or selecting a point.
	**/
	final CrossHair = 3;

	/**
		An arrow with a busy indicator, showing that work is in progress while input remains available.
	**/
	final WaitArrow = 4;

	/**
		A diagonal resize pointer running from the top-left to the bottom-right.
	**/
	final SizeNWSE = 5;

	/**
		A diagonal resize pointer running from the top-right to the bottom-left.
	**/
	final SizeNESW = 6;

	/**
		A horizontal resize pointer indicating that the left or right edge can be dragged.
	**/
	final SizeWE = 7;

	/**
		A vertical resize pointer indicating that the top or bottom edge can be dragged.
	**/
	final SizeNS = 8;

	/**
		A pointer with arrows in all four directions, indicating that an item can be moved.
	**/
	final SizeALL = 9;

	/**
		A prohibited-action pointer indicating that the current operation is not allowed.
	**/
	final No = 10;

	/**
		A pointing hand indicating an interactive item, such as a link.
	**/
	final Hand = 11;
}
