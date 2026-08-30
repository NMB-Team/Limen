#include "internal.h"
#include "module_loader.h"
#include <locale.h>

#ifdef HL_ANDROID
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
#endif

HL_PRIM bool HL_NAME(init_once)() {
	SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
	SDL_SetHint(SDL_HINT_IME_IMPLEMENTED_UI, "none");

#ifdef HL_ANDROID
	SDL_SetMainReady();
#endif
	if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD)) {
		hl_error("SDL_Init failed: %s", hl_to_utf16(SDL_GetError()));
		return false;
	}
	setlocale(LC_ALL, "C");
#ifdef _WIN32
	timeBeginPeriod(1);
#endif
	return true;
}

HL_PRIM void HL_NAME(quit)() {
	limen_modules_unload();
	SDL_Quit();
#ifdef _WIN32
	timeEndPeriod(1);
#endif
}

HL_PRIM void HL_NAME(message_box)(vbyte* title, vbyte* text, int icon) {
	hl_blocking(true);
	SDL_ShowSimpleMessageBox((SDL_MessageBoxFlags)icon, (char*)title, (char*)text, nullptr);
	hl_blocking(false);
}

HL_PRIM int HL_NAME(get_video_backend)() {
	const char* driver = SDL_GetCurrentVideoDriver();

	if (!driver)
		return 0;

	if (strcmp(driver, "windows") == 0) return 1;
	if (strcmp(driver, "x11") == 0) return 2;
	if (strcmp(driver, "wayland") == 0) return 3;
	if (strcmp(driver, "cocoa") == 0) return 4;

	if (strcmp(driver, "android") == 0) return 5;

	if (strcmp(driver, "kmsdrm") == 0) return 6;

	if (strcmp(driver, "offscreen") == 0) return 7;
	if (strcmp(driver, "dummy") == 0) return 8;

	return 0;
}

HL_PRIM bool HL_NAME(detect_win32)() {
#ifdef _WIN32
	return true;
#else
	return false;
#endif
}

HL_PRIM bool HL_NAME(detect_linux)() {
#ifdef __linux__
	return true;
#else
	return false;
#endif
}

HL_PRIM const char* HL_NAME(get_pref_path)(const char* org, const char* app) {
	return SDL_GetPrefPath(org, app);
}

HL_PRIM vbyte* HL_NAME(get_error)() {
	return (vbyte*)SDL_GetError();
}

DEFINE_PRIM(_BOOL, init_once, _NO_ARG);
DEFINE_PRIM(_VOID, quit, _NO_ARG);
DEFINE_PRIM(_VOID, message_box, _BYTES _BYTES _I32);
DEFINE_PRIM(_I32, get_video_backend, _NO_ARG);
DEFINE_PRIM(_BOOL, detect_win32, _NO_ARG);
DEFINE_PRIM(_BOOL, detect_linux, _NO_ARG);
DEFINE_PRIM(_BYTES, get_pref_path, _BYTES _BYTES);
DEFINE_PRIM(_BYTES, get_error, _NO_ARG);
