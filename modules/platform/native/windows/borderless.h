#pragma once

#include <SDL3/SDL_video.h>

bool limen_windows_prepare_fullscreen(SDL_Window* window, int mode);
bool limen_windows_set_borderless_fixed(SDL_Window* window);
void limen_windows_cleanup_borderless(SDL_Window* window);
