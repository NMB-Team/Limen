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

static int context_flags, reset_notification, create_calls;
static int supported_strategy;
static bool rejects_optional_attributes, rejects_all_contexts;
static bool SDLCALL test_get_attribute(SDL_GLAttr attribute, int* value) {
	if (attribute != SDL_GL_CONTEXT_FLAGS) return SDL_SetError("unexpected attribute query");
	*value = context_flags;
	return true;
}

static bool SDLCALL test_set_attribute(SDL_GLAttr attribute, int value) {
	if (rejects_optional_attributes &&
		((attribute == SDL_GL_CONTEXT_RESET_NOTIFICATION && value != SDL_GL_CONTEXT_RESET_NO_NOTIFICATION) ||
		(attribute == SDL_GL_CONTEXT_FLAGS && (value & SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG))))
		return SDL_SetError("optional attributes unsupported");

	if (attribute == SDL_GL_CONTEXT_FLAGS) context_flags = value;
	if (attribute == SDL_GL_CONTEXT_RESET_NOTIFICATION) reset_notification = value;
	return true;
}

static SDL_GLContext SDLCALL test_create_context(SDL_Window* window) {
	create_calls++;
	int strategy = reset_notification == SDL_GL_CONTEXT_RESET_LOSE_CONTEXT
		? (context_flags & SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG ? 2 : 1) : 0;
	if (rejects_all_contexts || strategy > supported_strategy) {
		SDL_SetError("injected context creation failure");
		return nullptr;
	}

	return (SDL_GLContext)(uintptr_t)1;
}

#define SDL_GL_MakeCurrent test_make_current
#define SDL_GL_SwapWindow test_swap
#define SDL_GL_GetAttribute test_get_attribute
#define SDL_GL_SetAttribute test_set_attribute
#define SDL_GL_CreateContext test_create_context
#include "../backend/src/platform/graphics.c"
#include "../backend/src/platform/egl_robustness.h"

#define CHECK(c) do { if (!(c)) { fprintf(stderr, "line %d: %s\n", __LINE__, #c); return 1; } } while (0)
int main(void) {
	int attributes[16] = { 0x3098, 3 };
	int count = 2;
	int flags = SDL_GL_CONTEXT_DEBUG_FLAG | SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG;
	CHECK(limen_egl_robustness(attributes, &count, &flags, true, false, false, true, true));
	CHECK(count == 6 && attributes[0] == 0x3098 && attributes[1] == 3);
	CHECK(attributes[2] == 0x31B2 && attributes[3] == 1 && attributes[4] == 0x31BD && attributes[5] == 0x31BF);
	CHECK(flags == SDL_GL_CONTEXT_DEBUG_FLAG);

	count = 0;
	flags = SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG;
	CHECK(limen_egl_robustness(attributes, &count, &flags, false, true, true, true, true));
	CHECK(count == 4 && attributes[0] == 0x30BF && attributes[2] == 0x3138 && flags == 0);

	count = 0;
	flags = SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG;
	CHECK(limen_egl_robustness(attributes, &count, &flags, false, false, true, false, true));
	CHECK(count == 2 && attributes[0] == 0x31BD && flags == SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG);
	CHECK(!limen_egl_robustness(attributes, &count, &flags, false, false, true, true, true));

	count = 0;
	flags = 0;
	CHECK(limen_egl_robustness(attributes, &count, &flags, false, false, false, true, false));
	CHECK(count == 0 && flags == 0);
	CHECK(!limen_egl_robustness(attributes, &count, &flags, false, false, false, true, true));

	CHECK(!limen_gl_make_current(nullptr, nullptr));
	CHECK(SDL_strstr(SDL_GetError(), "make current failure"));
	CHECK(!limen_gl_swap_window(nullptr));
	CHECK(SDL_strstr(SDL_GetError(), "swap failure"));
	succeeds = true;
	CHECK(limen_gl_make_current(nullptr, nullptr));
	CHECK(limen_gl_swap_window(nullptr));

	for (int strategy = 0; strategy <= 2; strategy++) {
		supported_strategy = strategy;
		context_flags = SDL_GL_CONTEXT_DEBUG_FLAG;
		create_calls = 0;

		CHECK(limen_gl_create_context(nullptr));
		CHECK(create_calls == 3 - strategy);
		CHECK(context_flags == SDL_GL_CONTEXT_DEBUG_FLAG);
		CHECK(reset_notification == SDL_GL_CONTEXT_RESET_NO_NOTIFICATION);
	}

	rejects_optional_attributes = true;
	create_calls = 0;
	CHECK(limen_gl_create_context(nullptr) && create_calls == 1);
	CHECK(context_flags == SDL_GL_CONTEXT_DEBUG_FLAG && reset_notification == SDL_GL_CONTEXT_RESET_NO_NOTIFICATION);

	rejects_optional_attributes = false;
	rejects_all_contexts = true;
	create_calls = 0;
	CHECK(!limen_gl_create_context(nullptr) && create_calls == 3);
	CHECK(SDL_strstr(SDL_GetError(), "injected context creation failure"));
	CHECK(context_flags == SDL_GL_CONTEXT_DEBUG_FLAG && reset_notification == SDL_GL_CONTEXT_RESET_NO_NOTIFICATION);
	puts("SDL OpenGL failure checks passed");
	return 0;
}
