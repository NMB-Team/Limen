#ifdef HL_VULKAN_HAS_SHADERC
#include <shaderc/shaderc.h>
#endif

#include <limits.h>
#include <stdint.h>
#include <string.h>

#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>

typedef struct vk_shader_compiler {
	void (*finalize)(struct vk_shader_compiler*);
#ifdef HL_VULKAN_HAS_SHADERC
	shaderc_compiler_t compiler;
#endif
	hl_mutex* mutex;
} vk_shader_compiler;

#define _SHADER_COMPILER _ABSTRACT(vk_shader_compiler)

static int size_to_int(size_t value) {
	return value > INT_MAX ? INT_MAX : (int)value;
}

static vbyte* compile_response(int status, int warnings, int errors, const char* bytecode, size_t bytecode_size, const char* diagnostics, int* out_size) {
	if (bytecode_size > INT_MAX)
		bytecode_size = 0;
	if (diagnostics == nullptr)
		diagnostics = "";
	const size_t diagnostics_size = strlen(diagnostics);
	const size_t header_size = 5 * sizeof(int32_t);
	const size_t total_size = header_size + bytecode_size + diagnostics_size;
	if (total_size > INT_MAX) {
		*out_size = 0;
		return nullptr;
	}
	vbyte* response = hl_alloc_bytes((int)total_size);
	int32_t* header = (int32_t*)response;
	header[0] = status;
	header[1] = warnings;
	header[2] = errors;
	header[3] = (int32_t)bytecode_size;
	header[4] = (int32_t)diagnostics_size;
	if (bytecode_size > 0)
		memcpy(response + header_size, bytecode, bytecode_size);
	if (diagnostics_size > 0)
		memcpy(response + header_size + bytecode_size, diagnostics, diagnostics_size);
	*out_size = (int)total_size;
	return response;
}

#ifdef HL_VULKAN_HAS_SHADERC
static shaderc_shader_kind shader_kind(int kind) {
	switch (kind) {
	case 0: return shaderc_vertex_shader;
	case 1: return shaderc_fragment_shader;
	case 2: return shaderc_compute_shader;
	case 3: return shaderc_geometry_shader;
	case 4: return shaderc_tess_control_shader;
	case 5: return shaderc_tess_evaluation_shader;
	default: return shaderc_glsl_infer_from_source;
	}
}

static uint32_t vulkan_version(int version) {
	switch (version) {
	case 10: return shaderc_env_version_vulkan_1_0;
	case 11: return shaderc_env_version_vulkan_1_1;
	case 12: return shaderc_env_version_vulkan_1_2;
	case 13: return shaderc_env_version_vulkan_1_3;
	default: return 0;
	}
}

static shaderc_spirv_version spirv_version(int version) {
	switch (version) {
	case 10: return shaderc_spirv_version_1_0;
	case 11: return shaderc_spirv_version_1_1;
	case 12: return shaderc_spirv_version_1_2;
	case 13: return shaderc_spirv_version_1_3;
	case 14: return shaderc_spirv_version_1_4;
	case 15: return shaderc_spirv_version_1_5;
	case 16: return shaderc_spirv_version_1_6;
	default: return shaderc_spirv_version_1_0;
	}
}
#endif

static void shader_compiler_finalize(vk_shader_compiler* service) {
	if (service == nullptr)
		return;
#ifdef HL_VULKAN_HAS_SHADERC
	if (service->compiler != nullptr) {
		shaderc_compiler_release(service->compiler);
		service->compiler = nullptr;
	}
#endif
	if (service->mutex != nullptr) {
		hl_remove_root(&service->mutex);
		hl_mutex_free(service->mutex);
		service->mutex = nullptr;
	}
	service->finalize = nullptr;
}

HL_PRIM vk_shader_compiler* HL_NAME(shader_compiler_create)() {
#ifndef HL_VULKAN_HAS_SHADERC
	return nullptr;
#else
	vk_shader_compiler* service = hl_gc_alloc_finalizer(sizeof(vk_shader_compiler));
	if (service == nullptr)
		return nullptr;
	service->finalize = shader_compiler_finalize;
	service->compiler = shaderc_compiler_initialize();
	service->mutex = hl_mutex_alloc(false);
	if (service->mutex != nullptr)
		hl_add_root(&service->mutex);
	if (service->compiler == nullptr || service->mutex == nullptr) {
		shader_compiler_finalize(service);
		return nullptr;
	}
	return service;
#endif
}

HL_PRIM void HL_NAME(shader_compiler_destroy)(vk_shader_compiler* service) {
	shader_compiler_finalize(service);
}

HL_PRIM vbyte* HL_NAME(shader_compile)(
	vk_shader_compiler* service,
	vbyte* source,
	vbyte* source_name,
	vbyte* entry_point,
	int kind,
	int target_vulkan,
	int target_spirv,
	int optimization,
	bool debug_info,
	bool warnings_as_errors,
	varray* defines,
	int* out_size
) {
#ifndef HL_VULKAN_HAS_SHADERC
	const char* unavailable = "shaderc support is not available in this Vulkan build";
	return compile_response(-1, 0, 1, nullptr, 0, unavailable, out_size);
#else
	if (service == nullptr || source == nullptr || source_name == nullptr || entry_point == nullptr) {
		const char* invalid = "Invalid shader compile request";
		return compile_response(-1, 0, 1, nullptr, 0, invalid, out_size);
	}

	shaderc_compile_options_t options = shaderc_compile_options_initialize();
	if (options == nullptr) {
		const char* failure = "shaderc_compile_options_initialize failed";
		return compile_response(-1, 0, 1, nullptr, 0, failure, out_size);
	}

	shaderc_compile_options_set_source_language(options, shaderc_source_language_glsl);
	shaderc_compile_options_set_target_env(options, shaderc_target_env_vulkan, vulkan_version(target_vulkan));
	shaderc_compile_options_set_target_spirv(options, spirv_version(target_spirv));
	switch (optimization) {
	case 1:
		shaderc_compile_options_set_optimization_level(options, shaderc_optimization_level_size);
		break;
	case 2:
		shaderc_compile_options_set_optimization_level(options, shaderc_optimization_level_performance);
		break;
	default:
		shaderc_compile_options_set_optimization_level(options, shaderc_optimization_level_zero);
		break;
	}
	if (debug_info)
		shaderc_compile_options_set_generate_debug_info(options);
	if (warnings_as_errors)
		shaderc_compile_options_set_warnings_as_errors(options);
	if (defines != nullptr) {
		vbyte** values = hl_aptr(defines, vbyte*);
		for (int i = 0; i < defines->size; ++i) {
			const char* define = (const char*)values[i];
			if (define == nullptr || *define == '\0')
				continue;
			const char* separator = strchr(define, '=');
			const size_t name_length = separator == nullptr ? strlen(define) : (size_t)(separator - define);
			const char* value = separator == nullptr ? nullptr : separator + 1;
			const size_t value_length = value == nullptr ? 0 : strlen(value);
			shaderc_compile_options_add_macro_definition(options, define, name_length, value, value_length);
		}
	}

	hl_mutex_acquire(service->mutex);
	shaderc_compilation_result_t result = shaderc_compile_into_spv(
		service->compiler,
		(const char*)source,
		strlen((const char*)source),
		shader_kind(kind),
		(const char*)source_name,
		(const char*)entry_point,
		options
	);
	hl_mutex_release(service->mutex);
	shaderc_compile_options_release(options);
	if (result == nullptr) {
		const char* failure = "shaderc_compile_into_spv returned no result";
		return compile_response(-1, 0, 1, nullptr, 0, failure, out_size);
	}

	int status = (int)shaderc_result_get_compilation_status(result);
	const int warnings = size_to_int(shaderc_result_get_num_warnings(result));
	int errors = size_to_int(shaderc_result_get_num_errors(result));
	const char* message = shaderc_result_get_error_message(result);
	if (message == nullptr)
		message = "";
	const size_t bytecode_size = status == shaderc_compilation_status_success ? shaderc_result_get_length(result) : 0;
	const char* bytecode = status == shaderc_compilation_status_success ? shaderc_result_get_bytes(result) : nullptr;
	if (bytecode_size > INT_MAX) {
		status = -1;
		errors = 1;
		message = "Compiled SPIR-V exceeds the supported bytecode size";
	}
	vbyte* response = compile_response(status, warnings, errors, bytecode, bytecode_size, message, out_size);
	shaderc_result_release(result);
	return response;
#endif
}

DEFINE_PRIM(_SHADER_COMPILER, shader_compiler_create, _NO_ARG);
DEFINE_PRIM(_VOID, shader_compiler_destroy, _SHADER_COMPILER);
DEFINE_PRIM(_BYTES, shader_compile, _SHADER_COMPILER _BYTES _BYTES _BYTES _I32 _I32 _I32 _I32 _BOOL _BOOL _ARR _REF(_I32));
