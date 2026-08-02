#include "../core/internal.h"

#define TJOY _ABSTRACT(limen_joystick)

HL_PRIM int HL_NAME(joy_count)() {
	int count;
	SDL_JoystickID* joysticks = SDL_GetJoysticks(&count);
	SDL_free(joysticks);
	return count;
}

HL_PRIM SDL_Joystick* HL_NAME(joy_open)(int id) {
	return SDL_OpenJoystick(id);
}

HL_PRIM void HL_NAME(joy_close)(SDL_Joystick* joystick) {
	SDL_CloseJoystick(joystick);
}

HL_PRIM int HL_NAME(joy_get_axis)(SDL_Joystick* joystick, int axis) {
	return SDL_GetJoystickAxis(joystick, axis);
}

HL_PRIM int HL_NAME(joy_get_hat)(SDL_Joystick* joystick, int hat) {
	return SDL_GetJoystickHat(joystick, hat);
}

HL_PRIM bool HL_NAME(joy_get_button)(SDL_Joystick* joystick, int button) {
	return SDL_GetJoystickButton(joystick, button);
}

HL_PRIM int HL_NAME(joy_get_id)(SDL_Joystick* joystick) {
	return SDL_GetJoystickID(joystick);
}

HL_PRIM vbyte* HL_NAME(joy_get_name)(SDL_Joystick* joystick) {
	return (vbyte*)SDL_GetJoystickName(joystick);
}

HL_PRIM varray* HL_NAME(get_joysticks)() {
	int count;
	SDL_JoystickID* joysticks = SDL_GetJoysticks(&count);
	varray* result = hl_alloc_array(&hlt_i32, count);
	SDL_JoystickID* ids = hl_aptr(result, SDL_JoystickID);
	for (int i = 0; i < count; i++)
		ids[i] = joysticks[i];
	SDL_free(joysticks);
	return result;
}

DEFINE_PRIM(_I32, joy_count, _NO_ARG);
DEFINE_PRIM(TJOY, joy_open, _I32);
DEFINE_PRIM(_VOID, joy_close, TJOY);
DEFINE_PRIM(_I32, joy_get_axis, TJOY _I32);
DEFINE_PRIM(_I32, joy_get_hat, TJOY _I32);
DEFINE_PRIM(_BOOL, joy_get_button, TJOY _I32);
DEFINE_PRIM(_I32, joy_get_id, TJOY);
DEFINE_PRIM(_BYTES, joy_get_name, TJOY);
DEFINE_PRIM(_ARR, get_joysticks, _NO_ARG);
