package limen.graphics.postprocess;

abstract NativeHandle(hl.Abstract<"postprocess_handle">) {
	@:from public static inline function fromD3D12Device(value:limen.graphics.internal.D3D12Handles.Device):NativeHandle
		return cast value;
	@:from public static inline function fromD3D12Resource(value:limen.graphics.internal.D3D12Handles.Dx12Resource):NativeHandle
		return cast value;
	@:from public static inline function fromD3D11Resource(value:limen.graphics.internal.D3D11Resources.Resource):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanImage(value:limen.graphics.internal.VulkanHandles.VkImage):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanMemory(value:limen.graphics.internal.VulkanHandles.VkDeviceMemory):NativeHandle
		return cast value;
	@:from public static inline function fromVulkanView(value:limen.graphics.internal.VulkanHandles.VkImageView):NativeHandle
		return cast value;
}
