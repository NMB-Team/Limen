#include "borderless.h"
#include <SDL3/SDL.h>
#include <stdlib.h>
#include <windows.h>

#define LIMEN_BORDERLESS_SAVE_PROPERTY "hashlink.borderless_save"

typedef struct {
	int x;
	int y;
	int width;
	int height;
	LONG style;
	bool maximized;
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
	if (saved == NULL || mode == 2)
		return true;

	SetWindowLong(native, GWL_STYLE, saved->style);
	if (saved->maximized) {
		WINDOWPLACEMENT placement = { sizeof(placement) };
		placement.showCmd = SW_SHOWMAXIMIZED;
		placement.rcNormalPosition.left = saved->x;
		placement.rcNormalPosition.top = saved->y;
		placement.rcNormalPosition.right = saved->x + saved->width;
		placement.rcNormalPosition.bottom = saved->y + saved->height;
		SetWindowPlacement(native, &placement);
		SetWindowPos(native, NULL, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE | SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
	} else {
		SetWindowPos(native, NULL, saved->x, saved->y, saved->width, saved->height, SWP_NOOWNERZORDER | SWP_FRAMECHANGED | SWP_SHOWWINDOW);
		SDL_SetWindowSize(window, saved->width, saved->height);
	}

	free(saved);
	SDL_SetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	if (mode == 1)
		SDL_SyncWindow(window);
	return true;
}

bool limen_windows_set_borderless_fixed(SDL_Window* window) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	limen_saved_window* saved = (limen_saved_window*)SDL_GetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, NULL);
	HWND native = get_native_window(window);
	HMONITOR monitor;
	MONITORINFO monitor_info = { sizeof(monitor_info) };
	RECT rectangle;

	if (native == NULL)
		return false;

	monitor = MonitorFromWindow(native, MONITOR_DEFAULTTONEAREST);
	if (!GetMonitorInfo(monitor, &monitor_info))
		return false;

	if (saved == NULL) {
		WINDOWPLACEMENT placement = { sizeof(placement) };
		bool maximized = IsZoomed(native) != 0;
		if (maximized && GetWindowPlacement(native, &placement))
			rectangle = placement.rcNormalPosition;
		else
			GetWindowRect(native, &rectangle);

		saved = (limen_saved_window*)malloc(sizeof(*saved));
		saved->x = rectangle.left;
		saved->y = rectangle.top;
		saved->width = rectangle.right - rectangle.left;
		saved->height = rectangle.bottom - rectangle.top;
		saved->style = GetWindowLong(native, GWL_STYLE);
		saved->maximized = maximized;
		SDL_SetPointerProperty(properties, LIMEN_BORDERLESS_SAVE_PROPERTY, saved);
	}

	SDL_SetWindowFullscreen(window, false);
	if (saved->maximized) {
		SDL_RestoreWindow(window);
		ShowWindow(native, SW_RESTORE);
	}
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
