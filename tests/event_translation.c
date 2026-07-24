#include "core/internal.h"
#include <assert.h>
#include <string.h>

static limen_event translate(SDL_Event* source) {
	limen_event destination;
	memset(&destination, 0, sizeof(destination));
	assert(limen_translate_event(source, &destination));
	assert(destination.timestamp == (double)source->common.timestamp / 1000000000.0);
	return destination;
}

int main(void) {
	SDL_Event source;
	memset(&source, 0, sizeof(source));

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

	memset(&source, 0, sizeof(source));
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

	memset(&source, 0, sizeof(source));
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

	memset(&source, 0, sizeof(source));
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

	memset(&source, 0, sizeof(source));
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

	memset(&source, 0, sizeof(source));
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
