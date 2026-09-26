#include <SDL3/SDL.h>
#if defined(LIMEN_HAS_VULKAN)
#include <vulkan/vulkan.h>
#include <SDL3/SDL_vulkan.h>
#endif

#include "native_window.h"

void* limen_gl_create_context(void* window) {
	return SDL_GL_CreateContext(window);
}

bool limen_gl_swap_window(void* window) {
	return SDL_GL_SwapWindow(window);
}

void limen_gl_make_current(void* window, void* context) {
	SDL_GL_MakeCurrent(window, context);
}

void limen_gl_destroy_context(void* context) {
	SDL_GL_DestroyContext(context);
}

static bool limen_gl_set_attribute(SDL_GLAttr attribute, int value, const char* name) {
	if (SDL_GL_SetAttribute(attribute, value))
		return true;

	char original_error[512];
	SDL_strlcpy(original_error, SDL_GetError(), sizeof(original_error));

	return SDL_SetError("SDL_GL_SetAttribute(%s, %d) failed: %s", name, value, original_error);
}

// macro attribute helper
#define LIMEN_GL_SET_ATTRIBUTE(attribute, value) \
	do { \
		if (!limen_gl_set_attribute((attribute), (value), #attribute)) \
			return false; \
	} while (0)

bool limen_gl_configure(int major, int minor, int depth, int stencil, int flags, int samples) {
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_MAJOR_VERSION, major);
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_MINOR_VERSION, minor);
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_DEPTH_SIZE, depth);
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_STENCIL_SIZE, stencil);
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_DOUBLEBUFFER, flags & 1);
	if (!(flags & 8) && (major < 3 || (major == 3 && minor < 2)))
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, 0);
	else if (flags & 2)
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
	else if (flags & 4)
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
	else if (flags & 8)
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
#ifdef HL_MOBILE
	else
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
#else
	else
		LIMEN_GL_SET_ATTRIBUTE(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
#endif
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_MULTISAMPLEBUFFERS, samples > 1);
	LIMEN_GL_SET_ATTRIBUTE(SDL_GL_MULTISAMPLESAMPLES, samples > 1 ? samples : 0);
}

static const char* limen_gl_profile_name(int profile) {
	switch (profile) {
		case SDL_GL_CONTEXT_PROFILE_CORE:
			return "Core";
		case SDL_GL_CONTEXT_PROFILE_COMPATIBILITY:
			return "Compatibility";
		case SDL_GL_CONTEXT_PROFILE_ES:
			return "ES";
		default:
			return "Default";
	}
}

const char* limen_gl_get_context_info(void) {
	static char buffer[512];
	int major = 0, minor = 0, profile = 0, depth = 0, stencil = 0, doublebuffer = 0, sample_buffers = 0, samples = 0;

	if (!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, &major))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, &minor))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, &profile))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_DEPTH_SIZE, &depth))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_STENCIL_SIZE, &stencil))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_DOUBLEBUFFER, &doublebuffer))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_MULTISAMPLEBUFFERS, &sample_buffers))
		return nullptr;
	if (!SDL_GL_GetAttribute(SDL_GL_MULTISAMPLESAMPLES, &samples))
		return nullptr;

	SDL_snprintf(buffer, sizeof(buffer), "OpenGL %d.%d %s, depth=%d, stencil=%d, doubleBuffer=%d, sampleBuffers=%d, samples=%d", major, minor, limen_gl_profile_name(profile), depth, stencil, doublebuffer, sample_buffers, samples);

	return buffer;
}

bool limen_gl_set_swap_interval(int interval) {
	return SDL_GL_SetSwapInterval(interval);
}

void* limen_gl_get_proc_address(const char* name) {
	return (void*)SDL_GL_GetProcAddress(name);
}

bool limen_vulkan_create_surface(void* window, void* instance, uint64_t* surface) {
#if defined(LIMEN_HAS_VULKAN)
	VkSurfaceKHR result = VK_NULL_HANDLE;
	if (!SDL_Vulkan_CreateSurface(window, instance, nullptr, &result))
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
