package limen.graphics.vulkan;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.VkSurface;
import limen.platform.window.Window;

class Surface {
	public var nativeHandle(default, null):VkSurface;

	public static function create(window:Window, enableValidation:Bool = false):Surface {
		if (!VulkanBindings.initialize(enableValidation))
			throw "Failed to initialize Vulkan";
		final handle = VulkanBindings.createWindowSurface(window.nativeHandle);
		if (handle == null)
			throw "Failed to create Vulkan surface";
		return new Surface(handle);
	}

	function new(handle:VkSurface) {
		nativeHandle = handle;
	}
}
