#include "../core/internal.h"

#ifdef HL_WIN_DESKTOP
#include "../platform/windows/borderless.h"
#include "../platform/windows/theme.h"
#endif

typedef enum {
	LIMEN_FULLSCREEN_WINDOWED,
	LIMEN_FULLSCREEN_BORDERLESS,
	LIMEN_FULLSCREEN_EXCLUSIVE,
} limen_fullscreen_mode;

static limen_fullscreen_mode normalize_fullscreen_mode(int mode) {
	switch (mode) {
		case 1:
			return LIMEN_FULLSCREEN_EXCLUSIVE;
		case 2:
		case 3:
			return LIMEN_FULLSCREEN_BORDERLESS;
		default:
			return LIMEN_FULLSCREEN_WINDOWED;
	}
}

static void sync_window_state(SDL_Window* window) {
#if SDL_VERSION_ATLEAST(3, 2, 0)
	SDL_SyncWindow(window);
#endif
}

HL_PRIM SDL_Window* HL_NAME(win_create_ex)(int x, int y, int width, int height, int flags) {
#ifdef HL_MOBILE
	SDL_Window* window = SDL_CreateWindow("", width, height, SDL_WINDOW_BORDERLESS | flags);
#else
	SDL_PropertiesID properties = SDL_CreateProperties();
	if (properties == 0)
		return NULL;
	SDL_SetStringProperty(properties, SDL_PROP_WINDOW_CREATE_TITLE_STRING, "");
	SDL_SetNumberProperty(properties, SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, width);
	SDL_SetNumberProperty(properties, SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, height);
	SDL_SetNumberProperty(properties, SDL_PROP_WINDOW_CREATE_X_NUMBER, x);
	SDL_SetNumberProperty(properties, SDL_PROP_WINDOW_CREATE_Y_NUMBER, y);
	if (flags & SDL_WINDOW_METAL) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_METAL_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_VULKAN) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_VULKAN_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_OPENGL) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_OPENGL_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_BORDERLESS) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_FULLSCREEN) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_HIDDEN) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_RESIZABLE) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_MINIMIZED) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_MINIMIZED_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_MAXIMIZED) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_MOUSE_GRABBED) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_MOUSE_GRABBED_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_HIGH_PIXEL_DENSITY) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_ALWAYS_ON_TOP) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_ALWAYS_ON_TOP_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_UTILITY) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_UTILITY_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_TOOLTIP) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_TOOLTIP_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_POPUP_MENU) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_MENU_BOOLEAN, true);
	}
	if (flags & SDL_WINDOW_MODAL) {
		SDL_SetBooleanProperty(properties, SDL_PROP_WINDOW_CREATE_MODAL_BOOLEAN, true);
	}

	SDL_Window* window = SDL_CreateWindowWithProperties(properties);
	SDL_DestroyProperties(properties);
#endif
	if (window == NULL)
		return NULL;

#ifdef HL_WIN
	if (!(flags & SDL_WINDOW_HIDDEN) && !(SDL_GetWindowFlags(window) & SDL_WINDOW_INPUT_FOCUS)) {
		SDL_HideWindow(window);
		SDL_ShowWindow(window);
	}
	SDL_RaiseWindow(window);
#endif
	SDL_StartTextInput(window);
	return window;
}
DEFINE_PRIM(TWIN, win_create_ex, _I32 _I32 _I32 _I32 _I32);

HL_PRIM SDL_Window* HL_NAME(win_create)(int width, int height) {
	return HL_NAME(win_create_ex)(SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, 0);
}
DEFINE_PRIM(TWIN, win_create, _I32 _I32);

HL_PRIM bool HL_NAME(win_set_fullscreen)(SDL_Window* window, int mode) {
	limen_fullscreen_mode normalized = normalize_fullscreen_mode(mode);
#ifdef HL_WIN_DESKTOP
	if (!limen_windows_prepare_fullscreen(window, mode))
		return false;
#endif
	if (normalized == LIMEN_FULLSCREEN_WINDOWED) {
		bool result = SDL_SetWindowFullscreen(window, false);
		if (result)
			SDL_SetWindowFullscreenMode(window, NULL);
		return result;
	}
	if (normalized == LIMEN_FULLSCREEN_EXCLUSIVE) {
		const SDL_DisplayMode* fullscreen_mode = SDL_GetWindowFullscreenMode(window);
		if (fullscreen_mode == NULL) {
			SDL_DisplayID display = SDL_GetDisplayForWindow(window);
			fullscreen_mode = SDL_GetDesktopDisplayMode(display);
			if (fullscreen_mode != NULL)
				SDL_SetWindowFullscreenMode(window, fullscreen_mode);
		}
		bool result = SDL_SetWindowFullscreen(window, true);
		if (result)
			sync_window_state(window);
		return result;
	}

	if (mode == 2) {
#ifdef HL_WIN_DESKTOP
		return limen_windows_set_borderless_fixed(window);
#endif
	}
	SDL_SetWindowFullscreenMode(window, NULL);
	return SDL_SetWindowFullscreen(window, true);
}
DEFINE_PRIM(_BOOL, win_set_fullscreen, TWIN _I32);

HL_PRIM bool HL_NAME(win_set_display_mode)(SDL_Window* window, int width, int height, int framerate) {
	SDL_DisplayMode mode;
	SDL_DisplayID display = SDL_GetDisplayForWindow(window);
	if (!SDL_GetClosestFullscreenDisplayMode(display, width, height, (float)framerate, true, &mode)) {
		return false;
	}
	bool result = SDL_SetWindowFullscreenMode(window, &mode);
	if (result)
		sync_window_state(window);
	return result;
}
DEFINE_PRIM(_BOOL, win_set_display_mode, TWIN _I32 _I32 _I32);

HL_PRIM int HL_NAME(win_display_handle)(SDL_Window* window) {
	return limen_display_index_from_id(SDL_GetDisplayForWindow(window));
}
DEFINE_PRIM(_I32, win_display_handle, TWIN);

HL_PRIM void HL_NAME(win_set_title)(SDL_Window* window, vbyte* title) {
	SDL_SetWindowTitle(window, (char*)title);
}
DEFINE_PRIM(_VOID, win_set_title, TWIN _BYTES);

HL_PRIM void HL_NAME(win_set_icon)(SDL_Window* window, SDL_Surface* surface) {
	SDL_SetWindowIcon(window, surface);
}
DEFINE_PRIM(_VOID, win_set_icon, TWIN _SURF);

HL_PRIM void HL_NAME(win_set_position)(SDL_Window* window, int x, int y) {
	SDL_SetWindowPosition(window, x, y);
}
DEFINE_PRIM(_VOID, win_set_position, TWIN _I32 _I32);

HL_PRIM void HL_NAME(win_get_position)(SDL_Window* window, int* x, int* y) {
	SDL_GetWindowPosition(window, x, y);
}
DEFINE_PRIM(_VOID, win_get_position, TWIN _REF(_I32) _REF(_I32));

HL_PRIM void HL_NAME(win_center)(SDL_Window* window, bool primary) {
	SDL_DisplayID display = primary ? SDL_GetPrimaryDisplay() : SDL_GetDisplayForWindow(window);
	int centered = SDL_WINDOWPOS_CENTERED_DISPLAY(display);
	SDL_SetWindowPosition(window, centered, centered);
}
DEFINE_PRIM(_VOID, win_center, TWIN _BOOL);

HL_PRIM void HL_NAME(win_set_size)(SDL_Window* window, int width, int height) {
	if (SDL_GetWindowFlags(window) & SDL_WINDOW_MAXIMIZED)
		SDL_RestoreWindow(window);
	SDL_SetWindowSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_set_size, TWIN _I32 _I32);

HL_PRIM void HL_NAME(win_set_min_size)(SDL_Window* window, int width, int height) {
	SDL_SetWindowMinimumSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_set_min_size, TWIN _I32 _I32);

HL_PRIM void HL_NAME(win_set_max_size)(SDL_Window* window, int width, int height) {
	SDL_SetWindowMaximumSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_set_max_size, TWIN _I32 _I32);

HL_PRIM void HL_NAME(win_get_pixel_size)(SDL_Window* window, int* width, int* height) {
	SDL_GetWindowSizeInPixels(window, width, height);
}
DEFINE_PRIM(_VOID, win_get_pixel_size, TWIN _REF(_I32) _REF(_I32));

HL_PRIM void HL_NAME(win_get_size)(SDL_Window* window, int* width, int* height) {
	SDL_GetWindowSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_get_size, TWIN _REF(_I32) _REF(_I32));

HL_PRIM void HL_NAME(win_get_min_size)(SDL_Window* window, int* width, int* height) {
	SDL_GetWindowMinimumSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_get_min_size, TWIN _REF(_I32) _REF(_I32));

HL_PRIM void HL_NAME(win_get_max_size)(SDL_Window* window, int* width, int* height) {
	SDL_GetWindowMaximumSize(window, width, height);
}
DEFINE_PRIM(_VOID, win_get_max_size, TWIN _REF(_I32) _REF(_I32));

HL_PRIM double HL_NAME(win_get_display_scale)(SDL_Window* window) {
	return SDL_GetWindowDisplayScale(window);
}
DEFINE_PRIM(_F64, win_get_display_scale, TWIN);

HL_PRIM double HL_NAME(win_get_opacity)(SDL_Window* window) {
	return SDL_GetWindowOpacity(window);
}
DEFINE_PRIM(_F64, win_get_opacity, TWIN);

HL_PRIM bool HL_NAME(win_set_opacity)(SDL_Window* window, double opacity) {
	return SDL_SetWindowOpacity(window, (float)opacity);
}
DEFINE_PRIM(_BOOL, win_set_opacity, TWIN _F64);

HL_PRIM bool HL_NAME(win_set_dark_mode)(SDL_Window* window, bool enabled) {
#ifdef HL_WIN_DESKTOP
	return limen_windows_set_dark_mode(window, enabled);
#else
	(void)window;
	(void)enabled;
	return false;
#endif
}
DEFINE_PRIM(_BOOL, win_set_dark_mode, TWIN _BOOL);

HL_PRIM void HL_NAME(win_resize)(SDL_Window* window, int mode) {
	switch (mode) {
		case 0:
			SDL_MaximizeWindow(window);
			break;
		case 1:
			SDL_MinimizeWindow(window);
			break;
		case 2:
			SDL_RestoreWindow(window);
			break;
		case 3:
			SDL_ShowWindow(window);
			break;
		case 4:
			SDL_HideWindow(window);
			break;
		default:
			break;
	}
}
DEFINE_PRIM(_VOID, win_resize, TWIN _I32);

HL_PRIM void HL_NAME(win_raise)(SDL_Window* window) {
	SDL_RaiseWindow(window);
}
DEFINE_PRIM(_VOID, win_raise, TWIN);

HL_PRIM bool HL_NAME(win_set_always_on_top)(SDL_Window* window, bool enabled) {
	return SDL_SetWindowAlwaysOnTop(window, enabled);
}
DEFINE_PRIM(_BOOL, win_set_always_on_top, TWIN _BOOL);

HL_PRIM int HL_NAME(win_get_id)(SDL_Window* window) {
	return SDL_GetWindowID(window);
}
DEFINE_PRIM(_I32, win_get_id, TWIN);

HL_PRIM void HL_NAME(window_destroy)(SDL_Window* window) {
#ifdef HL_WIN_DESKTOP
	limen_windows_cleanup_borderless(window);
#endif
	SDL_DestroyWindow(window);
}
DEFINE_PRIM(_VOID, window_destroy, TWIN);

HL_PRIM const char* HL_NAME(win_error)() {
	return SDL_GetError();
}
DEFINE_PRIM(_BYTES, win_error, _NO_ARG);
