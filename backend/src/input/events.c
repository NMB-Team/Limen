#include "../core/internal.h"

static bool text_editing = false;
static vclosure* window_event_watch_callback = nullptr;
static limen_event* window_event_watch_event = nullptr;
static bool window_event_watch_registered = false;

static bool translate_window_event(const SDL_Event* source, limen_event* destination) {
	if (source->type < SDL_EVENT_WINDOW_FIRST || source->type > SDL_EVENT_WINDOW_LAST) {
		return false;
	}

	destination->type = WindowState;
	destination->window = source->window.windowID;
	switch (source->type) {
		case SDL_EVENT_WINDOW_SHOWN:
			destination->state = Show;
			break;
		case SDL_EVENT_WINDOW_HIDDEN:
			destination->state = Hide;
			break;
		case SDL_EVENT_WINDOW_EXPOSED:
			destination->state = Expose;
			destination->value = source->window.data1;
			break;
		case SDL_EVENT_WINDOW_MOVED:
			destination->state = Move;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_RESIZED:
			destination->state = Resize;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
			destination->state = PixelResize;
			destination->mouseX = source->window.data1;
			destination->mouseY = source->window.data2;
			break;
		case SDL_EVENT_WINDOW_MINIMIZED:
			destination->state = Minimize;
			break;
		case SDL_EVENT_WINDOW_MAXIMIZED:
			destination->state = Maximize;
			break;
		case SDL_EVENT_WINDOW_RESTORED:
			destination->state = Restore;
			break;
		case SDL_EVENT_WINDOW_MOUSE_ENTER:
			destination->state = Enter;
			break;
		case SDL_EVENT_WINDOW_MOUSE_LEAVE:
			destination->state = Leave;
			break;
		case SDL_EVENT_WINDOW_FOCUS_GAINED:
			destination->state = Focus;
			break;
		case SDL_EVENT_WINDOW_FOCUS_LOST:
			destination->state = Blur;
			break;
		case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
			destination->state = Close;
			break;
		default:
			return false;
	}
	return true;
}

static bool translate_mouse_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_MOUSE_MOTION:
			destination->type = MouseMove;
			destination->window = source->motion.windowID;
			destination->mouseX = (int)source->motion.x;
			destination->mouseY = (int)source->motion.y;
			destination->mouseXRel = (int)source->motion.xrel;
			destination->mouseYRel = (int)source->motion.yrel;
			return true;
		case SDL_EVENT_MOUSE_BUTTON_DOWN:
		case SDL_EVENT_MOUSE_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_MOUSE_BUTTON_DOWN ? MouseDown : MouseUp;
			destination->window = source->button.windowID;
			destination->button = source->button.button;
			destination->mouseX = (int)source->button.x;
			destination->mouseY = (int)source->button.y;
			return true;
		case SDL_EVENT_MOUSE_WHEEL:
			destination->type = MouseWheel;
			destination->window = source->wheel.windowID;
			destination->wheelDelta = source->wheel.integer_y;
			if (source->wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
				destination->wheelDelta *= -1;
			destination->mouseX = (int)source->wheel.mouse_x;
			destination->mouseY = (int)source->wheel.mouse_y;
			return true;
		default:
			return false;
	}
}

static bool translate_keyboard_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_KEY_DOWN:
		case SDL_EVENT_KEY_UP:
			destination->type = source->type == SDL_EVENT_KEY_DOWN ? KeyDown : KeyUp;
			destination->window = source->key.windowID;
			destination->keyCode = source->key.key;
			destination->scanCode = source->key.scancode;
			destination->modifier = source->key.mod;
			destination->keyRepeat = source->type == SDL_EVENT_KEY_DOWN && source->key.repeat;
			return true;
		case SDL_EVENT_TEXT_EDITING:
			text_editing = true;
			return false;
		case SDL_EVENT_TEXT_INPUT:
			{
				uint32_t key_code = 0;
				size_t length = strlen(source->text.text);
				if (length > sizeof(key_code))
					length = sizeof(key_code);
				memcpy(&key_code, source->text.text, length);
				destination->type = TextInput;
				destination->window = source->text.windowID;
				destination->keyCode = (int)key_code;
				destination->value = 2;
				destination->inputChar = hl_to_utf16(source->text.text);
				return true;
			}
		case SDL_EVENT_KEYMAP_CHANGED:
			destination->type = KeyMapChanged;
			return true;
		default:
			return false;
	}
}

static bool translate_touch_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_FINGER_DOWN:
			destination->type = TouchDown;
			break;
		case SDL_EVENT_FINGER_MOTION:
			destination->type = TouchMove;
			break;
		case SDL_EVENT_FINGER_UP:
			destination->type = TouchUp;
			break;
		case SDL_EVENT_FINGER_CANCELED:
			destination->type = TouchCanceled;
			break;
		default:
			return false;
	}
	destination->window = source->tfinger.windowID;
	destination->mouseX = (int)(source->tfinger.x * 10000);
	destination->mouseY = (int)(source->tfinger.y * 10000);
	destination->reference = (int)source->tfinger.fingerID;
	destination->touchId = (int64_t)source->tfinger.touchID;
	destination->fingerId = (int64_t)source->tfinger.fingerID;
	destination->touchX = source->tfinger.x;
	destination->touchY = source->tfinger.y;
	destination->touchDX = source->tfinger.dx;
	destination->touchDY = source->tfinger.dy;
	destination->pressure = source->tfinger.pressure;
	return true;
}

static bool translate_pen_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_PEN_PROXIMITY_IN:
		case SDL_EVENT_PEN_PROXIMITY_OUT:
			destination->type = source->type == SDL_EVENT_PEN_PROXIMITY_IN ? PenProximityIn : PenProximityOut;
			destination->window = source->pproximity.windowID;
			destination->penId = (int)source->pproximity.which;
			destination->penState = (int)source->pproximity.pen_state;
			return true;
		case SDL_EVENT_PEN_DOWN:
		case SDL_EVENT_PEN_UP:
			destination->type = source->type == SDL_EVENT_PEN_DOWN ? PenDown : PenUp;
			destination->window = source->ptouch.windowID;
			destination->penId = (int)source->ptouch.which;
			destination->penState = (int)source->ptouch.pen_state;
			destination->penX = source->ptouch.x;
			destination->penY = source->ptouch.y;
			destination->penEraser = source->ptouch.eraser;
			return true;
		case SDL_EVENT_PEN_MOTION:
			destination->type = PenMove;
			destination->window = source->pmotion.windowID;
			destination->penId = (int)source->pmotion.which;
			destination->penState = (int)source->pmotion.pen_state;
			destination->penX = source->pmotion.x;
			destination->penY = source->pmotion.y;
			return true;
		case SDL_EVENT_PEN_BUTTON_DOWN:
		case SDL_EVENT_PEN_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_PEN_BUTTON_DOWN ? PenButtonDown : PenButtonUp;
			destination->window = source->pbutton.windowID;
			destination->penId = (int)source->pbutton.which;
			destination->penState = (int)source->pbutton.pen_state;
			destination->penX = source->pbutton.x;
			destination->penY = source->pbutton.y;
			destination->button = source->pbutton.button;
			return true;
		case SDL_EVENT_PEN_AXIS:
			destination->type = PenAxis;
			destination->window = source->paxis.windowID;
			destination->penId = (int)source->paxis.which;
			destination->penState = (int)source->paxis.pen_state;
			destination->penX = source->paxis.x;
			destination->penY = source->paxis.y;
			destination->penAxis = source->paxis.axis;
			destination->penValue = source->paxis.value;
			return true;
		default:
			return false;
	}
}

static bool translate_gamepad_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_GAMEPAD_ADDED:
			destination->type = GControllerAdded;
			destination->reference = source->gdevice.which;
			return true;
		case SDL_EVENT_GAMEPAD_REMOVED:
			destination->type = GControllerRemoved;
			destination->reference = source->gdevice.which;
			return true;
		case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
		case SDL_EVENT_GAMEPAD_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_GAMEPAD_BUTTON_DOWN ? GControllerDown : GControllerUp;
			destination->reference = source->gbutton.which;
			destination->button = source->gbutton.button;
			return true;
		case SDL_EVENT_GAMEPAD_AXIS_MOTION:
			destination->type = GControllerAxis;
			destination->reference = source->gaxis.which;
			destination->button = source->gaxis.axis;
			destination->value = source->gaxis.value;
			return true;
		default:
			return false;
	}
}

static bool translate_joystick_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_JOYSTICK_AXIS_MOTION:
			destination->type = JoystickAxisMotion;
			destination->reference = source->jaxis.which;
			destination->button = source->jaxis.axis;
			destination->value = source->jaxis.value;
			return true;
		case SDL_EVENT_JOYSTICK_BALL_MOTION:
			destination->type = JoystickBallMotion;
			destination->reference = source->jball.which;
			destination->button = source->jball.ball;
			destination->mouseXRel = source->jball.xrel;
			destination->mouseYRel = source->jball.yrel;
			return true;
		case SDL_EVENT_JOYSTICK_HAT_MOTION:
			destination->type = JoystickHatMotion;
			destination->reference = source->jhat.which;
			destination->button = source->jhat.hat;
			destination->value = source->jhat.value;
			return true;
		case SDL_EVENT_JOYSTICK_BUTTON_DOWN:
		case SDL_EVENT_JOYSTICK_BUTTON_UP:
			destination->type = source->type == SDL_EVENT_JOYSTICK_BUTTON_DOWN ? JoystickButtonDown : JoystickButtonUp;
			destination->reference = source->jbutton.which;
			destination->button = source->jbutton.button;
			return true;
		case SDL_EVENT_JOYSTICK_ADDED:
		case SDL_EVENT_JOYSTICK_REMOVED:
			destination->type = source->type == SDL_EVENT_JOYSTICK_ADDED ? JoystickAdded : JoystickRemoved;
			destination->reference = source->jdevice.which;
			return true;
		default:
			return false;
	}
}

static bool translate_drop_event(const SDL_Event* source, limen_event* destination) {
	switch (source->type) {
		case SDL_EVENT_DROP_BEGIN:
			destination->type = DropStart;
			break;
		case SDL_EVENT_DROP_FILE:
		case SDL_EVENT_DROP_TEXT:
			destination->type = source->type == SDL_EVENT_DROP_FILE ? DropFile : DropText;
			destination->dropFile = hl_copy_bytes(source->drop.data, (int)strlen(source->drop.data) + 1);
			break;
		case SDL_EVENT_DROP_COMPLETE:
			destination->type = DropEnd;
			break;
		default:
			return false;
	}
	destination->window = source->drop.windowID;
	return true;
}

bool limen_translate_event(const SDL_Event* source, limen_event* destination) {
	destination->timestamp = (int64_t)source->common.timestamp;
	if (source->type == SDL_EVENT_QUIT) {
		destination->type = Quit;
		return true;
	}
	return translate_window_event(source, destination) || translate_mouse_event(source, destination) || translate_keyboard_event(source, destination) || translate_touch_event(source, destination) || translate_gamepad_event(source, destination) ||
	       translate_joystick_event(source, destination) || translate_drop_event(source, destination) || translate_pen_event(source, destination);
}

static bool SDLCALL window_event_watch(void* userdata, SDL_Event* event) {
	(void)userdata;
	switch (event->type) {
		case SDL_EVENT_WINDOW_EXPOSED:
		case SDL_EVENT_WINDOW_MOVED:
		case SDL_EVENT_WINDOW_RESIZED:
		case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
			if (window_event_watch_callback && window_event_watch_event && limen_translate_event(event, window_event_watch_event)) {
				vdynamic* arguments[1] = { (vdynamic*)window_event_watch_event };
				hl_dyn_call(window_event_watch_callback, arguments, 1);
			}
			break;
		default:
			break;
	}
	return true;
}

HL_PRIM bool HL_NAME(event_loop)(limen_event* event) {
	SDL_Event source;
	while (SDL_PollEvent(&source))
		if (limen_translate_event(&source, event))
			return true;
	return false;
}
DEFINE_PRIM(_BOOL, event_loop, _DYN);

#ifdef LIMEN_BUILD_TESTS
HL_PRIM bool HL_NAME(test_queue_input_events)() {
	SDL_Event source = {};
	source.type = SDL_EVENT_FINGER_MOTION;
	source.tfinger.windowID = 7;
	source.tfinger.touchID = UINT64_C(0xf123456789abcdef);
	source.tfinger.fingerID = UINT64_C(0x123456789abcdef0);
	source.tfinger.x = 0.125f;
	source.tfinger.y = 0.875f;
	source.tfinger.dx = -0.0625f;
	source.tfinger.dy = 0.03125f;
	source.tfinger.pressure = 0.5f;
	if (!SDL_PushEvent(&source))
		return false;
	source = (SDL_Event) {};
	source.type = SDL_EVENT_PEN_AXIS;
	source.paxis.windowID = 8;
	source.paxis.which = 0xf1234567;
	source.paxis.pen_state = SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_ERASER_TIP | SDL_PEN_INPUT_IN_PROXIMITY;
	source.paxis.x = 12.25f;
	source.paxis.y = 34.5f;
	source.paxis.axis = SDL_PEN_AXIS_XTILT;
	source.paxis.value = -45.5f;
	return SDL_PushEvent(&source);
}
DEFINE_PRIM(_BOOL, test_queue_input_events, _NO_ARG);
#endif

HL_PRIM int HL_NAME(event_poll)(SDL_Event* event) {
	return SDL_PollEvent(event);
}
DEFINE_PRIM(_I32, event_poll, _STRUCT);

HL_PRIM void HL_NAME(set_window_event_watch)(vclosure* callback, limen_event* event) {
	if (window_event_watch_callback == nullptr)
		hl_add_root(&window_event_watch_callback);
	if (window_event_watch_event == nullptr)
		hl_add_root(&window_event_watch_event);
	if (callback != nullptr && !window_event_watch_registered) {
		SDL_AddEventWatch(window_event_watch, nullptr);
		window_event_watch_registered = true;
	} else if (callback == nullptr && window_event_watch_registered) {
		SDL_RemoveEventWatch(window_event_watch, nullptr);
		window_event_watch_registered = false;
	}
	window_event_watch_callback = callback;
	window_event_watch_event = callback != nullptr ? event : nullptr;
}
DEFINE_PRIM(_VOID, set_window_event_watch, _DYN _DYN);

HL_PRIM bool HL_NAME(is_text_input_shown)() {
	bool result = text_editing;
	text_editing = false;
	return result;
}
DEFINE_PRIM(_BOOL, is_text_input_shown, _NO_ARG);
