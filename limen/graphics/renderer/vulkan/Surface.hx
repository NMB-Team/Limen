package limen.graphics.renderer.vulkan;

import limen.graphics.renderer.vulkan.internal.VulkanBindings;
import limen.graphics.renderer.vulkan.internal.VulkanBindings.VkSurface;
import limen.platform.internal.SDLBindings;
import limen.platform.window.Window;

class Surface {
	public var nativeHandle(default, null):VkSurface;
	public var disposed(get, never):Bool;

	public static function create(window:Window, enableValidation:Bool = false):Surface {
		if (!VulkanBindings.initialize(enableValidation))
			throw Vulkan.error("Failed to initialize Vulkan");
		final handle = VulkanBindings.createWindowSurface(window.nativeHandle);
		if (handle == null) {
			final detail = @:privateAccess String.fromUTF8(SDLBindings.getError());
			VulkanBindings.shutdown();
			throw detail.length == 0 ? "Failed to create Vulkan surface" : 'Failed to create Vulkan surface: $detail';
		}
		return new Surface(handle);
	}

	private function new(handle:VkSurface) {
		nativeHandle = handle;
	}

	public function destroy() {
		if (nativeHandle == null)
			return;
		VulkanBindings.destroySurface(nativeHandle);
		nativeHandle = null;
		VulkanBindings.shutdown();
	}

	@:noCompletion
	private function get_disposed():Bool {
		return nativeHandle == null;
	}
}
