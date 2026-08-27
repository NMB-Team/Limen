#include "internal.h"

HL_PRIM void HL_NAME(delay)(int time) {
	hl_blocking(true);
	SDL_Delay(time);
	hl_blocking(false);
}

HL_PRIM double HL_NAME(get_time)() {
	return (double)SDL_GetTicksNS() * 0.000000001; // divide by 1_000_000
}

HL_PRIM int64_t HL_NAME(get_timestamp)() {
	return (int64_t)SDL_GetTicksNS();
}

DEFINE_PRIM(_VOID, delay, _I32);
DEFINE_PRIM(_F64, get_time, _NO_ARG);
DEFINE_PRIM(_I64, get_timestamp, _NO_ARG);
