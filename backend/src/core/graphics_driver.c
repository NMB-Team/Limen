#include "internal.h"

typedef enum {
	LIMEN_GRAPHICS_NONE,
	LIMEN_GRAPHICS_OPENGL,
	LIMEN_GRAPHICS_VULKAN,
	LIMEN_GRAPHICS_D3D11,
	LIMEN_GRAPHICS_D3D12,
	LIMEN_GRAPHICS_DRIVER_COUNT,
} limen_graphics_driver;

static const char* limen_graphics_modules[LIMEN_GRAPHICS_DRIVER_COUNT] = {
	NULL,
	"opengl.limen",
	"vulkan.limen",
	"d3d11.limen",
	"d3d12.limen",
};

static void* limen_graphics_handles[LIMEN_GRAPHICS_DRIVER_COUNT];
static void* limen_dlss_handle;
static limen_graphics_driver limen_selected_graphics_driver;

static bool limen_load_graphics_driver(limen_graphics_driver driver) {
	if (driver <= LIMEN_GRAPHICS_NONE || driver >= LIMEN_GRAPHICS_DRIVER_COUNT)
		return false;
	if (limen_graphics_handles[driver] != NULL)
		return true;
	limen_graphics_handles[driver] = SDL_LoadObject(limen_graphics_modules[driver]);
	return limen_graphics_handles[driver] != NULL;
}

HL_PRIM int HL_NAME(select_graphics_driver)(int preferred, int supported) {
	static const limen_graphics_driver fallback_order[] = {
		LIMEN_GRAPHICS_OPENGL,
		LIMEN_GRAPHICS_VULKAN,
		LIMEN_GRAPHICS_D3D11,
		LIMEN_GRAPHICS_D3D12,
	};

	if ((supported & (1 << preferred)) != 0 && limen_load_graphics_driver((limen_graphics_driver)preferred)) {
		SDL_ClearError();
		limen_selected_graphics_driver = (limen_graphics_driver)preferred;
		return preferred;
	}

	for (int i = 0; i < sizeof(fallback_order) / sizeof(fallback_order[0]); i++) {
		limen_graphics_driver driver = fallback_order[i];
		if (driver == preferred || (supported & (1 << driver)) == 0)
			continue;
		if (limen_load_graphics_driver(driver)) {
			SDL_ClearError();
			limen_selected_graphics_driver = driver;
			return driver;
		}
	}

	limen_selected_graphics_driver = LIMEN_GRAPHICS_NONE;
	SDL_SetError("No LIMEN graphics driver was found");
	return LIMEN_GRAPHICS_NONE;
}

HL_PRIM bool HL_NAME(is_dlss_available)() {
	if (limen_selected_graphics_driver != LIMEN_GRAPHICS_D3D12)
		return false;
	if (limen_dlss_handle != NULL)
		return true;
	limen_dlss_handle = SDL_LoadObject("dlss.limen");
	SDL_ClearError();
	return limen_dlss_handle != NULL;
}

DEFINE_PRIM(_I32, select_graphics_driver, _I32 _I32);
DEFINE_PRIM(_BOOL, is_dlss_available, _NO_ARG);
