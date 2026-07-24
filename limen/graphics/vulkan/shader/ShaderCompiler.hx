package limen.graphics.vulkan.shader;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.ShaderKind;

class ShaderCompiler {
	public static inline function compile(source:String, fileName:String, entryPoint:String, kind:ShaderKind):haxe.io.Bytes {
		return VulkanBindings.compileShader(source, fileName, entryPoint, kind);
	}
}
