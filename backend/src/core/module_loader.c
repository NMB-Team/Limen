#include "module_loader.h"

typedef void* (*limen_primitive_resolver)(const char** signature);

typedef struct limen_module {
	struct limen_module* next;
	char* name;
	void* handle;
	bool load_attempted;
} limen_module;

typedef struct limen_primitive {
	struct limen_primitive* next;
	limen_module* module;
	char* name;
	void* function;
	const char* signature;
} limen_primitive;

static limen_module* limen_modules;
static limen_primitive* limen_primitives;

static void limen_primitive_not_loaded(void) {
	hl_error("The LIMEN module primitive is not loaded");
}

static limen_module* limen_module_get(const char* name) {
	for (limen_module* module = limen_modules; module != NULL; module = module->next) {
		if (SDL_strcmp(module->name, name) == 0)
			return module;
	}

	limen_module* module = SDL_malloc(sizeof(*module));
	module->next = limen_modules;
	module->name = SDL_strdup(name);
	module->handle = NULL;
	module->load_attempted = false;
	limen_modules = module;
	return module;
}

void* limen_module_load(const char* name) {
	limen_module* module = limen_module_get(name);
	if (!module->load_attempted) {
		module->load_attempted = true;
		module->handle = SDL_LoadObject(name);
	}
	return module->handle;
}

void* limen_module_resolve(const char* module_name, const char* primitive_name, const char** signature) {
	limen_module* module = limen_module_get(module_name);
	for (limen_primitive* primitive = limen_primitives; primitive != NULL; primitive = primitive->next) {
		if (primitive->module == module && SDL_strcmp(primitive->name, primitive_name) == 0) {
			*signature = primitive->signature;
			return primitive->function;
		}
	}

	limen_primitive* primitive = SDL_malloc(sizeof(*primitive));
	primitive->next = limen_primitives;
	primitive->module = module;
	primitive->name = SDL_strdup(primitive_name);
	primitive->function = (void*)&limen_primitive_not_loaded;
	primitive->signature = NULL;
	limen_primitives = primitive;

	void* handle = limen_module_load(module_name);
	if (handle != NULL) {
		size_t symbol_length = SDL_strlen(primitive_name) + sizeof("hlp_");
		char* symbol = SDL_malloc(symbol_length);
		SDL_snprintf(symbol, symbol_length, "hlp_%s", primitive_name);
		limen_primitive_resolver resolver = (limen_primitive_resolver)SDL_LoadFunction(handle, symbol);
		SDL_free(symbol);
		if (resolver != NULL) {
			void* function = resolver(&primitive->signature);
			if (function != NULL)
				primitive->function = function;
		}
	}

	SDL_ClearError();
	*signature = primitive->signature;
	return primitive->function;
}

void limen_modules_unload(void) {
	while (limen_primitives != NULL) {
		limen_primitive* primitive = limen_primitives;
		limen_primitives = primitive->next;
		SDL_free(primitive->name);
		SDL_free(primitive);
	}

	while (limen_modules != NULL) {
		limen_module* module = limen_modules;
		limen_modules = module->next;
		if (module->handle != NULL)
			SDL_UnloadObject(module->handle);
		SDL_free(module->name);
		SDL_free(module);
	}
}
