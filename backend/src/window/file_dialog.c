#include "../core/internal.h"

typedef enum {
	LIMEN_DIALOG_ERROR = -1,
	LIMEN_DIALOG_CANCELLED,
	LIMEN_DIALOG_SELECTED,
} limen_dialog_status;

typedef struct {
	vclosure* callback;
	SDL_DialogFileFilter* filters;
	int filter_count;
	char* default_location;
} limen_dialog_data;

static void free_dialog_data(limen_dialog_data* data) {
	for (int index = 0; index < data->filter_count; index++) {
		SDL_free((void*)data->filters[index].name);
		SDL_free((void*)data->filters[index].pattern);
	}
	SDL_free(data->filters);
	SDL_free(data->default_location);
	SDL_free(data);
}

static limen_dialog_data* create_dialog_data(vclosure* callback, varray* filter_names, varray* filter_patterns, const char* default_location) {
	limen_dialog_data* data = SDL_calloc(1, sizeof(*data));
	if (data == nullptr)
		hl_error("Could not allocate file dialog data");

	data->callback = callback;
	data->filter_count = filter_names == nullptr ? 0 : filter_names->size;
	if (data->filter_count > 0) {
		data->filters = SDL_calloc(data->filter_count, sizeof(*data->filters));
		if (data->filters == nullptr) {
			free_dialog_data(data);
			hl_error("Could not allocate file dialog filters");
		}

		vbyte** names = hl_aptr(filter_names, vbyte*);
		vbyte** patterns = hl_aptr(filter_patterns, vbyte*);
		for (int index = 0; index < data->filter_count; index++) {
			data->filters[index].name = SDL_strdup((const char*)names[index]);
			data->filters[index].pattern = SDL_strdup((const char*)patterns[index]);
			if (data->filters[index].name == nullptr || data->filters[index].pattern == nullptr) {
				free_dialog_data(data);
				hl_error("Could not copy file dialog filters");
			}
		}
	}

	if (default_location != nullptr) {
		data->default_location = SDL_strdup(default_location);
		if (data->default_location == nullptr) {
			free_dialog_data(data);
			hl_error("Could not copy file dialog location");
		}
	}

	hl_add_root(&data->callback);
	return data;
}

static void SDLCALL file_dialog_callback(void* userdata, const char* const* file_list, int selected_filter) {
	limen_dialog_data* data = userdata;
	vdynamic* stack_top;
	bool registered_thread = hl_get_thread() == nullptr;
	if (registered_thread)
		hl_register_thread(&stack_top);

	limen_dialog_status status;
	varray* paths = nullptr;
	vbyte* error = nullptr;
	if (file_list == nullptr) {
		status = LIMEN_DIALOG_ERROR;
		const char* message = SDL_GetError();
		error = hl_copy_bytes((const vbyte*)message, (int)strlen(message) + 1);
	} else if (file_list[0] == nullptr) {
		status = LIMEN_DIALOG_CANCELLED;
	} else {
		status = LIMEN_DIALOG_SELECTED;
		int count = 0;
		while (file_list[count] != nullptr)
			count++;
		paths = hl_alloc_array(&hlt_bytes, count);
		vbyte** destination = hl_aptr(paths, vbyte*);
		for (int index = 0; index < count; index++)
			destination[index] = hl_copy_bytes((const vbyte*)file_list[index], (int)strlen(file_list[index]) + 1);
	}

	int status_value = status;
	vdynamic* arguments[] = {
		hl_make_dyn(&status_value, &hlt_i32),
		(vdynamic*)paths,
		hl_make_dyn(&error, &hlt_bytes),
		hl_make_dyn(&selected_filter, &hlt_i32),
	};
	bool is_exception;
	vdynamic* exception = hl_dyn_call_safe(data->callback, arguments, 4, &is_exception);

	hl_remove_root(&data->callback);
	free_dialog_data(data);

	if (registered_thread) {
		if (is_exception)
			hl_print_uncaught_exception(exception);
		hl_unregister_thread();
	} else if (is_exception)
		hl_rethrow(exception);
}

HL_PRIM void HL_NAME(show_open_file_dialog)(vclosure* callback, SDL_Window* window, varray* filter_names, varray* filter_patterns, vbyte* default_location, bool allow_multiple) {
	limen_dialog_data* data = create_dialog_data(callback, filter_names, filter_patterns, (const char*)default_location);
	SDL_ShowOpenFileDialog(file_dialog_callback, data, window, data->filters, data->filter_count, data->default_location, allow_multiple);
}
DEFINE_PRIM(_VOID, show_open_file_dialog, _FUN(_VOID, _I32 _ARR _BYTES _I32) TWIN _ARR _ARR _BYTES _BOOL);

HL_PRIM void HL_NAME(show_open_folder_dialog)(vclosure* callback, SDL_Window* window, vbyte* default_location, bool allow_multiple) {
	limen_dialog_data* data = create_dialog_data(callback, nullptr, nullptr, (const char*)default_location);
	SDL_ShowOpenFolderDialog(file_dialog_callback, data, window, data->default_location, allow_multiple);
}
DEFINE_PRIM(_VOID, show_open_folder_dialog, _FUN(_VOID, _I32 _ARR _BYTES _I32) TWIN _BYTES _BOOL);

HL_PRIM void HL_NAME(show_save_file_dialog)(vclosure* callback, SDL_Window* window, varray* filter_names, varray* filter_patterns, vbyte* default_location) {
	limen_dialog_data* data = create_dialog_data(callback, filter_names, filter_patterns, (const char*)default_location);
	SDL_ShowSaveFileDialog(file_dialog_callback, data, window, data->filters, data->filter_count, data->default_location);
}
DEFINE_PRIM(_VOID, show_save_file_dialog, _FUN(_VOID, _I32 _ARR _BYTES _I32) TWIN _ARR _ARR _BYTES);
