package limen.graphics.vulkan.shader;

abstract VkShaderModule(hl.Abstract<"vk_shader_module">) {}

enum VkShaderStageFlag {
	VERTEX;
	TESSELLATION_CONTROL;
	TESSELLATION_EVALUATION;
	GEOMETRY;
	FRAGMENT;
	COMPUTE;
	TASK_NV;
	MESH_NV;
	RAYGEN_KHR;
	ANY_HIT_KHR;
	CLOSEST_HIT_KHR;
	MISS_KHR;
	INTERSECTION_KHR;
	CALLABLE_KHR;
	// ALL_GRAPHICS = 0x0000001F,
	// ALL = 0x7FFFFFFF,
}

abstract VkSpecializationInfo(hl.Bytes) {}
