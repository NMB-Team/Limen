#pragma once

#include "internal.h"

void* limen_module_load(const char* name);
void* limen_module_resolve(const char* module_name, const char* primitive_name, const char** signature);
void limen_modules_unload(void);

#define LIMEN_MODULE_PROXY(module, primitive) \
	HL_EXTERN_C HL_EXPORT void* hlp_##module##_##primitive(const char** signature) { \
		return limen_module_resolve(#module ".limen", #primitive, signature); \
	}
