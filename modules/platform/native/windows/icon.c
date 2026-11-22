#include "icon.h"
#include <SDL3/SDL.h>
#include <windows.h>

#define LIMEN_ICON_PROPERTY "limen.window_icons"

typedef struct {
	HWND window;
	SDL_WindowID id;
	HICON small_icon;
	HICON big_icon;
} limen_window_icons;

static bool SDLCALL restore_icons(void* userdata, SDL_Event* event) {
	limen_window_icons* icons = userdata;

	if (event->type == SDL_EVENT_WINDOW_LEAVE_FULLSCREEN && event->window.windowID == icons->id) {
		SendMessage(icons->window, WM_SETICON, ICON_SMALL, 0);
		SendMessage(icons->window, WM_SETICON, ICON_SMALL, (LPARAM)icons->small_icon);
		SendMessage(icons->window, WM_SETICON, ICON_BIG, (LPARAM)icons->big_icon);
	}

	return true;
}

static void SDLCALL cleanup_icons(void* userdata, void* value) {
	limen_window_icons* icons = value;
	(void)userdata;

	SDL_RemoveEventWatch(restore_icons, icons);

	DestroyIcon(icons->small_icon);
	DestroyIcon(icons->big_icon);
	SDL_free(icons);
}

void limen_windows_cleanup_icons(SDL_Window* window) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	limen_window_icons* icons = SDL_GetPointerProperty(properties, LIMEN_ICON_PROPERTY, nullptr);

	if (icons == nullptr)
		return;

	SendMessage(icons->window, WM_SETICON, ICON_SMALL, 0);
	SendMessage(icons->window, WM_SETICON, ICON_BIG, 0);
	SDL_ClearProperty(properties, LIMEN_ICON_PROPERTY);
}

static HICON create_icon(SDL_Surface* surface) {
	SDL_Surface* pixels = SDL_ConvertSurface(surface, SDL_PIXELFORMAT_ARGB8888);

	if (pixels == nullptr)
		return nullptr;

	size_t row_size = (size_t)pixels->w * 4;
	size_t mask_pitch = (((size_t)pixels->w + 31) / 32) * 4;
	Uint64 size = sizeof(BITMAPINFOHEADER) + ((Uint64)row_size + mask_pitch) * pixels->h;

	if (size > MAXDWORD || pixels->h > INT_MAX / 2) {
		SDL_DestroySurface(pixels);
		SDL_SetError("Window icon is too large");

		return nullptr;
	}

	BYTE* data = SDL_calloc(1, (size_t)size);

	if (data == nullptr) {
		SDL_DestroySurface(pixels);

		return nullptr;
	}

	BITMAPINFOHEADER* header = (BITMAPINFOHEADER*)data;
	header->biSize = sizeof(*header);
	header->biWidth = pixels->w;
	header->biHeight = pixels->h * 2;
	header->biPlanes = 1;
	header->biBitCount = 32;
	header->biCompression = BI_RGB;

	for (int y = 0; y < pixels->h; ++y) {
		SDL_memcpy(data + sizeof(*header) + (size_t)y * row_size,
		           (BYTE*)pixels->pixels + (size_t)(pixels->h - 1 - y) * pixels->pitch, row_size);
	}

	HICON icon = CreateIconFromResource(data, (DWORD)size, TRUE, 0x00030000);

	if (icon == nullptr)
		SDL_SetError("Could not create window icon, error %lu", (unsigned long)GetLastError());

	SDL_free(data);
	SDL_DestroySurface(pixels);

	return icon;
}

bool limen_windows_set_icon(SDL_Window* window, SDL_Surface* surface) {
	SDL_PropertiesID properties = SDL_GetWindowProperties(window);
	HWND native = SDL_GetPointerProperty(properties, SDL_PROP_WINDOW_WIN32_HWND_POINTER, nullptr);

	if (native == nullptr)
		return false;

	int count;
	SDL_Surface** images = SDL_GetSurfaceImages(surface, &count);

	if (images == nullptr)
		return false;

	SDL_Surface* selected[2] = { nullptr, nullptr };
	Sint64 closest[2] = { -1, -1 };
	int widths[2] = { GetSystemMetrics(SM_CXSMICON), GetSystemMetrics(SM_CXICON) };
	int heights[2] = { GetSystemMetrics(SM_CYSMICON), GetSystemMetrics(SM_CYICON) };

	for (int i = 0; i < count; ++i) {
		for (int slot = 0; slot < 2; ++slot) {
			Sint64 dx = (Sint64)images[i]->w - widths[slot];
			Sint64 dy = (Sint64)images[i]->h - heights[slot];
			Sint64 distance = dx * dx + dy * dy;

			if (dx < 0 || dy < 0)
				distance += 1000000;

			if (closest[slot] < 0 || distance < closest[slot]) {
				selected[slot] = images[i];
				closest[slot] = distance;
			}
		}
	}

	SDL_free(images);

	if (selected[0] == nullptr || selected[1] == nullptr)
		return false;

	HICON small_icon = create_icon(selected[0]);

	if (small_icon == nullptr)
		return false;

	HICON big_icon = create_icon(selected[1]);

	if (big_icon == nullptr) {
		DestroyIcon(small_icon);

		return false;
	}

	limen_window_icons* icons = SDL_GetPointerProperty(properties, LIMEN_ICON_PROPERTY, nullptr);

	if (icons == nullptr) {
		icons = SDL_calloc(1, sizeof(*icons));

		if (icons == nullptr) {
			DestroyIcon(small_icon);
			DestroyIcon(big_icon);

			return false;
		}

		icons->window = native;
		icons->id = SDL_GetWindowID(window);

		if (!SDL_SetPointerPropertyWithCleanup(properties, LIMEN_ICON_PROPERTY, icons, cleanup_icons, nullptr)) {
			DestroyIcon(small_icon);
			DestroyIcon(big_icon);

			return false;
		}

		if (!SDL_AddEventWatch(restore_icons, icons)) {
			SDL_ClearProperty(properties, LIMEN_ICON_PROPERTY);
			DestroyIcon(small_icon);
			DestroyIcon(big_icon);

			return false;
		}
	}

	HICON old_small = icons->small_icon;
	HICON old_big = icons->big_icon;
	icons->small_icon = small_icon;
	icons->big_icon = big_icon;

	SendMessage(native, WM_SETICON, ICON_SMALL, (LPARAM)small_icon);
	SendMessage(native, WM_SETICON, ICON_BIG, (LPARAM)big_icon);

	if (old_small != nullptr)
		DestroyIcon(old_small);

	if (old_big != nullptr)
		DestroyIcon(old_big);

	return true;
}
