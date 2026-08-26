#include "theme.h"
#include <SDL3/SDL.h>
#include <dwmapi.h>
#include <windows.h>

bool limen_windows_set_dark_mode(SDL_Window* window, bool enabled) {
	HWND native = (HWND)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_WIN32_HWND_POINTER, nullptr);
	BOOL value = enabled;
	HRESULT result;

	if (native == nullptr)
		return false;

	result = DwmSetWindowAttribute(native, 20, &value, sizeof(value));
	if (FAILED(result))
		result = DwmSetWindowAttribute(native, 19, &value, sizeof(value));
	return SUCCEEDED(result);
}
