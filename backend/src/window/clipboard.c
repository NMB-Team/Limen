#include "../core/internal.h"
#include <limits.h>

HL_PRIM bool HL_NAME(set_clipboard_text)(char* text) {
	return SDL_SetClipboardText(text);
}
DEFINE_PRIM(_BOOL, set_clipboard_text, _BYTES);

HL_PRIM char* HL_NAME(get_clipboard_text)() {
	char* text = SDL_GetClipboardText();
	if (text == nullptr)
		return nullptr;
	vbyte* result = hl_copy_bytes(text, (int)strlen(text) + 1);
	SDL_free(text);
	return (char*)result;
}
DEFINE_PRIM(_BYTES, get_clipboard_text, _NO_ARG);

HL_PRIM bool HL_NAME(has_clipboard_text)() {
	return SDL_HasClipboardText();
}
DEFINE_PRIM(_BOOL, has_clipboard_text, _NO_ARG);

HL_PRIM bool HL_NAME(has_clipboard_data)(char* mime_type) {
	return SDL_HasClipboardData(mime_type);
}
DEFINE_PRIM(_BOOL, has_clipboard_data, _BYTES);

HL_PRIM vbyte* HL_NAME(get_clipboard_data)(char* mime_type, int* size) {
	*size = 0;
	size_t length = 0;
	void* data = SDL_GetClipboardData(mime_type, &length);
	if (data == nullptr)
		return nullptr;
	if (length > INT_MAX) {
		SDL_free(data);
		return nullptr;
	}
	vbyte* result = hl_copy_bytes(data, (int)length);
	SDL_free(data);
	*size = (int)length;
	return result;
}
DEFINE_PRIM(_BYTES, get_clipboard_data, _BYTES _REF(_I32));

typedef struct {
	int references;
	size_t size;
	vbyte data[];
} limen_clipboard_data;

static const void* SDLCALL clipboard_data_callback(void* userdata, const char* mime_type, size_t* size) {
	limen_clipboard_data* data = userdata;
	*size = data->size;
	return data->data;
}

static void SDLCALL clipboard_data_cleanup(void* userdata) {
	limen_clipboard_data* data = userdata;
	if (--data->references == 0)
		SDL_free(data);
}

HL_PRIM bool HL_NAME(set_clipboard_data)(char* mime_type, vbyte* bytes, int size) {
	if (mime_type == nullptr || mime_type[0] == '\0' || size < 0 || (size > 0 && bytes == nullptr) || !SDL_WasInit(SDL_INIT_VIDEO))
		return false;
	limen_clipboard_data* data = SDL_malloc(sizeof(*data) + (size > 0 ? (size_t)size : 1));
	if (data == nullptr)
		return false;
	data->references = 2;
	data->size = (size_t)size;
	if (size > 0)
		memcpy(data->data, bytes, size);
	const char* mime_types[] = {mime_type};

	// SDL can run cleanup during submission or retain the callback on failure
	bool success = SDL_SetClipboardData(clipboard_data_callback, clipboard_data_cleanup, data, mime_types, 1);
	if (!success)
		SDL_ClearClipboardData();
	clipboard_data_cleanup(data);
	return success;
}
DEFINE_PRIM(_BOOL, set_clipboard_data, _BYTES _BYTES _I32);

HL_PRIM varray* HL_NAME(get_clipboard_mime_types)() {
	size_t count = 0;
	char** types = SDL_GetClipboardMimeTypes(&count);
	if (types == nullptr)
		return hl_alloc_array(&hlt_bytes, 0);
	if (count > INT_MAX) {
		SDL_free(types);
		return hl_alloc_array(&hlt_bytes, 0);
	}
	varray* result = hl_alloc_array(&hlt_bytes, (int)count);
	for (size_t index = 0; index < count; index++)
		hl_aptr(result, vbyte*)[index] = hl_copy_bytes((vbyte*)types[index], (int)strlen(types[index]) + 1);
	SDL_free(types);
	return result;
}
DEFINE_PRIM(_ARR, get_clipboard_mime_types, _NO_ARG);
