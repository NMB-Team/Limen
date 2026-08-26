#include "core/internal.h"
#include <stdio.h>

extern void* hlp_win_create_ex(const char** signature);
extern SDL_Window* limen_win_create_ex(int x, int y, int width, int height, int64_t flags);
extern int64_t limen_test_last_window_flags(void);
extern void limen_window_destroy(SDL_Window* window);

int main(void) {
	const char* signature;
	hlp_win_create_ex(&signature);
	if (strcmp(signature, _FUN(TWIN, _I32 _I32 _I32 _I32 _I64)) != 0) {
		fprintf(stderr, "win_create_ex does not use the HashLink _I64 ABI for flags\n");
		return 1;
	}

	SDL_Window* window = limen_win_create_ex(
		SDL_WINDOWPOS_CENTERED,
		SDL_WINDOWPOS_CENTERED,
		64,
		64,
		(int64_t)SDL_WINDOW_NOT_FOCUSABLE
	);
	if (limen_test_last_window_flags() != INT64_C(0x0000000080000000)) {
		fprintf(stderr, "SDL_WINDOW_NOT_FOCUSABLE was changed across the native ABI\n");
		return 1;
	}
	if (window == nullptr) {
		fprintf(stderr, "Window creation failed\n");
		return 1;
	}

	limen_window_destroy(window);
	return 0;
}
