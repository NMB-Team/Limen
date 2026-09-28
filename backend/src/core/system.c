#include "internal.h"

HL_PRIM int HL_NAME(get_power_state)() {
	return SDL_GetPowerInfo(nullptr, nullptr);
}
DEFINE_PRIM(_I32, get_power_state, _NO_ARG);

HL_PRIM int HL_NAME(get_battery_percent)() {
	int percent = -1;
	if (SDL_GetPowerInfo(nullptr, &percent) == SDL_POWERSTATE_ERROR)
		return -1;
	return percent;
}
DEFINE_PRIM(_I32, get_battery_percent, _NO_ARG);

HL_PRIM int HL_NAME(get_system_theme)() {
	return SDL_GetSystemTheme();
}
DEFINE_PRIM(_I32, get_system_theme, _NO_ARG);

HL_PRIM const char* HL_NAME(get_platform)() {
	return SDL_GetPlatform();
}
DEFINE_PRIM(_BYTES, get_platform, _NO_ARG);

HL_PRIM vbyte* HL_NAME(get_base_path)() {
	const char* path = SDL_GetBasePath();
	return path == nullptr ? nullptr : hl_copy_bytes(path, (int)strlen(path) + 1);
}
DEFINE_PRIM(_BYTES, get_base_path, _NO_ARG);

HL_PRIM vbyte* HL_NAME(get_current_directory)() {
	char* path = SDL_GetCurrentDirectory();
	if (path == nullptr)
		return nullptr;
	vbyte* result = hl_copy_bytes(path, (int)strlen(path) + 1);
	SDL_free(path);
	return result;
}
DEFINE_PRIM(_BYTES, get_current_directory, _NO_ARG);
