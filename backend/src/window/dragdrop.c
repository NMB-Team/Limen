#include "../core/internal.h"

HL_PRIM void HL_NAME(set_drag_and_drop_enabled)(bool enabled) {
	SDL_SetEventEnabled(SDL_EVENT_DROP_BEGIN, enabled);
	SDL_SetEventEnabled(SDL_EVENT_DROP_FILE, enabled);
	SDL_SetEventEnabled(SDL_EVENT_DROP_TEXT, enabled);
	SDL_SetEventEnabled(SDL_EVENT_DROP_COMPLETE, enabled);
}
DEFINE_PRIM(_VOID, set_drag_and_drop_enabled, _BOOL);

HL_PRIM bool HL_NAME(get_drag_and_drop_enabled)() {
	return SDL_EventEnabled(SDL_EVENT_DROP_FILE);
}
DEFINE_PRIM(_BOOL, get_drag_and_drop_enabled, _NO_ARG);
