#define HL_NAME(n) limen_opengl_##n
#include <hl.h>
#include "native_window.h"

#define TWIN _ABSTRACT(limen_window)
#define TGL _ABSTRACT(limen_gl)

void* limen_gl_new_context(void* window);
bool limen_gl_activate_context(void* window, void* context);
bool limen_gl_delete_context(void* context);

HL_PRIM void* HL_NAME(win_get_glcontext)(void* window) {
	return limen_gl_new_context(window);
}

HL_PRIM bool HL_NAME(win_swap_window)(void* window) {
	return limen_gl_swap_window(window);
}

HL_PRIM bool HL_NAME(win_render_to)(void* window, void* context) {
	return limen_gl_activate_context(window, context);
}

HL_PRIM bool HL_NAME(gl_options)(int major, int minor, int depth, int stencil, int flags, int samples) {
	return limen_gl_configure(major, minor, depth, stencil, flags, samples);
}

HL_PRIM const char* HL_NAME(gl_context_info)() {
	return limen_gl_get_context_info();
}

HL_PRIM bool HL_NAME(set_swap_interval)(int interval) {
	return limen_gl_set_swap_interval(interval);
}

HL_PRIM void HL_NAME(gl_context_destroy)(void* context) {
	if (!limen_gl_delete_context(context)) hl_error("Could not destroy OpenGL context: it is current on another thread");
}

DEFINE_PRIM(_BOOL, gl_options, _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_BYTES, gl_context_info, _NO_ARG);
DEFINE_PRIM(_BOOL, set_swap_interval, _I32);
DEFINE_PRIM(_VOID, gl_context_destroy, TGL);
DEFINE_PRIM(TGL, win_get_glcontext, TWIN);
DEFINE_PRIM(_BOOL, win_swap_window, TWIN);
DEFINE_PRIM(_BOOL, win_render_to, TWIN TGL);
