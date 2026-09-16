package limen.graphics.vulkan.shader;

import limen.graphics.vulkan.Runtime;
import limen.graphics.vulkan.internal.VulkanBindings.VkContext;
import limen.graphics.vulkan.shader.SpirvReflection.SpirvValidator;

abstract VkShaderModule(hl.Abstract<"vk_shader_module">) {}

class ShaderModule {
	public var handle(default, null):VkShaderModule;
	public final debugName:String;

	final context:VkContext;

	public function new(context:VkContext, spirv:haxe.io.Bytes, debugName:String) {
		this.context = context;
		this.debugName = debugName;
		final validation = SpirvValidator.validate(spirv);
		if (!validation.valid)
			throw Runtime.error('Refusing to create Vulkan shader module "$debugName" from invalid SPIR-V: ${validation.diagnostics}');
		handle = context.createShaderModule(@:privateAccess spirv.b, spirv.length);
		if (handle == null)
			throw Runtime.error('Failed to create Vulkan shader module "$debugName"');
		if (debugName.length > 0)
			context.setShaderModuleName(handle, @:privateAccess debugName.toUtf8());
	}

	public function dispose() {
		if (handle == null)
			return;
		context.destroyShaderModule(handle);
		handle = null;
	}
}

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
