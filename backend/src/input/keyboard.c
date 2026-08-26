#include "../core/internal.h"

HL_PRIM void HL_NAME(text_input)(bool enable) {
	SDL_Window** windows;

	SDL_SetEventEnabled(SDL_EVENT_TEXT_INPUT, true);
	SDL_SetEventEnabled(SDL_EVENT_TEXT_EDITING, true);
	windows = SDL_GetWindows(nullptr);
	if (windows == nullptr)
		return;
	for (int i = 0; windows[i] != nullptr; i++)
		if (enable)
			SDL_StartTextInput(windows[i]);
		else
			SDL_StopTextInput(windows[i]);
	SDL_free(windows);
}

HL_PRIM const char* HL_NAME(detect_keyboard_layout)() {
	char q = SDL_GetKeyFromScancode(SDL_SCANCODE_Q, SDL_KMOD_NONE, false);
	char w = SDL_GetKeyFromScancode(SDL_SCANCODE_W, SDL_KMOD_NONE, false);
	char y = SDL_GetKeyFromScancode(SDL_SCANCODE_Y, SDL_KMOD_NONE, false);

	if (q == 'q' && w == 'w' && y == 'y')
		return "qwerty";
	if (q == 'a' && w == 'z' && y == 'y')
		return "azerty";
	if (q == 'q' && w == 'w' && y == 'z')
		return "qwertz";
	if (q == 'q' && w == 'z' && y == 'y')
		return "qzerty";
	return "unknown";
}

DEFINE_PRIM(_VOID, text_input, _BOOL);
DEFINE_PRIM(_BYTES, detect_keyboard_layout, _NO_ARG);
