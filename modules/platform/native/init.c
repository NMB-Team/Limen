#include "platform_internal.h"
#include "module_loader.h"
#include <locale.h>

#ifdef HL_ANDROID
#define SDL_MAIN_HANDLED
#include <SDL3/SDL_main.h>
#endif

static SDL_AtomicInt listener_error_pending;

static bool defer_event_delivery(void) {
	return SDL_GetAtomicInt(&listener_error_pending) || limen_tray_has_callbacks();
}

HL_PRIM void HL_NAME(mark_event_watch_error)() {
	SDL_SetAtomicInt(&listener_error_pending, 1);
}
DEFINE_PRIM(_VOID, mark_event_watch_error, _NO_ARG);

HL_PRIM int HL_NAME(next_event)(limen_event* target, limen_event* deferred) {
	return limen_take_queued_event(target, deferred, defer_event_delivery);
}
DEFINE_PRIM(_I32, next_event, _DYN _DYN);

static bool init_platform(vclosure* callback, limen_event* event, bool queued) {
	SDL_SetHint(SDL_HINT_JOYSTICK_ALLOW_BACKGROUND_EVENTS, "1");
	SDL_SetHint(SDL_HINT_IME_IMPLEMENTED_UI, "none");

#ifdef HL_ANDROID
	SDL_SetMainReady();
#endif
	if (!SDL_Init(SDL_INIT_EVENTS))
		hl_error("SDL_Init failed: %s", hl_to_utf16(SDL_GetError()));

	limen_set_event_watch(callback, event, queued);

	if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD)) {
		uchar* error = hl_to_utf16(SDL_GetError());
		limen_set_event_watch(nullptr, nullptr, false);
		SDL_Quit();
		hl_error("SDL_Init failed: %s", error);

		return false;
	}

	setlocale(LC_ALL, "C");
#ifdef _WIN32
	timeBeginPeriod(1);
#endif
	return true;
}

HL_PRIM bool HL_NAME(init_once)(vclosure* callback, limen_event* event) {
	return init_platform(callback, event, false);
}
DEFINE_PRIM(_BOOL, init_once, _DYN _DYN);

HL_PRIM bool HL_NAME(init_event_queue)(vclosure* callback, limen_event* event) {
	return init_platform(callback, event, true);
}
DEFINE_PRIM(_BOOL, init_event_queue, _DYN _DYN);

HL_PRIM void HL_NAME(validate_event_shutdown)() {
	if (limen_in_event_watch())
		hl_error("Cannot shut down LIMEN from an Event Watch listener");
	if (!SDL_IsMainThread())
		hl_error("LIMEN shutdown requires the SDL main thread");
}
DEFINE_PRIM(_VOID, validate_event_shutdown, _NO_ARG);

HL_PRIM void HL_NAME(quit)() {
	HL_NAME(validate_event_shutdown)();
	limen_set_event_watch(nullptr, nullptr, false);
	SDL_SetAtomicInt(&listener_error_pending, 0);
	limen_tray_clear_callbacks(); // clean callbacks of tray
	limen_modules_unload();
	SDL_Quit();
#ifdef _WIN32
	timeEndPeriod(1);
#endif
}
DEFINE_PRIM(_VOID, quit, _NO_ARG);

HL_PRIM void HL_NAME(message_box)(vbyte* title, vbyte* text, int icon) {
	hl_blocking(true);
	SDL_ShowSimpleMessageBox((SDL_MessageBoxFlags)icon, (char*)title, (char*)text, nullptr);
	hl_blocking(false);
}
DEFINE_PRIM(_VOID, message_box, _BYTES _BYTES _I32);

HL_PRIM int HL_NAME(get_video_backend)() {
	const char* driver = SDL_GetCurrentVideoDriver();

	if (!driver)
		return 0;

	if (strcmp(driver, "windows") == 0)
		return 1;
	if (strcmp(driver, "x11") == 0)
		return 2;
	if (strcmp(driver, "wayland") == 0)
		return 3;
	if (strcmp(driver, "cocoa") == 0)
		return 4;

	if (strcmp(driver, "android") == 0)
		return 5;

	if (strcmp(driver, "kmsdrm") == 0)
		return 6;

	if (strcmp(driver, "offscreen") == 0)
		return 7;
	if (strcmp(driver, "dummy") == 0)
		return 8;

	return 0;
}
DEFINE_PRIM(_I32, get_video_backend, _NO_ARG);

HL_PRIM bool HL_NAME(detect_win32)() {
#ifdef _WIN32
	return true;
#else
	return false;
#endif
}
DEFINE_PRIM(_BOOL, detect_win32, _NO_ARG);

HL_PRIM bool HL_NAME(detect_linux)() {
#ifdef __linux__
	return true;
#else
	return false;
#endif
}
DEFINE_PRIM(_BOOL, detect_linux, _NO_ARG);

HL_PRIM bool HL_NAME(detect_mobile)() {
#ifdef HL_MOBILE
	return true;
#else
	return false;
#endif
}
DEFINE_PRIM(_BOOL, detect_mobile, _NO_ARG);

HL_PRIM const char* HL_NAME(get_pref_path)(const char* org, const char* app) {
	return SDL_GetPrefPath(org, app);
}
DEFINE_PRIM(_BYTES, get_pref_path, _BYTES _BYTES);

HL_PRIM vbyte* HL_NAME(get_error)() {
	return (vbyte*)SDL_GetError();
}
DEFINE_PRIM(_BYTES, get_error, _NO_ARG);
