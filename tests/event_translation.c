#include "core/internal.h"
#include <assert.h>

static limen_event translate(SDL_Event* source) {
	limen_event destination = {};
	assert(limen_translate_event(source, &destination));
	assert(destination.timestamp == (int64_t)source->common.timestamp);
	return destination;
}

static void test_touch_events(void) {
	const SDL_EventType types[] = { SDL_EVENT_FINGER_DOWN, SDL_EVENT_FINGER_UP, SDL_EVENT_FINGER_MOTION, SDL_EVENT_FINGER_CANCELED };
	const limen_event_type expected[] = { TouchDown, TouchUp, TouchMove, TouchCanceled };
	for (int i = 0; i < 4; i++) {
		SDL_Event source = {};
		source.type = types[i];
		source.tfinger.timestamp = 4500000000;
		source.tfinger.windowID = 7;
		source.tfinger.touchID = UINT64_C(0xf123456789abcdef);
		source.tfinger.fingerID = UINT64_C(0x123456789abcdef0);
		source.tfinger.x = 0.125f;
		source.tfinger.y = 0.875f;
		source.tfinger.dx = -0.0625f;
		source.tfinger.dy = 0.03125f;
		source.tfinger.pressure = 0.5f;
		limen_event destination = translate(&source);
		assert(destination.type == expected[i]);
		assert(destination.window == 7);
		assert((uint64_t)destination.touchId == source.tfinger.touchID);
		assert((uint64_t)destination.fingerId == source.tfinger.fingerID);
		assert(destination.touchX == 0.125);
		assert(destination.touchY == 0.875);
		assert(destination.touchDX == -0.0625);
		assert(destination.touchDY == 0.03125);
		assert(destination.pressure == 0.5);
	}
}

static void test_pen_events(void) {
	const SDL_PenID id = 0xf1234567;
	const SDL_PenInputFlags flags = SDL_PEN_INPUT_DOWN | SDL_PEN_INPUT_BUTTON_1 | SDL_PEN_INPUT_ERASER_TIP | SDL_PEN_INPUT_IN_PROXIMITY;
	SDL_Event source = {};
	for (int i = 0; i < 2; i++) {
		source = (SDL_Event) {};
		source.type = i == 0 ? SDL_EVENT_PEN_PROXIMITY_IN : SDL_EVENT_PEN_PROXIMITY_OUT;
		source.pproximity.timestamp = 5500000000;
		source.pproximity.windowID = 8;
		source.pproximity.which = id;
		source.pproximity.pen_state = i == 0 ? flags : 0;
		limen_event destination = translate(&source);
		assert(destination.type == (i == 0 ? PenProximityIn : PenProximityOut));
		assert(destination.window == 8);
		assert((SDL_PenID)destination.penId == id);
		assert((SDL_PenInputFlags)destination.penState == source.pproximity.pen_state);

		source = (SDL_Event) {};
		source.type = i == 0 ? SDL_EVENT_PEN_DOWN : SDL_EVENT_PEN_UP;
		source.ptouch.windowID = 8;
		source.ptouch.which = id;
		source.ptouch.pen_state = flags;
		source.ptouch.x = 12.25f;
		source.ptouch.y = 34.5f;
		source.ptouch.eraser = true;
		destination = translate(&source);
		assert(destination.type == (i == 0 ? PenDown : PenUp));
		assert(destination.window == 8);
		assert((SDL_PenID)destination.penId == id);
		assert((SDL_PenInputFlags)destination.penState == flags);
		assert(destination.penX == 12.25 && destination.penY == 34.5);
		assert(destination.penEraser);

		source = (SDL_Event) {};
		source.type = i == 0 ? SDL_EVENT_PEN_BUTTON_DOWN : SDL_EVENT_PEN_BUTTON_UP;
		source.pbutton.windowID = 8;
		source.pbutton.which = id;
		source.pbutton.pen_state = flags;
		source.pbutton.x = 12.25f;
		source.pbutton.y = 34.5f;
		source.pbutton.button = 5;
		destination = translate(&source);
		assert(destination.type == (i == 0 ? PenButtonDown : PenButtonUp));
		assert(destination.window == 8);
		assert((SDL_PenID)destination.penId == id);
		assert((SDL_PenInputFlags)destination.penState == flags);
		assert(destination.penX == 12.25 && destination.penY == 34.5);
		assert(destination.button == 5);
	}

	source = (SDL_Event) {};
	source.type = SDL_EVENT_PEN_MOTION;
	source.pmotion.windowID = 9;
	source.pmotion.which = id;
	source.pmotion.pen_state = SDL_PEN_INPUT_IN_PROXIMITY;
	source.pmotion.x = 0.25f;
	source.pmotion.y = -0.5f;
	limen_event destination = translate(&source);
	assert(destination.type == PenMove);
	assert(destination.window == 9);
	assert((SDL_PenID)destination.penId == id);
	assert((SDL_PenInputFlags)destination.penState == SDL_PEN_INPUT_IN_PROXIMITY);
	assert(destination.penX == 0.25 && destination.penY == -0.5);

	const float values[] = { 0.5f, -45.5f, 30.25f, 0.25f, -179.5f, 0.75f, -0.125f };
	for (int axis = 0; axis < SDL_PEN_AXIS_COUNT; axis++) {
		source = (SDL_Event) {};
		source.type = SDL_EVENT_PEN_AXIS;
		source.paxis.windowID = 10;
		source.paxis.which = id;
		source.paxis.pen_state = flags;
		source.paxis.x = 12.25f;
		source.paxis.y = 34.5f;
		source.paxis.axis = (SDL_PenAxis)axis;
		source.paxis.value = values[axis];
		destination = translate(&source);
		assert(destination.type == PenAxis);
		assert(destination.window == 10);
		assert((SDL_PenID)destination.penId == id);
		assert((SDL_PenInputFlags)destination.penState == flags);
		assert(destination.penX == 12.25 && destination.penY == 34.5);
		assert(destination.penAxis == axis);
		assert(destination.penValue == values[axis]);
	}
}

int main(void) {
	test_touch_events();
	test_pen_events();
	SDL_Event source = {};

	source.type = SDL_EVENT_WINDOW_RESIZED;
	source.window.timestamp = 1500000000;
	source.window.windowID = 4;
	source.window.data1 = 1280;
	source.window.data2 = 720;
	limen_event destination = translate(&source);
	assert(destination.type == WindowState);
	assert(destination.state == Resize);
	assert(destination.window == 4);
	assert(destination.mouseX == 1280);
	assert(destination.mouseY == 720);

	source = (SDL_Event) {};
	source.type = SDL_EVENT_KEY_DOWN;
	source.key.timestamp = 2500000000;
	source.key.windowID = 5;
	source.key.key = SDLK_A;
	source.key.scancode = SDL_SCANCODE_A;
	source.key.mod = SDL_KMOD_LSHIFT;
	source.key.repeat = true;
	destination = translate(&source);
	assert(destination.type == KeyDown);
	assert(destination.window == 5);
	assert(destination.keyCode == SDLK_A);
	assert(destination.scanCode == SDL_SCANCODE_A);
	assert(destination.modifier == SDL_KMOD_LSHIFT);
	assert(destination.keyRepeat);

	source = (SDL_Event) {};
	source.type = SDL_EVENT_MOUSE_WHEEL;
	source.wheel.timestamp = 3500000000;
	source.wheel.windowID = 6;
	source.wheel.integer_y = 2;
	source.wheel.mouse_x = 42;
	source.wheel.mouse_y = 24;
	destination = translate(&source);
	assert(destination.type == MouseWheel);
	assert(destination.window == 6);
	assert(destination.wheelDelta == 2);
	assert(destination.mouseX == 42);
	assert(destination.mouseY == 24);

	source = (SDL_Event) {};
	source.type = SDL_EVENT_FINGER_MOTION;
	source.tfinger.timestamp = 4500000000;
	source.tfinger.windowID = 7;
	source.tfinger.fingerID = 9;
	source.tfinger.x = 0.25f;
	source.tfinger.y = 0.75f;
	destination = translate(&source);
	assert(destination.type == TouchMove);
	assert(destination.window == 7);
	assert(destination.reference == 9);
	assert(destination.mouseX == 2500);
	assert(destination.mouseY == 7500);

	source = (SDL_Event) {};
	source.type = SDL_EVENT_GAMEPAD_AXIS_MOTION;
	source.gaxis.timestamp = 5500000000;
	source.gaxis.which = 10;
	source.gaxis.axis = SDL_GAMEPAD_AXIS_LEFTX;
	source.gaxis.value = 1234;
	destination = translate(&source);
	assert(destination.type == GControllerAxis);
	assert(destination.reference == 10);
	assert(destination.button == SDL_GAMEPAD_AXIS_LEFTX);
	assert(destination.value == 1234);

	source = (SDL_Event) {};
	source.type = SDL_EVENT_JOYSTICK_BUTTON_DOWN;
	source.jbutton.timestamp = 6500000000;
	source.jbutton.which = 11;
	source.jbutton.button = 3;
	destination = translate(&source);
	assert(destination.type == JoystickButtonDown);
	assert(destination.reference == 11);
	assert(destination.button == 3);
	return 0;
}
