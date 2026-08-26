#include <SDL3/SDL.h>
#include "native_window.h"

bool limen_get_native_window(void* handle, limen_native_window* out) {
	SDL_PropertiesID properties;
	SDL_Window* window = handle;

	if (window == nullptr || out == nullptr)
		return false;

	*out = (limen_native_window) {};
	properties = SDL_GetWindowProperties(window);

#if defined(SDL_PLATFORM_WINDOWS)
	out->type = LIMEN_NATIVE_WIN32;
	out->win32.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WIN32_HWND_POINTER, nullptr);
	out->win32.instance = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WIN32_INSTANCE_POINTER, nullptr);
	return out->win32.window != nullptr;
#elif defined(SDL_PLATFORM_MACOS)
	out->type = LIMEN_NATIVE_COCOA;
	out->cocoa.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_COCOA_WINDOW_POINTER, nullptr);
	return out->cocoa.window != nullptr;
#elif defined(SDL_PLATFORM_ANDROID)
	out->type = LIMEN_NATIVE_ANDROID;
	out->android.window = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_ANDROID_WINDOW_POINTER, nullptr);
	return out->android.window != nullptr;
#elif defined(SDL_PLATFORM_LINUX)
	out->wayland.display = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WAYLAND_DISPLAY_POINTER, nullptr);
	out->wayland.surface = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WAYLAND_SURFACE_POINTER, nullptr);
	if (out->wayland.display != nullptr && out->wayland.surface != nullptr) {
		out->type = LIMEN_NATIVE_WAYLAND;
		return true;
	}

	out->x11.display = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_X11_DISPLAY_POINTER, nullptr);
	out->x11.window = (uint64_t)SDL_GetNumberProperty(properties, SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
	if (out->x11.display != nullptr && out->x11.window != 0) {
		out->type = LIMEN_NATIVE_X11;
		return true;
	}
#endif

	out->type = LIMEN_NATIVE_UNKNOWN;
	return false;
}
