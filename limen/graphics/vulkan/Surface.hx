package limen.graphics.vulkan;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.VkSurface;
import limen.platform.internal.SdlBindings;
import limen.platform.window.Window;

class Surface {
	public var nativeHandle(default, null):VkSurface;
	public var disposed(get, never):Bool;

	public static function create(window:Window, enableValidation:Bool = false):Surface {
		if (!VulkanBindings.initialize(enableValidation))
			throw Runtime.error("Failed to initialize Vulkan");
		final handle = VulkanBindings.createWindowSurface(window.nativeHandle);
		if (handle == null) {
			final detail = @:privateAccess String.fromUTF8(SdlBindings.getError());
			VulkanBindings.shutdown();
			throw detail.length == 0 ? "Failed to create Vulkan surface" : 'Failed to create Vulkan surface: $detail';
		}
		return new Surface(handle);
	}

	function new(handle:VkSurface) {
		nativeHandle = handle;
	}

	public function destroy() {
		if (nativeHandle == null)
			return;
		VulkanBindings.destroySurface(nativeHandle);
		nativeHandle = null;
		VulkanBindings.shutdown();
	}

	function get_disposed():Bool {
		return nativeHandle == null;
	}
}
