#include "../core/internal.h"

#define _CURSOR _ABSTRACT(limen_cursor)

HL_PRIM SDL_Surface* HL_NAME(surface_from)(vbyte* pixels, int width, int height, int depth, int pitch, int red_mask, int green_mask, int blue_mask, int alpha_mask) {
	SDL_PixelFormat format = SDL_GetPixelFormatForMasks(depth, red_mask, green_mask, blue_mask, alpha_mask);
	return SDL_CreateSurfaceFrom(width, height, format, pixels, pitch);
}
DEFINE_PRIM(_SURF, surface_from, _BYTES _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);

HL_PRIM void HL_NAME(free_surface)(SDL_Surface* surface) {
	SDL_DestroySurface(surface);
}
DEFINE_PRIM(_VOID, free_surface, _SURF);

HL_PRIM void HL_NAME(show_cursor)(bool visible) {
	if (visible)
		SDL_ShowCursor();
	else
		SDL_HideCursor();
}
DEFINE_PRIM(_VOID, show_cursor, _BOOL);

HL_PRIM bool HL_NAME(is_cursor_visible)() {
	return SDL_CursorVisible();
}
DEFINE_PRIM(_BOOL, is_cursor_visible, _NO_ARG);

HL_PRIM SDL_Cursor* HL_NAME(cursor_create)(SDL_Surface* surface, int hot_x, int hot_y) {
	return SDL_CreateColorCursor(surface, hot_x, hot_y);
}
DEFINE_PRIM(_CURSOR, cursor_create, _SURF _I32 _I32);

HL_PRIM SDL_Cursor* HL_NAME(cursor_create_system)(int kind) {
	return SDL_CreateSystemCursor(kind);
}
DEFINE_PRIM(_CURSOR, cursor_create_system, _I32);

HL_PRIM void HL_NAME(free_cursor)(SDL_Cursor* cursor) {
	SDL_DestroyCursor(cursor);
}
DEFINE_PRIM(_VOID, free_cursor, _CURSOR);

HL_PRIM void HL_NAME(set_cursor)(SDL_Cursor* cursor) {
	SDL_SetCursor(cursor);
}
DEFINE_PRIM(_VOID, set_cursor, _CURSOR);
