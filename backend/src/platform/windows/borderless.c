#include "borderless.h"
#include <SDL3/SDL.h>
#include <stdlib.h>
#include <windows.h>

#define LIMEN_BORDERLESS_SAVE_PROPERTY "limen.borderless_save"

typedef struct {
	WINDOWPLACEMENT placement;
	LONG style;
} limen_saved_window;

static HWND get_native_window(SDL_Window* window) {
	return (HWND)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_WIN32_HWND_POINTER, NULL);
}

bool limen_windows_prepare_fullscreen(SDL_Window* window, int mode) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	limen_saved_window* saved = (limen_saved_window*)SDL_GetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	HWND native = get_native_window(window);

	if (native == NULL)
		return false;

	// mode == 2 means we're ENTERING WindowedFullscreen, so nothing should be restored yet
	if (saved == NULL || mode == 2)
		return true;

	SetWindowLong(native, GWL_STYLE, saved->style);

	WINDOWPLACEMENT placement = saved->placement;
	placement.length = sizeof(WINDOWPLACEMENT);

	SetWindowPlacement(native, &placement);

	SetWindowPos(native, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);

	free(saved);
	SDL_SetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	return true;
}

bool limen_windows_set_borderless_fixed(SDL_Window* window) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	limen_saved_window* saved = (limen_saved_window*)SDL_GetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	HWND native = get_native_window(window);

	if (native == NULL)
		return false;

	HMONITOR monitor = MonitorFromWindow(native, MONITOR_DEFAULTTONEAREST);
	MONITORINFO monitor_info = { sizeof(monitor_info) };
	if (!GetMonitorInfo(monitor, &monitor_info))
		return false;

	if (saved == NULL) {
		saved = (limen_saved_window*)malloc(sizeof(*saved));

		if (saved == NULL)
			return false;

		saved->placement.length = sizeof(WINDOWPLACEMENT);

		if (!GetWindowPlacement(native, &saved->placement)) {
			free(saved);
			return false;
		}

		saved->style = GetWindowLong(native, GWL_STYLE);
		SDL_SetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, saved);
	}

	SDL_SetWindowFullscreen(window, false);

	if (IsZoomed(native))
		ShowWindow(native, SW_RESTORE);
	SetWindowLong(native, GWL_STYLE, WS_POPUP | WS_VISIBLE);
	SetWindowPos(native, NULL, monitor_info.rcMonitor.left, monitor_info.rcMonitor.top, monitor_info.rcMonitor.right - monitor_info.rcMonitor.left, monitor_info.rcMonitor.bottom - monitor_info.rcMonitor.top + 2,
	             SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
	return true;
}

void limen_windows_cleanup_borderless(SDL_Window* window) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	limen_saved_window* saved = (limen_saved_window*)SDL_GetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	if (saved != NULL) {
		free(saved);
		SDL_SetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	}
}
