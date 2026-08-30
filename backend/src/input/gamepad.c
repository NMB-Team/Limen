#include "../core/internal.h"

#define TGCTRL _ABSTRACT(limen_gamepad)
#define THAPTIC _ABSTRACT(limen_haptic)

HL_PRIM int HL_NAME(gctrl_count)() {
	int count;
	SDL_JoystickID* gamepads = SDL_GetGamepads(&count);
	SDL_free(gamepads);
	return count;
}
DEFINE_PRIM(_I32, gctrl_count, _NO_ARG);

HL_PRIM SDL_Gamepad* HL_NAME(gctrl_open)(SDL_JoystickID id) {
	return SDL_OpenGamepad(id);
}
DEFINE_PRIM(TGCTRL, gctrl_open, _I32);

HL_PRIM void HL_NAME(gctrl_close)(SDL_Gamepad* controller) {
	SDL_CloseGamepad(controller);
}
DEFINE_PRIM(_VOID, gctrl_close, TGCTRL);

HL_PRIM int HL_NAME(gctrl_get_axis)(SDL_Gamepad* controller, int axis) {
	return SDL_GetGamepadAxis(controller, axis);
}
DEFINE_PRIM(_I32, gctrl_get_axis, TGCTRL _I32);

HL_PRIM bool HL_NAME(gctrl_get_button)(SDL_Gamepad* controller, int button) {
	return SDL_GetGamepadButton(controller, button);
}
DEFINE_PRIM(_BOOL, gctrl_get_button, TGCTRL _I32);

HL_PRIM int HL_NAME(gctrl_get_id)(SDL_Gamepad* controller) {
	return SDL_GetGamepadID(controller);
}
DEFINE_PRIM(_I32, gctrl_get_id, TGCTRL);

HL_PRIM vbyte* HL_NAME(gctrl_get_name)(SDL_Gamepad* controller) {
	return (vbyte*)SDL_GetGamepadName(controller);
}
DEFINE_PRIM(_BYTES, gctrl_get_name, TGCTRL);

HL_PRIM bool HL_NAME(gctrl_rumble)(SDL_Gamepad* controller, double strength, int length) {
	if (length < 0)
		return false;
	if (strength < 0)
		strength = 0;
	else if (strength > 1)
		strength = 1;
	Uint16 intensity = (Uint16)(strength * 65535.0);
	return SDL_RumbleGamepad(controller, intensity, intensity, (Uint32)length);
}
DEFINE_PRIM(_BOOL, gctrl_rumble, TGCTRL _F64 _I32);

HL_PRIM SDL_Haptic* HL_NAME(haptic_open)(SDL_Gamepad* controller) {
	return SDL_OpenHapticFromJoystick(SDL_GetGamepadJoystick(controller));
}
DEFINE_PRIM(THAPTIC, haptic_open, TGCTRL);

HL_PRIM void HL_NAME(haptic_close)(SDL_Haptic* haptic) {
	SDL_CloseHaptic(haptic);
}
DEFINE_PRIM(_VOID, haptic_close, THAPTIC);

HL_PRIM int HL_NAME(haptic_rumble_init)(SDL_Haptic* haptic) {
	return SDL_InitHapticRumble(haptic) ? 0 : -1;
}
DEFINE_PRIM(_I32, haptic_rumble_init, THAPTIC);

HL_PRIM int HL_NAME(haptic_rumble_play)(SDL_Haptic* haptic, double strength, int length) {
	return SDL_PlayHapticRumble(haptic, (float)strength, length) ? 0 : -1;
}
DEFINE_PRIM(_I32, haptic_rumble_play, THAPTIC _F64 _I32);
