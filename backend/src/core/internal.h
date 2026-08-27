#pragma once

#define HL_NAME(n) limen_##n

#include "hlsystem.h"
#include <SDL3/SDL.h>
#include <SDL3/SDL_gamepad.h>
#include <hl.h>
#include <stdint.h>
#include <string.h>

#ifndef SDL_MAJOR_VERSION
#error "SDL3 SDK not found"
#endif

#define TWIN _ABSTRACT(limen_window)
#define TGL _ABSTRACT(limen_gl)
#define _SURF _ABSTRACT(limen_surface)

typedef enum {
	Quit,
	MouseMove,
	MouseLeave,
	MouseDown,
	MouseUp,
	MouseWheel,
	WindowState,
	KeyDown,
	KeyUp,
	TextInput,
	GControllerAdded = 100,
	GControllerRemoved,
	GControllerDown,
	GControllerUp,
	GControllerAxis,
	TouchDown = 200,
	TouchUp,
	TouchMove,
	JoystickAxisMotion = 300,
	JoystickBallMotion,
	JoystickHatMotion,
	JoystickButtonDown,
	JoystickButtonUp,
	JoystickAdded,
	JoystickRemoved,
	DropStart = 400,
	DropFile,
	DropText,
	DropEnd,
	KeyMapChanged = 500,
} limen_event_type;

typedef enum {
	Show,
	Hide,
	Expose,
	Move,
	Resize,
	Minimize,
	Maximize,
	Restore,
	Enter,
	Leave,
	Focus,
	Blur,
	Close,
	PixelResize,
} limen_window_state_change;

typedef struct {
	hl_type* t;
	limen_event_type type;
	int mouseX;
	int mouseY;
	int mouseXRel;
	int mouseYRel;
	int button;
	int wheelDelta;
	limen_window_state_change state;
	int keyCode;
	int scanCode;
	int modifier;
	bool keyRepeat;
	int reference;
	int value;
	int __unused;
	int window;
	vbyte* dropFile;
	uchar* inputChar;
	int64_t timestamp;
} limen_event;

extern bool limen_hint_window_grab_keyboard;

bool limen_translate_event(const SDL_Event* source, limen_event* destination);
SDL_DisplayID limen_display_id_from_index(int index);
int limen_display_index_from_id(SDL_DisplayID display);
