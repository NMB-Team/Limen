package limen.vulkan.internal;

import limen.vulkan.Context;
import limen.vulkan.Types.ArrayStruct;
import limen.vulkan.VulkanRequirements;

enum abstract ShaderKind(Int) {
	final Vertex = 0;
	final Fragment = 1;
	final Compute = 2;
	final Geometry = 3;
	final TessellationControl = 4;
	final TessellationEvaluation = 5;
}

@:noDoc
@:noCompletion
abstract VkShaderCompiler(hl.Abstract<"vk_shader_compiler">) {}

abstract VkSurface(hl.Bytes) {}

@:noDoc
@:noCompletion
@:hlNative("limen", "vulkan_vk_")
class VulkanBindings {
	public static var ENABLE_VALIDATION = false;

	@:hlNative("limen", "vulkan_vk_init")
	public static function initialize(enableValidation:Bool, ?requirements:VulkanRequirements):Bool {
		return false;
	}

	public static function shutdown() {}

	public static function destroySurface(surface:VkSurface) {}

	public static function lastError():hl.Bytes {
		return null;
	}

	public static function instanceReport():hl.Bytes {
		return null;
	}

	public static function loaderApiVersion():Int {
		return 0;
	}

	public static function instanceApiVersion():Int {
		return 0;
	}

	public static function validationEnabled():Bool {
		return false;
	}

	@:hlNative("limen", "vulkan_win_get_vulkan")
	public static function createWindowSurface(window:hl.Abstract<"limen_window">):VkSurface {
		return null;
	}

	public static function initContext(surface:VkSurface, queueFamily:hl.Ref<Int>, requiredCapabilities:Int, ?requirements:VulkanRequirements):Context {
		return null;
	}

	@:hlNative("limen", "vulkan_shader_compiler_create")
	public static function shaderCompilerCreate():VkShaderCompiler {
		return null;
	}

	@:hlNative("limen", "vulkan_shader_compiler_destroy")
	public static function shaderCompilerDestroy(compiler:VkShaderCompiler):Void {}

	@:hlNative("limen", "vulkan_shader_compile")
	public static function shaderCompile(compiler:VkShaderCompiler, source:hl.Bytes, sourceName:hl.Bytes, entryPoint:hl.Bytes, kind:ShaderKind, targetVulkan:Int, targetSpirv:Int, optimization:Int, debugInfo:Bool, warningsAsErrors:Bool,
			defines:hl.NativeArray<hl.Bytes>, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	@:hlNative("limen", "vulkan_spirv_validate")
	public static function spirvValidate(bytes:hl.Bytes, length:Int, targetVulkan:Int, outStatus:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	@:hlNative("limen", "vulkan_spirv_reflect")
	public static function spirvReflect(bytes:hl.Bytes, length:Int, outStatus:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public static function makeRef<T>(arr:T):ArrayStruct<T> {
		return null;
	}

	public static function makeArray<T>(arr:hl.NativeArray<T>):ArrayStruct<T> {
		return null;
	}
}
