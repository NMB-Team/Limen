#include "internal.h"

bool limen_hint_window_grab_keyboard = false;

HL_PRIM bool HL_NAME(hint_value)(vbyte* name, vbyte* value) {
	if (strcmp((char*)name, "SDL_GRAB_KEYBOARD") == 0)
		limen_hint_window_grab_keyboard = value != nullptr;
	return SDL_SetHint((char*)name, (char*)value);
}
DEFINE_PRIM(_BOOL, hint_value, _BYTES _BYTES);
