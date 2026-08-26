#pragma once

#include <stdint.h>

#if defined(_WIN32)
#if defined(LIMEN_PLATFORM_BUILD)
#define LIMEN_PLATFORM_API __declspec(dllexport)
#else
#define LIMEN_PLATFORM_API __declspec(dllimport)
#endif
#else
#define LIMEN_PLATFORM_API __attribute__((visibility("default")))
#endif

typedef enum {
	LIMEN_NATIVE_UNKNOWN,
	LIMEN_NATIVE_WIN32,
	LIMEN_NATIVE_COCOA,
	LIMEN_NATIVE_X11,
	LIMEN_NATIVE_WAYLAND,
	LIMEN_NATIVE_ANDROID,
} limen_native_window_type;

typedef struct {
	limen_native_window_type type;
	union {
		struct {
			void* window;
			void* instance;
		} win32;
		struct {
			void* window;
		} cocoa;
		struct {
			void* display;
			uint64_t window;
		} x11;
		struct {
			void* display;
			void* surface;
		} wayland;
		struct {
			void* window;
		} android;
	};
} limen_native_window;

#ifdef __cplusplus
extern "C" {
#endif

LIMEN_PLATFORM_API bool limen_get_native_window(void* window, limen_native_window* out);

LIMEN_PLATFORM_API void* limen_gl_create_context(void* window);
LIMEN_PLATFORM_API void limen_gl_swap_window(void* window);
LIMEN_PLATFORM_API void limen_gl_make_current(void* window, void* context);
LIMEN_PLATFORM_API void limen_gl_destroy_context(void* context);
LIMEN_PLATFORM_API void limen_gl_configure(int major, int minor, int depth, int stencil, int flags, int samples);
LIMEN_PLATFORM_API void limen_gl_set_vsync(bool enabled);
LIMEN_PLATFORM_API void* limen_gl_get_proc_address(const char* name);

LIMEN_PLATFORM_API bool limen_vulkan_create_surface(void* window, void* instance, uint64_t* surface);

#ifdef __cplusplus
}
#endif
