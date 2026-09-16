#ifdef HL_VULKAN_HAS_SPIRV_TOOLS
#include <spirv-tools/libspirv.h>
#endif
#ifdef HL_VULKAN_HAS_SPIRV_REFLECT
#include <spirv_reflect.h>
#endif

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define HL_NAME(n) limen_vulkan_##n
#include <hl.h>

typedef struct {
	char* data;
	size_t length;
	size_t capacity;
	bool failed;
} json_buffer;

static void json_reserve(json_buffer* buffer, size_t extra) {
	if (buffer->failed || extra > SIZE_MAX - buffer->length - 1) {
		buffer->failed = true;
		return;
	}
	const size_t required = buffer->length + extra + 1;
	if (required <= buffer->capacity)
		return;
	size_t capacity = buffer->capacity == 0 ? 1024 : buffer->capacity;
	while (capacity < required) {
		if (capacity > SIZE_MAX / 2) {
			buffer->failed = true;
			return;
		}
		capacity *= 2;
	}
	char* data = realloc(buffer->data, capacity);
	if (data == nullptr) {
		buffer->failed = true;
		return;
	}
	buffer->data = data;
	buffer->capacity = capacity;
}

static void json_append(json_buffer* buffer, const char* text) {
	const size_t length = strlen(text);
	json_reserve(buffer, length);
	if (buffer->failed)
		return;
	memcpy(buffer->data + buffer->length, text, length);
	buffer->length += length;
	buffer->data[buffer->length] = '\0';
}

static void json_format(json_buffer* buffer, const char* format, ...) {
	va_list args;
	va_start(args, format);
	va_list copy;
	va_copy(copy, args);
	const int length = vsnprintf(nullptr, 0, format, copy);
	va_end(copy);
	if (length < 0) {
		buffer->failed = true;
		va_end(args);
		return;
	}
	json_reserve(buffer, (size_t)length);
	if (!buffer->failed) {
		vsnprintf(buffer->data + buffer->length, (size_t)length + 1, format, args);
		buffer->length += (size_t)length;
	}
	va_end(args);
}

static void json_string(json_buffer* buffer, const char* value) {
	json_append(buffer, "\"");
	if (value != nullptr) {
		for (const unsigned char* current = (const unsigned char*)value; *current != 0; ++current) {
			switch (*current) {
			case '\"': json_append(buffer, "\\\""); break;
			case '\\': json_append(buffer, "\\\\"); break;
			case '\b': json_append(buffer, "\\b"); break;
			case '\f': json_append(buffer, "\\f"); break;
			case '\n': json_append(buffer, "\\n"); break;
			case '\r': json_append(buffer, "\\r"); break;
			case '\t': json_append(buffer, "\\t"); break;
			default:
				if (*current < 0x20)
					json_format(buffer, "\\u%04x", *current);
				else {
					json_reserve(buffer, 1);
					if (!buffer->failed) {
						buffer->data[buffer->length++] = (char)*current;
						buffer->data[buffer->length] = '\0';
					}
				}
				break;
			}
		}
	}
	json_append(buffer, "\"");
}

#ifdef HL_VULKAN_HAS_SPIRV_REFLECT
static void json_array_traits(json_buffer* buffer, const SpvReflectArrayTraits* array) {
	json_append(buffer, "\"arrayDimensions\":[");
	for (uint32_t index = 0; index < array->dims_count; ++index) {
		if (index != 0)
			json_append(buffer, ",");
		json_format(buffer, "%u", array->dims[index]);
	}
	json_format(buffer, "],\"arrayStride\":%u", array->stride);
}

static void json_numeric_traits(json_buffer* buffer, const SpvReflectNumericTraits* numeric) {
	json_format(
		buffer,
		"\"scalarWidth\":%u,\"signedness\":%u,\"vectorComponents\":%u,\"matrixColumns\":%u,\"matrixRows\":%u,\"matrixStride\":%u",
		numeric->scalar.width,
		numeric->scalar.signedness,
		numeric->vector.component_count,
		numeric->matrix.column_count,
		numeric->matrix.row_count,
		numeric->matrix.stride
	);
}

static void json_block_variable(json_buffer* buffer, const SpvReflectBlockVariable* variable) {
	json_append(buffer, "{\"name\":");
	json_string(buffer, variable->name);
	json_format(
		buffer,
		",\"offset\":%u,\"absoluteOffset\":%u,\"size\":%u,\"paddedSize\":%u,\"decorationFlags\":%u,",
		variable->offset,
		variable->absolute_offset,
		variable->size,
		variable->padded_size,
		variable->decoration_flags
	);
	json_numeric_traits(buffer, &variable->numeric);
	json_append(buffer, ",");
	json_array_traits(buffer, &variable->array);
	json_append(buffer, ",\"typeName\":");
	json_string(buffer, variable->type_description == nullptr ? nullptr : variable->type_description->type_name);
	json_append(buffer, ",\"members\":[");
	for (uint32_t index = 0; index < variable->member_count; ++index) {
		if (index != 0)
			json_append(buffer, ",");
		json_block_variable(buffer, &variable->members[index]);
	}
	json_append(buffer, "]}");
}

static void json_interface_variable(json_buffer* buffer, const SpvReflectInterfaceVariable* variable) {
	json_append(buffer, "{\"name\":");
	json_string(buffer, variable->name);
	json_append(buffer, ",\"semantic\":");
	json_string(buffer, variable->semantic);
	json_format(
		buffer,
		",\"location\":%u,\"component\":%u,\"builtIn\":%d,\"format\":%d,\"decorationFlags\":%u,",
		variable->location,
		variable->component,
		variable->built_in,
		variable->format,
		variable->decoration_flags
	);
	json_numeric_traits(buffer, &variable->numeric);
	json_append(buffer, ",");
	json_array_traits(buffer, &variable->array);
	json_append(buffer, ",\"typeName\":");
	json_string(buffer, variable->type_description == nullptr ? nullptr : variable->type_description->type_name);
	json_append(buffer, "}");
}

static void json_descriptor_binding(json_buffer* buffer, const SpvReflectDescriptorBinding* binding) {
	json_append(buffer, "{\"name\":");
	json_string(buffer, binding->name);
	json_format(
		buffer,
		",\"set\":%u,\"binding\":%u,\"descriptorType\":%d,\"count\":%u,\"resourceType\":%u,\"accessed\":%u,",
		binding->set,
		binding->binding,
		binding->descriptor_type,
		binding->count,
		binding->resource_type,
		binding->accessed
	);
	json_format(
		buffer,
		"\"imageDimension\":%d,\"imageArrayed\":%u,\"imageMultisampled\":%u,\"imageSampled\":%u,\"imageFormat\":%d,",
		binding->image.dim,
		binding->image.arrayed,
		binding->image.ms,
		binding->image.sampled,
		binding->image.image_format
	);
	json_append(buffer, "\"arrayDimensions\":[");
	for (uint32_t index = 0; index < binding->array.dims_count; ++index) {
		if (index != 0)
			json_append(buffer, ",");
		json_format(buffer, "%u", binding->array.dims[index]);
	}
	json_append(buffer, "],\"block\":");
	json_block_variable(buffer, &binding->block);
	json_append(buffer, "}");
}
#endif

HL_PRIM vbyte* HL_NAME(spirv_validate)(vbyte* bytes, int length, int target_vulkan, int* out_status) {
#ifndef HL_VULKAN_HAS_SPIRV_TOOLS
	const char* unavailable = "SPIRV-Tools validation is not available in this Vulkan build";
	*out_status = -1;
	return hl_copy_bytes((const vbyte*)unavailable, (int)strlen(unavailable) + 1);
#else
	if (bytes == nullptr || length <= 0 || (length & 3) != 0) {
		const char* invalid = "SPIR-V bytecode must be non-empty and aligned to 32-bit words";
		*out_status = -1;
		return hl_copy_bytes((const vbyte*)invalid, (int)strlen(invalid) + 1);
	}
	spv_target_env environment;
	switch (target_vulkan) {
	case 10: environment = SPV_ENV_VULKAN_1_0; break;
	case 11: environment = SPV_ENV_VULKAN_1_1; break;
	case 12: environment = SPV_ENV_VULKAN_1_2; break;
	case 13: environment = SPV_ENV_VULKAN_1_3; break;
	default:
		const char* invalid = "Unsupported Vulkan validation target";
		*out_status = -1;
		return hl_copy_bytes((const vbyte*)invalid, (int)strlen(invalid) + 1);
	}
	spv_context context = spvContextCreate(environment);
	spv_const_binary_t binary = { (const uint32_t*)bytes, (size_t)length / sizeof(uint32_t) };
	spv_diagnostic diagnostic = nullptr;
	*out_status = (int)spvValidate(context, &binary, &diagnostic);
	const char* message = diagnostic == nullptr || diagnostic->error == nullptr ? "" : diagnostic->error;
	vbyte* result = hl_copy_bytes((const vbyte*)message, (int)strlen(message) + 1);
	spvDiagnosticDestroy(diagnostic);
	spvContextDestroy(context);
	return result;
#endif
}

HL_PRIM vbyte* HL_NAME(spirv_reflect)(vbyte* bytes, int length, int* out_status) {
#ifndef HL_VULKAN_HAS_SPIRV_REFLECT
	const char* unavailable = "SPIRV-Reflect is not available in this Vulkan build";
	*out_status = -1;
	return hl_copy_bytes((const vbyte*)unavailable, (int)strlen(unavailable) + 1);
#else
	if (bytes == nullptr || length <= 0 || (length & 3) != 0) {
		const char* invalid = "SPIR-V bytecode must be non-empty and aligned to 32-bit words";
		*out_status = -1;
		return hl_copy_bytes((const vbyte*)invalid, (int)strlen(invalid) + 1);
	}
	SpvReflectShaderModule module;
	const SpvReflectResult create_result = spvReflectCreateShaderModule((size_t)length, bytes, &module);
	if (create_result != SPV_REFLECT_RESULT_SUCCESS) {
		char message[96];
		snprintf(message, sizeof(message), "spvReflectCreateShaderModule failed (%d)", create_result);
		*out_status = (int)create_result;
		return hl_copy_bytes((const vbyte*)message, (int)strlen(message) + 1);
	}

	json_buffer output = { 0 };
	json_append(&output, "{\"entryPoint\":");
	json_string(&output, module.entry_point_name);
	json_format(&output, ",\"shaderStage\":%u", module.shader_stage);
	const SpvReflectEntryPoint* entry = spvReflectGetEntryPoint(&module, module.entry_point_name);
	if (entry == nullptr)
		json_append(&output, ",\"localSize\":{\"x\":0,\"y\":0,\"z\":0}");
	else
		json_format(&output, ",\"localSize\":{\"x\":%u,\"y\":%u,\"z\":%u}", entry->local_size.x, entry->local_size.y, entry->local_size.z);

	json_append(&output, ",\"descriptorSets\":[");
	for (uint32_t set_index = 0; set_index < module.descriptor_set_count; ++set_index) {
		const SpvReflectDescriptorSet* set = &module.descriptor_sets[set_index];
		if (set_index != 0)
			json_append(&output, ",");
		json_format(&output, "{\"set\":%u,\"bindings\":[", set->set);
		for (uint32_t binding_index = 0; binding_index < set->binding_count; ++binding_index) {
			if (binding_index != 0)
				json_append(&output, ",");
			json_descriptor_binding(&output, set->bindings[binding_index]);
		}
		json_append(&output, "]}");
	}

	json_append(&output, "],\"pushConstantBlocks\":[");
	for (uint32_t index = 0; index < module.push_constant_block_count; ++index) {
		if (index != 0)
			json_append(&output, ",");
		json_block_variable(&output, &module.push_constant_blocks[index]);
	}

	json_append(&output, "],\"inputs\":[");
	for (uint32_t index = 0; index < module.input_variable_count; ++index) {
		if (index != 0)
			json_append(&output, ",");
		json_interface_variable(&output, module.input_variables[index]);
	}

	json_append(&output, "],\"outputs\":[");
	for (uint32_t index = 0; index < module.output_variable_count; ++index) {
		if (index != 0)
			json_append(&output, ",");
		json_interface_variable(&output, module.output_variables[index]);
	}
	json_append(&output, "]}");

	spvReflectDestroyShaderModule(&module);
	if (output.failed) {
		free(output.data);
		const char* failure = "Failed to allocate SPIR-V reflection result";
		*out_status = -1;
		return hl_copy_bytes((const vbyte*)failure, (int)strlen(failure) + 1);
	}
	*out_status = 0;
	vbyte* result = hl_copy_bytes((const vbyte*)output.data, (int)output.length + 1);
	free(output.data);
	return result;
#endif
}

DEFINE_PRIM(_BYTES, spirv_validate, _BYTES _I32 _I32 _REF(_I32));
DEFINE_PRIM(_BYTES, spirv_reflect, _BYTES _I32 _REF(_I32));
