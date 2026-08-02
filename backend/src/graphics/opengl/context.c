#define HL_NAME(n) limen_opengl_##n
#include <hl.h>
#include "native_window.h"

#define TWIN _ABSTRACT(limen_window)
#define TGL _ABSTRACT(limen_gl)

HL_PRIM void* HL_NAME(win_get_glcontext)(void* window) {
	return limen_gl_create_context(window);
}

HL_PRIM void HL_NAME(win_swap_window)(void* window) {
	limen_gl_swap_window(window);
}

HL_PRIM void HL_NAME(win_render_to)(void* window, void* context) {
	limen_gl_make_current(window, context);
}

HL_PRIM void HL_NAME(gl_options)(int major, int minor, int depth, int stencil, int flags, int samples) {
	limen_gl_configure(major, minor, depth, stencil, flags, samples);
}

HL_PRIM void HL_NAME(set_vsync)(bool enabled) {
	limen_gl_set_vsync(enabled);
}

HL_PRIM void HL_NAME(gl_context_destroy)(void* context) {
	limen_gl_destroy_context(context);
}

DEFINE_PRIM(_VOID, gl_options, _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, set_vsync, _BOOL);
DEFINE_PRIM(_VOID, gl_context_destroy, TGL);
DEFINE_PRIM(TGL, win_get_glcontext, TWIN);
DEFINE_PRIM(_VOID, win_swap_window, TWIN);
DEFINE_PRIM(_VOID, win_render_to, TWIN TGL);
