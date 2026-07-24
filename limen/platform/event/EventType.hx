package limen.platform.event;

enum abstract EventType(Int) {
	final Quit = 0;
	final MouseMove = 1;
	final MouseLeave = 2;
	final MouseDown = 3;
	final MouseUp = 4;
	final MouseWheel = 5;
	final WindowState = 6;
	final KeyDown = 7;
	final KeyUp = 8;
	final TextInput = 9;
	final GamepadAdded = 100;
	final GamepadRemoved = 101;
	final GamepadButtonDown = 102;
	final GamepadButtonUp = 103;
	final GamepadAxis = 104;
	final TouchDown = 200;
	final TouchUp = 201;
	final TouchMove = 202;
	final JoystickAxisMotion = 300;
	final JoystickBallMotion = 301;
	final JoystickHatMotion = 302;
	final JoystickButtonDown = 303;
	final JoystickButtonUp = 304;
	final JoystickAdded = 305;
	final JoystickRemoved = 306;
	final DropStart = 400;
	final DropFile = 401;
	final DropText = 402;
	final DropEnd = 403;
	final KeyMapChanged = 500;
}
