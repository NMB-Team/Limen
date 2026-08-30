#include "../core/internal.h"

static bool relative_mouse_mode = false;

HL_PRIM int HL_NAME(set_relative_mouse_mode)(bool enable) {
	int result = 0;
	SDL_Window** windows = SDL_GetWindows(nullptr);
	if (windows != nullptr) {
		for (int i = 0; windows[i] != nullptr; i++)
			if (!SDL_SetWindowRelativeMouseMode(windows[i], enable))
				result = -1;
		SDL_free(windows);
	}
	if (result == 0)
		relative_mouse_mode = enable;
	return result;
}
DEFINE_PRIM(_I32, set_relative_mouse_mode, _BOOL);

HL_PRIM bool HL_NAME(get_relative_mouse_mode)() {
	return relative_mouse_mode;
}
DEFINE_PRIM(_BOOL, get_relative_mouse_mode, _NO_ARG);

HL_PRIM int HL_NAME(capture_mouse)(bool enable) {
	return SDL_CaptureMouse(enable);
}
DEFINE_PRIM(_I32, capture_mouse, _BOOL);

HL_PRIM int HL_NAME(warp_mouse_global)(int x, int y) {
	return SDL_WarpMouseGlobal((float)x, (float)y);
}
DEFINE_PRIM(_I32, warp_mouse_global, _I32 _I32);

HL_PRIM void HL_NAME(warp_mouse_in_window)(SDL_Window* window, int x, int y) {
	SDL_WarpMouseInWindow(window, (float)x, (float)y);
}
DEFINE_PRIM(_VOID, warp_mouse_in_window, TWIN _I32 _I32);

HL_PRIM void HL_NAME(set_window_grab)(SDL_Window* window, bool grabbed) {
	if (limen_hint_window_grab_keyboard)
		SDL_SetWindowKeyboardGrab(window, grabbed);
	SDL_SetWindowMouseGrab(window, grabbed);
}
DEFINE_PRIM(_VOID, set_window_grab, TWIN _BOOL);

HL_PRIM bool HL_NAME(get_window_grab)(SDL_Window* window) {
	return SDL_GetWindowMouseGrab(window);
}
DEFINE_PRIM(_BOOL, get_window_grab, TWIN);

HL_PRIM int HL_NAME(get_global_mouse_state)(int* x, int* y) {
	float fx;
	float fy;
	SDL_MouseButtonFlags buttons = SDL_GetGlobalMouseState(&fx, &fy);
	*x = (int)fx;
	*y = (int)fy;
	return (int)buttons;
}
DEFINE_PRIM(_I32, get_global_mouse_state, _REF(_I32) _REF(_I32));

HL_PRIM int HL_NAME(get_relative_mouse_state)(int* x, int* y) {
	float fx;
	float fy;
	SDL_MouseButtonFlags buttons = SDL_GetRelativeMouseState(&fx, &fy);
	*x = (int)fx;
	*y = (int)fy;
	return (int)buttons;
}
DEFINE_PRIM(_I32, get_relative_mouse_state, _REF(_I32) _REF(_I32));

HL_PRIM void HL_NAME(set_mouse_motion_events)(bool enabled) {
	SDL_SetEventEnabled(SDL_EVENT_MOUSE_MOTION, enabled);
}
DEFINE_PRIM(_VOID, set_mouse_motion_events, _BOOL);
