package limen.graphics.postprocess;

abstract NativeHandle(hl.Abstract<"postprocess_handle">) {
	@:from public static inline function fromD3D12Device(value:limen.graphics.renderer.d3d12.internal.D3D12Bindings.Device):NativeHandle
		return cast value;
	@:from public static inline function fromD3D12Resource(value:limen.graphics.renderer.d3d12.resource.Resources.Dx12Resource):NativeHandle
		return cast value;
	@:from public static inline function fromD3D11Resource(value:limen.graphics.renderer.d3d11.resource.Resources.Resource):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanImage(value:limen.graphics.renderer.vulkan.memory.Memory.VkImage):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanMemory(value:limen.graphics.renderer.vulkan.memory.Memory.VkDeviceMemory):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanView(value:limen.graphics.renderer.vulkan.memory.Memory.VkImageView):NativeHandle
		return cast value;
}
