package limen.graphics.vulkan;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.VkContext;
import limen.graphics.vulkan.device.Capabilities;
import limen.platform.window.Window;

class Runtime {
	public static var diagnostics(get, never):String;
	public static var loaderApiVersion(get, never):Int;
	public static var instanceApiVersion(get, never):Int;
	public static var validationEnabled(get, never):Bool;

	public static function createSurface(window:Window, enableValidation:Bool = false):Surface {
		return Surface.create(window, enableValidation);
	}

	public static function createContext(surface:Surface, queueFamily:hl.Ref<Int>, requiredCapabilities:Int = Capabilities.FOUNDATION):VkContext {
		final context = VulkanBindings.initContext(surface.nativeHandle, queueFamily, requiredCapabilities);
		if (context == null)
			throw error("Failed to create Vulkan context");
		return context;
	}

	public static function getCapabilities(context:VkContext):Capabilities {
		return new Capabilities(context);
	}

	public static function destroyContext(context:VkContext) {
		if (!context.destroyContext())
			throw error("Failed to destroy Vulkan context");
	}

	public static function error(prefix:String):String {
		final detail = @:privateAccess String.fromUTF8(VulkanBindings.lastError());
		return detail.length == 0 ? prefix : '$prefix: $detail';
	}

	static function get_diagnostics():String {
		return @:privateAccess String.fromUTF8(VulkanBindings.instanceReport());
	}

	static function get_loaderApiVersion():Int {
		return VulkanBindings.loaderApiVersion();
	}

	static function get_instanceApiVersion():Int {
		return VulkanBindings.instanceApiVersion();
	}

	static function get_validationEnabled():Bool {
		return VulkanBindings.validationEnabled();
	}
}
