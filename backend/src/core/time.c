#include "internal.h"

HL_PRIM void HL_NAME(delay)(int time) {
	hl_blocking(true);
	SDL_Delay(time);
	hl_blocking(false);
}

HL_PRIM double HL_NAME(get_time)() {
	return (double)SDL_GetTicksNS() / 1000000000.0;
}

DEFINE_PRIM(_VOID, delay, _I32);
DEFINE_PRIM(_F64, get_time, _NO_ARG);
