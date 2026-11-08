#define LIMEN_PLATFORM_BUILD
#include <SDL3/SDL.h>
#include <stdio.h>

static bool succeeds;
static bool SDLCALL test_make_current(SDL_Window* window, SDL_GLContext context) {
	return succeeds || SDL_SetError("injected make current failure");
}
static bool SDLCALL test_swap(SDL_Window* window) {
	return succeeds || SDL_SetError("injected swap failure");
}
#define SDL_GL_MakeCurrent test_make_current
#define SDL_GL_SwapWindow test_swap
#include "../backend/src/platform/graphics.c"

#define CHECK(c) do { if (!(c)) { fprintf(stderr, "line %d: %s\n", __LINE__, #c); return 1; } } while (0)
int main(void) {
	CHECK(!limen_gl_make_current(nullptr, nullptr));
	CHECK(SDL_strstr(SDL_GetError(), "make current failure"));
	CHECK(!limen_gl_swap_window(nullptr));
	CHECK(SDL_strstr(SDL_GetError(), "swap failure"));
	succeeds = true;
	CHECK(limen_gl_make_current(nullptr, nullptr));
	CHECK(limen_gl_swap_window(nullptr));
	puts("SDL OpenGL failure checks passed");
	return 0;
}
