package limen.graphics.vulkan.internal;

import limen.graphics.vulkan.command.Commands.VkCommandBuffer;
import limen.graphics.vulkan.command.Commands.VkCommandBufferAllocateInfo;
import limen.graphics.vulkan.command.Commands.VkCommandPool;
import limen.graphics.vulkan.command.Commands.VkCommandPoolCreateInfo;
import limen.graphics.vulkan.command.Commands.VkFence;
import limen.graphics.vulkan.command.Commands.VkFenceCreateInfo;
import limen.graphics.vulkan.command.Commands.VkSemaphore;
import limen.graphics.vulkan.command.Commands.VkSemaphoreCreateInfo;
import limen.graphics.vulkan.command.Commands.VkSubmitInfo;
import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.descriptor.Descriptors.VkCopyDescriptorSet;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorPool;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorPoolCreateInfo;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSet;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSetAllocateInfo;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSetLayout;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSetLayoutCreateInfo;
import limen.graphics.vulkan.descriptor.Descriptors.VkWriteDescriptorSet;
import limen.graphics.vulkan.memory.Memory.VkBuffer;
import limen.graphics.vulkan.memory.Memory.VkBufferCreateInfo;
import limen.graphics.vulkan.memory.Memory.VkDeviceMemory;
import limen.graphics.vulkan.memory.Memory.VkImage;
import limen.graphics.vulkan.memory.Memory.VkImageCreateInfo;
import limen.graphics.vulkan.memory.Memory.VkImageLayout;
import limen.graphics.vulkan.memory.Memory.VkImageView;
import limen.graphics.vulkan.memory.Memory.VkImageViewCreateInfo;
import limen.graphics.vulkan.memory.Memory.VkMemoryAllocateInfo;
import limen.graphics.vulkan.memory.Memory.VkMemoryPropertyFlag;
import limen.graphics.vulkan.memory.Memory.VkMemoryRequirements;
import limen.graphics.vulkan.format.Formats.VkFormat;
import limen.graphics.vulkan.format.Formats.VkFormatProperties;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipelineCreateInfo;
import limen.graphics.vulkan.device.DeviceLimits.VkPhysicalDeviceLimits;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayout;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayoutCreateInfo;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderModule;
import limen.graphics.vulkan.render.RenderPass.VkFramebuffer;
import limen.graphics.vulkan.render.RenderPass.VkFramebufferCreateInfo;
import limen.graphics.vulkan.render.RenderPass.VkRenderPass;
import limen.graphics.vulkan.render.RenderPass.VkRenderPassCreateInfo;
import limen.graphics.vulkan.sampler.Samplers.VkSampler;
import limen.graphics.vulkan.sampler.Samplers.VkSamplerCreateInfo;

import haxe.Int64;

enum abstract ShaderKind(Int) {
	final Vertex = 0;
	final Fragment = 1;
}

@:hlNative("limen", "vulkan_vk_")
abstract VkContext(hl.Abstract<"vk_context">) {
	public function getLimits():VkPhysicalDeviceLimits {
		return null;
	}

	public function getDeviceName() {
		return @:privateAccess String.fromUTF8(get_device_name());
	}

	public function getPdeviceFormatProps(format:VkFormat, props:VkFormatProperties) {}

	function get_device_name():hl.Bytes {
		return null;
	}

	public function initSwapchain(width:Int, height:Int, vsync:Bool, outImages:hl.NativeArray<VkImage>, outFormat:hl.Ref<VkFormat>):Bool {
		return false;
	}

	public function createCommandPool(inf:VkCommandPoolCreateInfo):VkCommandPool {
		return null;
	}

	public function allocateCommandBuffers(inf:VkCommandBufferAllocateInfo, buffers:hl.NativeArray<VkCommandBuffer>):Bool {
		return false;
	}

	public function getNextImageIndex(sem:VkSemaphore):Int {
		return 0;
	}

	public function createSampler(inf:VkSamplerCreateInfo):VkSampler {
		return null;
	}

	public function createSemaphore(inf:VkSemaphoreCreateInfo):VkSemaphore {
		return null;
	}

	public function waitForFence(fence:VkFence, timeout:Float):Bool {
		return false;
	}

	public function resetFence(fence:VkFence) {}

	public function createFence(inf:VkFenceCreateInfo):VkFence {
		return null;
	}

	public function createShaderModule(source:hl.Bytes, len:Int):VkShaderModule {
		return null;
	}

	public function createGraphicsPipeline(inf:VkGraphicsPipelineCreateInfo):VkGraphicsPipeline {
		return null;
	}

	public function createPipelineLayout(inf:VkPipelineLayoutCreateInfo):VkPipelineLayout {
		return null;
	}

	public function createRenderPass(inf:VkRenderPassCreateInfo):VkRenderPass {
		return null;
	}

	public function createDescriptorSetLayout(inf:VkDescriptorSetLayoutCreateInfo):VkDescriptorSetLayout {
		return null;
	}

	public function createDescriptorPool(inf:VkDescriptorPoolCreateInfo):VkDescriptorPool {
		return null;
	}

	public function allocateDescriptorSets(inf:VkDescriptorSetAllocateInfo, sets:hl.NativeArray<VkDescriptorSet>):Bool {
		return false;
	}

	public function updateDescriptorSets(writeCount:Int, write:ArrayStruct<VkWriteDescriptorSet>, copyCount:Int, copy:ArrayStruct<VkCopyDescriptorSet>) {}

	public function updateDescriptorImageSampler(set:VkDescriptorSet, binding:Int, view:VkImageView, sampler:VkSampler, layout:VkImageLayout) {}

	public function createFramebuffer(inf:VkFramebufferCreateInfo):VkFramebuffer {
		return null;
	}

	public function createImageView(inf:VkImageViewCreateInfo):VkImageView {
		return null;
	}

	public function createBuffer(inf:VkBufferCreateInfo):VkBuffer {
		return null;
	}

	public function getBufferMemoryRequirements(b:VkBuffer, inf:VkMemoryRequirements) {}

	public function allocateMemory(inf:VkMemoryAllocateInfo):VkDeviceMemory {
		return null;
	}

	public function bindBufferMemory(b:VkBuffer, mem:VkDeviceMemory, memOffset:Int) {
		return false;
	}

	public function createImage(inf:VkImageCreateInfo):VkImage {
		return null;
	}

	public function getImageMemoryRequirements(b:VkImage, inf:VkMemoryRequirements) {}

	public function bindImageMemory(b:VkImage, mem:VkDeviceMemory, memOffset:Int) {
		return false;
	}

	public function findMemoryType(allowed:Int, required:haxe.EnumFlags<VkMemoryPropertyFlag>):Int {
		return 0;
	}

	public function mapMemory(mem:VkDeviceMemory, offset:Int, size:Int, flags:Int):hl.Bytes {
		return null;
	}

	public function unmapMemory(mem:VkDeviceMemory) {}

	public function queueSubmit(submit:VkSubmitInfo, fence:VkFence) {}

	public function queueWaitIdle() {}

	public function present(sem:VkSemaphore, currentImage:Int) {}

	public function destroyImage(img:VkImage) {}

	public function destroyImageView(view:VkImageView) {}

	public function destroyFramebuffer(buf:VkFramebuffer) {}

	public function destroyRenderPass(pass:VkRenderPass) {}

	public function freeCommandBuffers(pool:VkCommandPool, arr:hl.NativeArray<VkCommandBuffer>) {}

	public function destroyCommandPool(pool:VkCommandPool) {}

	public function destroyBuffer(buf:VkBuffer) {}

	public function destroyFence(fence:VkFence) {}

	public function destroySemaphore(sem:VkSemaphore) {}

	public function freeMemory(mem:VkDeviceMemory) {}

	public function destroyDescriptorPool(pool:VkDescriptorPool) {}

	public function destroySampler(sampler:VkSampler) {}
}

abstract VkSurface(hl.Bytes) {}

@:hlNative("limen", "vulkan_vk_")
class VulkanBindings {
	public static var ENABLE_VALIDATION = false;

	@:hlNative("limen", "vulkan_vk_init")
	public static function initialize(enableValidation:Bool):Bool {
		return false;
	}

	@:hlNative("limen", "vulkan_win_get_vulkan")
	public static function createWindowSurface(window:hl.Abstract<"limen_window">):VkSurface {
		return null;
	}

	public static function initContext(surface:VkSurface, queueFamily:hl.Ref<Int>):VkContext {
		return null;
	}

	public static function compileShader(source:String, fileName:String, mainFunction:String, kind:ShaderKind) {
		var outSize = -1;
		var bytes = @:privateAccess compile_shader(source.toUtf8(), fileName.toUtf8(), mainFunction.toUtf8(), kind, outSize);
		if (outSize < 0) {
			var error = @:privateAccess String.fromUTF8(bytes);
			var lines = source.split("\n");
			throw error + "\n\nin\n\n" + [for (i => l in lines) StringTools.rpad((i + 1) + ":", " ", 8) + l].join("\n");
		}
		return @:privateAccess new haxe.io.Bytes(bytes, outSize);
	}

	@:hlNative("limen", "vulkan_compile_shader")
	static function compile_shader(source:hl.Bytes, shaderFile:hl.Bytes, mainFunction:hl.Bytes, kind:ShaderKind, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public static function makeRef<T>(arr:T):ArrayStruct<T> {
		return null;
	}

	public static function makeArray<T>(arr:hl.NativeArray<T>):ArrayStruct<T> {
		return null;
	}
}
