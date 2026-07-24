#include <SDL3/SDL.h>
#if defined(LIMEN_HAS_VULKAN)
#include <vulkan/vulkan.h>
#include <SDL3/SDL_vulkan.h>
#endif

#include "native_window.h"

void* limen_gl_create_context(void* window) {
	return SDL_GL_CreateContext(window);
}

void limen_gl_swap_window(void* window) {
	SDL_GL_SwapWindow(window);
}

void limen_gl_make_current(void* window, void* context) {
	SDL_GL_MakeCurrent(window, context);
}

void limen_gl_destroy_context(void* context) {
	SDL_GL_DestroyContext(context);
}

void limen_gl_configure(int major, int minor, int depth, int stencil, int flags, int samples) {
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, major);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, minor);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, depth);
	SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, stencil);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, flags & 1);
	if (!(flags & 8) && (major < 3 || (major == 3 && minor < 2)))
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, 0);
	else if (flags & 2)
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	else if (flags & 4)
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
	else if (flags & 8)
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
#ifdef HL_MOBILE
	else
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
#else
	else
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
#endif
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, samples > 1);
	SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, samples > 1 ? samples : 0);
}

void limen_gl_set_vsync(bool enabled) {
	SDL_GL_SetSwapInterval(enabled ? 1 : 0);
}

void* limen_gl_get_proc_address(const char* name) {
	return (void*)SDL_GL_GetProcAddress(name);
}

bool limen_vulkan_create_surface(void* window, void* instance, uint64_t* surface) {
#if defined(LIMEN_HAS_VULKAN)
	VkSurfaceKHR result = VK_NULL_HANDLE;
	if (!SDL_Vulkan_CreateSurface(window, instance, NULL, &result))
		return false;
	*surface = (uint64_t)result;
	return true;
#else
	(void)window;
	(void)instance;
	(void)surface;
	return false;
#endif
}
