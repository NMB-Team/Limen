#include "../core/internal.h"

HL_PRIM int HL_NAME(get_pen_device_type)(int id) {
	return SDL_GetPenDeviceType((SDL_PenID)id);
}
DEFINE_PRIM(_I32, get_pen_device_type, _I32);
