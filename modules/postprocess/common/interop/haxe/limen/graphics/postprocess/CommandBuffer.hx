package limen.graphics.postprocess;

abstract CommandBuffer(hl.Abstract<"postprocess_command_buffer">) {
	@:from public static inline function fromD3D12(value:limen.graphics.renderer.d3d12.command.Commands.CommandList):CommandBuffer
		return cast value;
	@:from public static inline function fromVulkan(value:limen.graphics.renderer.vulkan.command.Commands.VkCommandBuffer):CommandBuffer
		return cast value;
}
