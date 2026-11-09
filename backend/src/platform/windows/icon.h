#pragma once

#include <SDL3/SDL_video.h>

bool limen_windows_set_icon(SDL_Window* window, SDL_Surface* surface);
void limen_windows_cleanup_icons(SDL_Window* window);
