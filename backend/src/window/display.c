#include "../core/internal.h"

#ifdef HL_WIN_DESKTOP
#include <windows.h>
#endif

SDL_DisplayID limen_display_id_from_index(int index) {
	int count;
	SDL_DisplayID result = 0;
	SDL_DisplayID primary = SDL_GetPrimaryDisplay();
	SDL_DisplayID* displays = SDL_GetDisplays(&count);

	if (index == 0) {
		result = primary;
	} else if (displays != nullptr && index > 0) {
		int current = 1;

		for (int i = 0; i < count; i++) {
			if (displays[i] == primary)
				continue;
			if (current++ == index) {
				result = displays[i];
				break;
			}
		}
	}

	SDL_free(displays);

	return result;
}

int limen_display_index_from_id(SDL_DisplayID display) {
	int count;
	SDL_DisplayID primary = SDL_GetPrimaryDisplay();
	SDL_DisplayID* displays = SDL_GetDisplays(&count);

	if (display == primary) {
		SDL_free(displays);

		return 0;
	}

	if (displays != nullptr) {
		int current = 1;

		for (int i = 0; i < count; i++) {
			if (displays[i] == primary)
				continue;
			if (displays[i] == display) {
				SDL_free(displays);

				return current;
			}

			current++;
		}
	}

	SDL_free(displays);

	return -1;
}

SDL_DisplayID limen_display_for_window(SDL_Window* window) {
#ifdef HL_WIN_DESKTOP
	HWND native = (HWND)SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_PROP_WINDOW_WIN32_HWND_POINTER, nullptr);
	HMONITOR monitor = native != nullptr ? MonitorFromWindow(native, MONITOR_DEFAULTTONEAREST) : nullptr;

	if (monitor != nullptr) {
		int count;
		SDL_DisplayID* displays = SDL_GetDisplays(&count);
		SDL_DisplayID result = 0;

		for (int i = 0; i < count; i++) {
			if (SDL_GetPointerProperty(SDL_GetDisplayProperties(displays[i]), SDL_PROP_DISPLAY_WINDOWS_HMONITOR_POINTER, nullptr) == monitor) {
				result = displays[i];
				break;
			}
		}

		SDL_free(displays);

		if (result != 0)
			return result;
	}
#endif

	return SDL_GetDisplayForWindow(window);
}

static const SDL_DisplayMode* current_mode_for_window(SDL_Window* window) {
	SDL_DisplayID display = window != nullptr ? limen_display_for_window(window) : limen_display_id_from_index(0);
	return display != 0 ? SDL_GetCurrentDisplayMode(display) : nullptr;
}

HL_PRIM int HL_NAME(get_screen_width)() {
	const SDL_DisplayMode* mode = current_mode_for_window(nullptr);
	return mode != nullptr ? mode->w : 0;
}
DEFINE_PRIM(_I32, get_screen_width, _NO_ARG);

HL_PRIM int HL_NAME(get_screen_height)() {
	const SDL_DisplayMode* mode = current_mode_for_window(nullptr);
	return mode != nullptr ? mode->h : 0;
}
DEFINE_PRIM(_I32, get_screen_height, _NO_ARG);

HL_PRIM int HL_NAME(get_screen_width_of_window)(SDL_Window* window) {
	const SDL_DisplayMode* mode = current_mode_for_window(window);
	return mode != nullptr ? mode->w : 0;
}
DEFINE_PRIM(_I32, get_screen_width_of_window, TWIN);

HL_PRIM int HL_NAME(get_screen_height_of_window)(SDL_Window* window) {
	const SDL_DisplayMode* mode = current_mode_for_window(window);
	return mode != nullptr ? mode->h : 0;
}
DEFINE_PRIM(_I32, get_screen_height_of_window, TWIN);

HL_PRIM double HL_NAME(get_refresh_rate)(SDL_Window* window) {
	const SDL_DisplayMode* mode = current_mode_for_window(window);
	return mode != nullptr ? mode->refresh_rate : 0;
}
DEFINE_PRIM(_F64, get_refresh_rate, TWIN);

HL_PRIM varray* HL_NAME(get_displays)() {
	int count;
	SDL_DisplayID* displays = SDL_GetDisplays(&count);

	if (displays == nullptr)
		return nullptr;

	varray* result = hl_alloc_array(&hlt_dynobj, count);

	for (int i = 0; i < count; i++) {
		SDL_DisplayID display = limen_display_id_from_index(i);
		SDL_Rect bounds;
		vdynamic* object = (vdynamic*)hl_alloc_dynobj();
		SDL_GetDisplayBounds(display, &bounds);
		hl_dyn_seti(object, hl_hash_utf8("right"), &hlt_i32, bounds.x + bounds.w);
		hl_dyn_seti(object, hl_hash_utf8("bottom"), &hlt_i32, bounds.y + bounds.h);
		hl_dyn_seti(object, hl_hash_utf8("left"), &hlt_i32, bounds.x);
		hl_dyn_seti(object, hl_hash_utf8("top"), &hlt_i32, bounds.y);
		hl_dyn_seti(object, hl_hash_utf8("handle"), &hlt_i32, i);

		const char* name = SDL_GetDisplayName(display);

		if (name == nullptr)
			name = "";

		hl_dyn_setp(object, hl_hash_utf8("name"), &hlt_bytes, hl_copy_bytes(name, (int)strlen(name) + 1));
		hl_aptr(result, vdynamic*)[i] = object;
	}

	SDL_free(displays);

	return result;
}
DEFINE_PRIM(_ARR, get_displays, _NO_ARG);

HL_PRIM varray* HL_NAME(get_display_modes)(int display_index) {
	int count;
	SDL_DisplayID display = limen_display_id_from_index(display_index);
	SDL_DisplayMode** modes = display != 0 ? SDL_GetFullscreenDisplayModes(display, &count) : nullptr;

	if (modes == nullptr)
		return nullptr;

	varray* result = hl_alloc_array(&hlt_dynobj, count);

	for (int i = 0; i < count; i++) {
		vdynamic* object = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti(object, hl_hash_utf8("width"), &hlt_i32, modes[i]->w);
		hl_dyn_seti(object, hl_hash_utf8("height"), &hlt_i32, modes[i]->h);
		hl_dyn_setd(object, hl_hash_utf8("refreshRate"), modes[i]->refresh_rate);
		hl_aptr(result, vdynamic*)[i] = object;
	}

	SDL_free(modes);

	return result;
}
DEFINE_PRIM(_ARR, get_display_modes, _I32);

static vdynobj* display_mode_object(SDL_DisplayID display, bool desktop) {
	if (display == 0)
		return nullptr;

	const SDL_DisplayMode* mode = desktop ? SDL_GetDesktopDisplayMode(display) : SDL_GetCurrentDisplayMode(display);

	if (mode == nullptr)
		return nullptr;

	vdynamic* object = (vdynamic*)hl_alloc_dynobj();
	hl_dyn_seti(object, hl_hash_utf8("width"), &hlt_i32, mode->w);
	hl_dyn_seti(object, hl_hash_utf8("height"), &hlt_i32, mode->h);
	hl_dyn_setd(object, hl_hash_utf8("refreshRate"), mode->refresh_rate);

	return (vdynobj*)object;
}

HL_PRIM vdynobj* HL_NAME(get_current_display_mode)(int display_index, bool desktop) {
	return display_mode_object(limen_display_id_from_index(display_index), desktop);
}
DEFINE_PRIM(_DYN, get_current_display_mode, _I32 _BOOL);

HL_PRIM vdynobj* HL_NAME(win_get_current_display_mode)(SDL_Window* window, bool desktop) {
	return display_mode_object(limen_display_for_window(window), desktop);
}
DEFINE_PRIM(_DYN, win_get_current_display_mode, TWIN _BOOL);

HL_PRIM varray* HL_NAME(get_devices)() {
	int count;
	SDL_DisplayID* displays = SDL_GetDisplays(&count);

	if (displays == nullptr)
		return hl_alloc_array(&hlt_bytes, 0);

	varray* result = hl_alloc_array(&hlt_bytes, count);

	for (int i = 0; i < count; i++) {
		const char* name = SDL_GetDisplayName(limen_display_id_from_index(i));
		hl_aptr(result, vbyte*)[i] = (vbyte*)hl_to_utf16(name != nullptr ? name : "");
	}

	SDL_free(displays);

	return result;
}
DEFINE_PRIM(_ARR, get_devices, _NO_ARG);
