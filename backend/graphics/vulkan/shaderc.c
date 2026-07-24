#ifdef HL_VULKAN_HAS_SHADERC
#include <shaderc/shaderc.h>
#endif

#include <stdint.h>
#include <string.h>

#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>

HL_PRIM vbyte* HL_NAME(compile_shader)(vbyte* source, vbyte* shaderFile, vbyte* mainFunction, int shaderKind, int* outSize) {
#ifndef HL_VULKAN_HAS_SHADERC
	const char* error = "shaderc support is not available in this HashLink build";
	*outSize = -1;
	return hl_copy_bytes((const vbyte*)error, (int)strlen(error) + 1);
#else
	shaderc_compiler_t compiler = shaderc_compiler_initialize();
	shaderc_compile_options_t opts = shaderc_compile_options_initialize();
	shaderc_compile_options_set_optimization_level(opts, shaderc_optimization_level_size);
	shaderc_compilation_result_t result = shaderc_compile_into_spv(compiler, source, strlen(source), shaderKind, shaderFile, mainFunction, opts);
	shaderc_compiler_release(compiler);
	shaderc_compile_options_release(opts);

	if (shaderc_result_get_compilation_status(result) != shaderc_compilation_status_success) {
		const char* str = shaderc_result_get_error_message(result);
		vbyte* error = hl_copy_bytes(str, (int)strlen(str) + 1);
		shaderc_result_release(result);
		*outSize = -1;
		return error;
	}

	int size = (int)shaderc_result_get_length(result);
	vbyte* data = hl_alloc_bytes(size);
	memcpy(data, shaderc_result_get_bytes(result), size);
	shaderc_result_release(result);

	*outSize = size;
	return data;
#endif
}

DEFINE_PRIM(_BYTES, compile_shader, _BYTES _BYTES _BYTES _I32 _REF(_I32));
