package limen.platform.event;

enum abstract EventType(Int) {
	/**
		The application has been asked to quit.
		The application decides how to handle the request and shut down.
	**/
	final Quit = 0;

	/**
		The mouse pointer has moved within a window.

		Event.mouseX and Event.mouseY contain the position in window coordinates.
		Event.mouseXRel and Event.mouseYRel contain the movement since the previous event.
	**/
	final MouseMove = 1;

	/**
		The mouse pointer has left a window.

		The native backend reports this through WindowState with
		Event.state set to WindowStateChange.Leave instead of emitting this type.
	**/
	final MouseLeave = 2;

	/**
		A mouse button has been pressed.
		Event.button identifies the button; Event.mouseX and Event.mouseY contain its position.
	**/
	final MouseDown = 3;

	/**
		A mouse button has been released.
		Event.button identifies the button; Event.mouseX and Event.mouseY contain its position.
	**/
	final MouseUp = 4;

	/**
		The mouse wheel has been scrolled vertically.

		Event.wheelDelta contains the signed whole-number scroll amount,
		adjusted for the native scroll direction. Event.mouseX and Event.mouseY
		contain the mouse position in window coordinates.
	**/
	final MouseWheel = 5;

	/**
		A window has changed state, moved, resized, or received a close request.
		Event.state identifies the change as a WindowStateChange value.
	**/
	final WindowState = 6;

	/**
		A keyboard key has been pressed or repeated while held down.

		Event.keyCode identifies the key and Event.scanCode identifies its physical position.
		Event.modifier contains the active modifier flags; Event.keyRepeat indicates a repeat.
	**/
	final KeyDown = 7;

	/**
		A keyboard key has been released.

		Event.keyCode identifies the key and Event.scanCode identifies its physical position.
		Event.modifier contains the active modifier flags.
	**/
	final KeyUp = 8;

	/**
		Text has been entered, including text committed by an input method.
		Event.inputChar contains the entered text as null-terminated UTF-16 bytes.
	**/
	final TextInput = 9;

	/**
		A gamepad has become available.
		Event.reference contains its instance ID.
	**/
	final GamepadAdded = 100;

	/**
		A gamepad has been disconnected.
		Event.reference contains its instance ID.
	**/
	final GamepadRemoved = 101;

	/**
		A gamepad button has been pressed.
		Event.reference identifies the gamepad; Event.button identifies the button.
	**/
	final GamepadButtonDown = 102;

	/**
		A gamepad button has been released.
		Event.reference identifies the gamepad; Event.button identifies the button.
	**/
	final GamepadButtonUp = 103;

	/**
		A gamepad axis, such as a stick or trigger, has changed value.

		Event.reference identifies the gamepad; Event.button identifies the axis.
		Event.value contains the raw signed axis value.
	**/
	final GamepadAxis = 104;

	/**
		A finger has touched the screen.

		Event.touchId and Event.fingerId identify the device and finger.
		Event.touchX, Event.touchY and Event.pressure are normalized to 0..1.
	**/
	final TouchDown = 200;

	/**
		A finger has lifted from the screen.

		Event.touchId and Event.fingerId identify the device and finger.
		Event.touchX, Event.touchY and Event.pressure are normalized to 0..1.
	**/
	final TouchUp = 201;

	/**
		A finger has moved while touching the screen.

		Event.touchId and Event.fingerId identify the device and finger.
		Event.touchX, Event.touchY and Event.pressure are normalized to 0..1.
		Event.touchDX and Event.touchDY contain normalized movement.
	**/
	final TouchMove = 202;

	/** A touch was canceled. Treat as TouchUp and release the finger's state. **/
	final TouchCanceled = 203;

	/**
		A joystick axis has changed value.

		Event.reference identifies the joystick; Event.button identifies the axis.
		Event.value contains the raw signed axis value.
	**/
	final JoystickAxisMotion = 300;

	/**
		A joystick trackball has moved.

		Event.reference identifies the joystick; Event.button identifies the trackball.
		Event.mouseXRel and Event.mouseYRel contain the relative movement.
	**/
	final JoystickBallMotion = 301;

	/**
		A joystick directional hat has changed position.

		Event.reference identifies the joystick; Event.button identifies the hat.
		Event.value contains the native direction flags, or zero for the centered position.
	**/
	final JoystickHatMotion = 302;

	/**
		A joystick button has been pressed.
		Event.reference identifies the joystick; Event.button identifies the button.
	**/
	final JoystickButtonDown = 303;

	/**
		A joystick button has been released.
		Event.reference identifies the joystick; Event.button identifies the button.
	**/
	final JoystickButtonUp = 304;

	/**
		A joystick has become available.
		Event.reference contains its instance ID.
	**/
	final JoystickAdded = 305;

	/**
		A joystick has been disconnected.
		Event.reference contains its instance ID.
	**/
	final JoystickRemoved = 306;

	/**
		A sequence of dropped files or text has begun for a window.
		Individual items follow as DropFile or DropText events.
	**/
	final DropStart = 400;

	/**
		A file has been dropped onto a window.
		Event.dropFile contains its path as null-terminated UTF-8 bytes.
	**/
	final DropFile = 401;

	/**
		Text has been dropped onto a window.
		Event.dropFile contains the dropped text as null-terminated UTF-8 bytes.
	**/
	final DropText = 402;

	/**
		A sequence of dropped files or text has completed for a window.
	**/
	final DropEnd = 403;

	/**
		The keyboard mapping has changed, for example after switching layouts.
		Key codes for physical keys may now differ.
	**/
	final KeyMapChanged = 500;

	/** A pen entered proximity. Event.penId identifies it; Event.penState contains input flags. **/
	final PenProximityIn = 600;

	/** A pen left proximity. Event.penId identifies it; Event.penState contains input flags. **/
	final PenProximityOut = 601;

	/** The pen tip touched the surface. Event.penX/Y, penState and penEraser describe the input. **/
	final PenDown = 602;

	/** The pen tip left the surface. Event.penX/Y, penState and penEraser describe the input. **/
	final PenUp = 603;

	/** A pen moved, including hovering. Event.penX/Y are window coordinates; penState contains input flags. **/
	final PenMove = 604;

	/** A pen button was pressed. Event.button is one-based; penX/Y and penState describe the input. **/
	final PenButtonDown = 605;

	/** A pen button was released. Event.button is one-based; penX/Y and penState describe the input. **/
	final PenButtonUp = 606;

	/** A pen axis changed. Event.penAxis and penValue contain pressure, tilt or another axis measurement. **/
	final PenAxis = 607;
}
