#include <SDL3/SDL.h>
#include "native_window.h"
#include <string.h>

bool limen_get_native_window(void* handle, limen_native_window* out) {
	SDL_PropertiesID properties;
	SDL_Window* window = handle;

	if (window == NULL || out == NULL)
		return false;

	memset(out, 0, sizeof(*out));
	properties = SDL_GetWindowProperties(window);

#if defined(SDL_PLATFORM_WINDOWS)
	out->type = LIMEN_NATIVE_WIN32;
	out->win32.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WIN32_HWND_POINTER, NULL);
	out->win32.instance = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, NULL);
	return out->win32.window != NULL;
#elif defined(SDL_PLATFORM_MACOS)
	out->type = LIMEN_NATIVE_COCOA;
	out->cocoa.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, NULL);
	return out->cocoa.window != NULL;
#elif defined(SDL_PLATFORM_ANDROID)
	out->type = LIMEN_NATIVE_ANDROID;
	out->android.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER, NULL);
	return out->android.window != NULL;
#elif defined(SDL_PLATFORM_LINUX)
	out->wayland.display = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, NULL);
	out->wayland.surface = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, NULL);
	if (out->wayland.display != NULL && out->wayland.surface != NULL) {
		out->type = LIMEN_NATIVE_WAYLAND;
		return true;
	}

	out->x11.display = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_X11_DISPLAY_POINTER, NULL);
	out->x11.window = (uint64_t)SDL_GetNumberProperty(properties, SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
	if (out->x11.display != NULL && out->x11.window != 0) {
		out->type = LIMEN_NATIVE_X11;
		return true;
	}
#endif

	out->type = LIMEN_NATIVE_UNKNOWN;
	return false;
}
