#include "../core/internal.h"

#define _TRAY _ABSTRACT(limen_tray)
#define _TRAY_MENU _ABSTRACT(limen_tray_menu)
#define _TRAY_ENTRY _ABSTRACT(limen_tray_entry)

typedef struct limen_tray_callback {
	struct limen_tray_callback* next;
	int id;
	bool checked;
} limen_tray_callback;

static limen_tray_callback* pending_head = nullptr;
static limen_tray_callback* pending_tail = nullptr;
static bool callback_allocation_failed = false;

// SDL callbacks only queue values
// haxe dispatches after SDL has finished pumping events
static void queue_callback(int id, bool checked) {
	limen_tray_callback* pending = SDL_malloc(sizeof(*pending));
	if (pending == nullptr) {
		callback_allocation_failed = true;
		return;
	}
	*pending = (limen_tray_callback){.id = id, .checked = checked};
	if (pending_tail != nullptr)
		pending_tail->next = pending;
	else
		pending_head = pending;
	pending_tail = pending;
}

static void SDLCALL button_callback(void* userdata, SDL_TrayEntry* entry) {
	(void)entry;
	queue_callback((int)(intptr_t)userdata, false);
}

static void SDLCALL checkbox_callback(void* userdata, SDL_TrayEntry* entry) {
	queue_callback((int)(intptr_t)userdata, SDL_GetTrayEntryChecked(entry));
}

void limen_tray_clear_callbacks(void) {
	while (pending_head != nullptr) {
		limen_tray_callback* pending = pending_head;
		pending_head = pending->next;
		SDL_free(pending);
	}
	pending_tail = nullptr;
	callback_allocation_failed = false;
}

HL_PRIM SDL_Tray* HL_NAME(tray_create)(SDL_Surface* icon, vbyte* tooltip) {
	return SDL_CreateTray(icon, (const char*)tooltip);
}
DEFINE_PRIM(_TRAY, tray_create, _SURF _BYTES);

HL_PRIM void HL_NAME(tray_destroy)(SDL_Tray* tray) {
	SDL_DestroyTray(tray);
}
DEFINE_PRIM(_VOID, tray_destroy, _TRAY);

HL_PRIM void HL_NAME(tray_set_icon)(SDL_Tray* tray, SDL_Surface* icon) {
	SDL_SetTrayIcon(tray, icon);
}
DEFINE_PRIM(_VOID, tray_set_icon, _TRAY _SURF);

HL_PRIM void HL_NAME(tray_set_tooltip)(SDL_Tray* tray, vbyte* tooltip) {
	SDL_SetTrayTooltip(tray, (const char*)tooltip);
}
DEFINE_PRIM(_VOID, tray_set_tooltip, _TRAY _BYTES);

HL_PRIM SDL_TrayMenu* HL_NAME(tray_create_menu)(SDL_Tray* tray) {
	SDL_TrayMenu* menu = SDL_GetTrayMenu(tray);
	return menu != nullptr ? menu : SDL_CreateTrayMenu(tray);
}
DEFINE_PRIM(_TRAY_MENU, tray_create_menu, _TRAY);

HL_PRIM SDL_TrayMenu* HL_NAME(tray_create_submenu)(SDL_TrayEntry* entry) {
	return SDL_CreateTraySubmenu(entry);
}
DEFINE_PRIM(_TRAY_MENU, tray_create_submenu, _TRAY_ENTRY);

HL_PRIM SDL_TrayEntry* HL_NAME(tray_insert_entry)(SDL_TrayMenu* menu, vbyte* label, int kind, bool checked) {
	SDL_TrayEntryFlags flags = (SDL_TrayEntryFlags)kind;
	if (checked)
		flags |= SDL_TRAYENTRY_CHECKED;
	return SDL_InsertTrayEntryAt(menu, -1, (const char*)label, flags);
}
DEFINE_PRIM(_TRAY_ENTRY, tray_insert_entry, _TRAY_MENU _BYTES _I32 _BOOL);

HL_PRIM void HL_NAME(tray_remove_entry)(SDL_TrayEntry* entry) {
	SDL_RemoveTrayEntry(entry);
}
DEFINE_PRIM(_VOID, tray_remove_entry, _TRAY_ENTRY);

HL_PRIM void HL_NAME(tray_set_entry_label)(SDL_TrayEntry* entry, vbyte* label) {
	SDL_SetTrayEntryLabel(entry, (const char*)label);
}
DEFINE_PRIM(_VOID, tray_set_entry_label, _TRAY_ENTRY _BYTES);

HL_PRIM vbyte* HL_NAME(tray_get_entry_label)(SDL_TrayEntry* entry) {
	const char* label = SDL_GetTrayEntryLabel(entry);
	return label == nullptr ? nullptr : hl_copy_bytes((const vbyte*)label, (int)strlen(label) + 1);
}
DEFINE_PRIM(_BYTES, tray_get_entry_label, _TRAY_ENTRY);

HL_PRIM void HL_NAME(tray_set_entry_enabled)(SDL_TrayEntry* entry, bool enabled) {
	SDL_SetTrayEntryEnabled(entry, enabled);
}
DEFINE_PRIM(_VOID, tray_set_entry_enabled, _TRAY_ENTRY _BOOL);

HL_PRIM bool HL_NAME(tray_get_entry_enabled)(SDL_TrayEntry* entry) {
	return SDL_GetTrayEntryEnabled(entry);
}
DEFINE_PRIM(_BOOL, tray_get_entry_enabled, _TRAY_ENTRY);

HL_PRIM void HL_NAME(tray_set_entry_checked)(SDL_TrayEntry* entry, bool checked) {
	SDL_SetTrayEntryChecked(entry, checked);
}
DEFINE_PRIM(_VOID, tray_set_entry_checked, _TRAY_ENTRY _BOOL);

HL_PRIM bool HL_NAME(tray_get_entry_checked)(SDL_TrayEntry* entry) {
	return SDL_GetTrayEntryChecked(entry);
}
DEFINE_PRIM(_BOOL, tray_get_entry_checked, _TRAY_ENTRY);

HL_PRIM void HL_NAME(tray_set_entry_callback)(SDL_TrayEntry* entry, int id, bool checkbox) {
	SDL_SetTrayEntryCallback(entry, id == 0 ? nullptr : (checkbox ? checkbox_callback : button_callback), (void*)(intptr_t)id);
}
DEFINE_PRIM(_VOID, tray_set_entry_callback, _TRAY_ENTRY _I32 _BOOL);

HL_PRIM int HL_NAME(tray_poll_callback)(bool* checked) {
	if (callback_allocation_failed) {
		callback_allocation_failed = false;
		hl_error("Could not allocate tray callback");
	}
	if (pending_head == nullptr)
		return 0;
	limen_tray_callback* pending = pending_head;
	int id = pending->id;
	*checked = pending->checked;
	pending_head = pending->next;
	if (pending_head == nullptr)
		pending_tail = nullptr;
	SDL_free(pending);
	return id;
}
DEFINE_PRIM(_I32, tray_poll_callback, _REF(_BOOL));

HL_PRIM void HL_NAME(tray_update)() {
	SDL_UpdateTrays();
}
DEFINE_PRIM(_VOID, tray_update, _NO_ARG);
