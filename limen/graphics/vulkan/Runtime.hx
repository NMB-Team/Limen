package limen.graphics.vulkan;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.VkContext;
import limen.platform.Window;

class Runtime {
	public static function createSurface(window:Window, enableValidation:Bool = false):Surface {
		return Surface.create(window, enableValidation);
	}

	public static function createContext(surface:Surface, queueFamily:hl.Ref<Int>):VkContext {
		final context = VulkanBindings.initContext(surface.nativeHandle, queueFamily);
		if (context == null)
			throw "Failed to create Vulkan context";
		return context;
	}
}
