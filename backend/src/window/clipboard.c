#include "../core/internal.h"

HL_PRIM bool HL_NAME(set_clipboard_text)(char* text) {
	return SDL_SetClipboardText(text);
}

HL_PRIM char* HL_NAME(get_clipboard_text)() {
	char* text = SDL_GetClipboardText();
	if (text == NULL)
		return NULL;
	vbyte* result = hl_copy_bytes(text, (int)strlen(text) + 1);
	SDL_free(text);
	return (char*)result;
}

DEFINE_PRIM(_BOOL, set_clipboard_text, _BYTES);
DEFINE_PRIM(_BYTES, get_clipboard_text, _NO_ARG);
