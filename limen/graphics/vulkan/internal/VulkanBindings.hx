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
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorType;
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
import limen.graphics.vulkan.memory.Memory.VkMemoryRequirementsInfo;
import limen.graphics.vulkan.memory.Memory.VkMemoryHeapBudgetInfo;
import limen.graphics.vulkan.format.Formats.VkFormat;
import limen.graphics.vulkan.format.Formats.VkFormatProperties;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipelineCreateInfo;
import limen.graphics.vulkan.pipeline.Pipeline.VkComputePipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkComputePipelineCreateInfo;
import limen.graphics.vulkan.device.DeviceLimits.VkPhysicalDeviceLimits;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayout;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayoutCreateInfo;
import limen.graphics.vulkan.query.Queries.VkQueryPool;
import limen.graphics.vulkan.query.Queries.VkQueryPoolCreateInfo;
import limen.graphics.vulkan.query.Queries.VkQueryResultFlag;
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
	final Compute = 2;
	final Geometry = 3;
	final TessellationControl = 4;
	final TessellationEvaluation = 5;
}

abstract VkShaderCompiler(hl.Abstract<"vk_shader_compiler">) {}

enum abstract VkWsiStatus(Int) from Int to Int {
	final Error = -1;
	final Success = 0;
	final Suboptimal = 1;
	final OutOfDate = 2;
	final SurfaceLost = 3;
	final DeviceLost = 4;
	final Deferred = 5;
}

@:struct class VkSwapchainInfo {
	public var width:Int;
	public var height:Int;
	public var vsync:Int;
	public var format:VkFormat;
	public var actualWidth:Int;
	public var actualHeight:Int;
	public var transferSource:Int;

	public function new(width:Int, height:Int, vsync:Bool) {
		this.width = width;
		this.height = height;
		this.vsync = vsync ? 1 : 0;
	}
}

@:hlNative("limen", "vulkan_vk_")
abstract VkContext(hl.Abstract<"vk_context">) {
	public function destroyContext():Bool {
		return false;
	}

	public function getContextReport():hl.Bytes {
		return null;
	}

	public function getCapabilityFlags():Int {
		return 0;
	}

	public function getMaxUpdateAfterBindDescriptors():Int
		return 0;

	public function getMaxPerStageUpdateAfterBindResources():Int
		return 0;

	public function getMaxPerStageUpdateAfterBindSamplers():Int
		return 0;

	public function getMaxPerStageUpdateAfterBindSampledImages():Int
		return 0;

	public function getMaxPerStageUpdateAfterBindStorageBuffers():Int
		return 0;

	public function getMaxUpdateAfterBindSamplers():Int
		return 0;

	public function getMaxUpdateAfterBindSampledImages():Int
		return 0;

	public function getMaxUpdateAfterBindStorageBuffers():Int
		return 0;

	public function getDeviceApiVersion():Int {
		return 0;
	}

	public function getVendorId():Int {
		return 0;
	}

	public function getDeviceId():Int {
		return 0;
	}

	public function getDriverVersion():Int {
		return 0;
	}

	public function getGraphicsQueueFamily():Int {
		return 0;
	}

	public function getPresentQueueFamily():Int {
		return 0;
	}

	public function getComputeQueueFamily():Int {
		return 0;
	}

	public function getTransferQueueFamily():Int {
		return 0;
	}

	public function getGraphicsTimestampValidBits():Int {
		return 0;
	}

	public function getTimestampPeriod():Float {
		return 0;
	}

	public function getLimits():VkPhysicalDeviceLimits {
		return null;
	}

	public function getMemoryTypeCount():Int {
		return 0;
	}

	public function getMemoryTypeProperties(index:Int):Int {
		return 0;
	}

	public function getMemoryTypeHeapIndex(index:Int):Int {
		return 0;
	}

	public function getMemoryHeapCount():Int {
		return 0;
	}

	public function getMemoryHeapSize(index:Int):hl.I64 {
		return 0;
	}

	public function getMemoryHeapFlags(index:Int):Int {
		return 0;
	}

	public function hasMemoryBudget():Bool {
		return false;
	}

	public function getMemoryHeapBudget(index:Int, info:VkMemoryHeapBudgetInfo):Bool {
		return false;
	}

	public function setBufferName(buffer:VkBuffer, name:hl.Bytes):Bool {
		return false;
	}

	public function setImageName(image:VkImage, name:hl.Bytes):Bool {
		return false;
	}

	public function setImageViewName(view:VkImageView, name:hl.Bytes):Bool {
		return false;
	}

	public function setMemoryName(memory:VkDeviceMemory, name:hl.Bytes):Bool {
		return false;
	}

	public function getDeviceName() {
		return @:privateAccess String.fromUTF8(get_device_name());
	}

	public function getPdeviceFormatProps(format:VkFormat, props:VkFormatProperties) {}

	function get_device_name():hl.Bytes {
		return null;
	}

	public function initSwapchain(info:VkSwapchainInfo, outImages:hl.NativeArray<VkImage>):VkWsiStatus {
		return 0;
	}

	public function createCommandPool(inf:VkCommandPoolCreateInfo):VkCommandPool {
		return null;
	}

	public function createQueryPool(inf:VkQueryPoolCreateInfo):VkQueryPool {
		return null;
	}

	public function getQueryPoolResults(pool:VkQueryPool, firstQuery:Int, queryCount:Int, dataSize:Int, data:hl.Bytes, stride:hl.I64, flags:haxe.EnumFlags<VkQueryResultFlag>):Int {
		return 0;
	}

	public function allocateCommandBuffers(inf:VkCommandBufferAllocateInfo, buffers:hl.NativeArray<VkCommandBuffer>):Int {
		return 0;
	}

	public function acquireNextImage(sem:VkSemaphore, outImage:hl.Ref<Int>):VkWsiStatus {
		return 0;
	}

	public function createSampler(inf:VkSamplerCreateInfo):VkSampler {
		return null;
	}

	public function createSemaphore(inf:VkSemaphoreCreateInfo):VkSemaphore {
		return null;
	}

	public function waitForFence(fence:VkFence, timeout:Float):Int {
		return 0;
	}

	public function resetFence(fence:VkFence):Int {
		return 0;
	}

	public function getFenceStatus(fence:VkFence):Int {
		return 0;
	}

	public function createFence(inf:VkFenceCreateInfo):VkFence {
		return null;
	}

	public function createShaderModule(source:hl.Bytes, len:Int):VkShaderModule {
		return null;
	}

	public function setShaderModuleName(module:VkShaderModule, name:hl.Bytes):Bool {
		return false;
	}

	public function createGraphicsPipeline(inf:VkGraphicsPipelineCreateInfo):VkGraphicsPipeline {
		return null;
	}

	public function createComputePipeline(inf:VkComputePipelineCreateInfo):VkComputePipeline {
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

	public function allocateDescriptorSets(inf:VkDescriptorSetAllocateInfo, sets:hl.NativeArray<VkDescriptorSet>):Int {
		return 0;
	}

	public function resetDescriptorPool(pool:VkDescriptorPool):Int {
		return 0;
	}

	public function updateDescriptorSets(writeCount:Int, write:ArrayStruct<VkWriteDescriptorSet>, copyCount:Int, copy:ArrayStruct<VkCopyDescriptorSet>) {}

	public function updateDescriptorImageSampler(set:VkDescriptorSet, binding:Int, arrayElement:Int, view:VkImageView, sampler:VkSampler, layout:VkImageLayout) {}

	public function updateDescriptorSampledImage(set:VkDescriptorSet, binding:Int, arrayElement:Int, view:VkImageView, layout:VkImageLayout) {}

	public function updateDescriptorSampler(set:VkDescriptorSet, binding:Int, arrayElement:Int, sampler:VkSampler) {}

	public function updateDescriptorSampledImageRange(set:VkDescriptorSet, binding:Int, firstElement:Int, views:hl.NativeArray<VkImageView>, layout:VkImageLayout) {}

	public function updateDescriptorSamplerRange(set:VkDescriptorSet, binding:Int, firstElement:Int, samplers:hl.NativeArray<VkSampler>) {}

	public function updateDescriptorStorageImage(set:VkDescriptorSet, binding:Int, arrayElement:Int, view:VkImageView, layout:VkImageLayout) {}

	public function updateDescriptorBuffer(set:VkDescriptorSet, binding:Int, descriptorType:VkDescriptorType, buffer:VkBuffer, offset:hl.I64, range:hl.I64) {}

	public function updateDescriptorBufferElement(set:VkDescriptorSet, binding:Int, arrayElement:Int, descriptorType:VkDescriptorType, buffer:VkBuffer, offset:hl.I64, range:hl.I64) {}

	public function updateDescriptorBufferRange(set:VkDescriptorSet, binding:Int, firstElement:Int, descriptorType:VkDescriptorType, buffers:hl.NativeArray<VkBuffer>, ranges:hl.NativeArray<hl.I64>) {}

	public function createFramebuffer(inf:VkFramebufferCreateInfo):VkFramebuffer {
		return null;
	}

	public function createImageView(inf:VkImageViewCreateInfo):VkImageView {
		return null;
	}

	public function createBuffer(inf:VkBufferCreateInfo):VkBuffer {
		return null;
	}

	public function createBuffer64(size:hl.I64, usage:haxe.EnumFlags<limen.graphics.vulkan.memory.Memory.VkBufferUsageFlag>):VkBuffer {
		return null;
	}

	public function getBufferMemoryRequirements(b:VkBuffer, inf:VkMemoryRequirements) {}

	public function getBufferMemoryRequirements2(b:VkBuffer, inf:VkMemoryRequirementsInfo) {}

	public function allocateMemory(inf:VkMemoryAllocateInfo):VkDeviceMemory {
		return null;
	}

	public function allocateMemory64(size:hl.I64, memoryTypeIndex:Int, dedicatedBuffer:VkBuffer, dedicatedImage:VkImage):VkDeviceMemory {
		return null;
	}

	public function bindBufferMemory(b:VkBuffer, mem:VkDeviceMemory, memOffset:Int) {
		return false;
	}

	public function bindBufferMemory64(b:VkBuffer, mem:VkDeviceMemory, memOffset:hl.I64) {
		return false;
	}

	public function createImage(inf:VkImageCreateInfo):VkImage {
		return null;
	}

	public function getImageMemoryRequirements(b:VkImage, inf:VkMemoryRequirements) {}

	public function getImageMemoryRequirements2(b:VkImage, inf:VkMemoryRequirementsInfo) {}

	public function bindImageMemory(b:VkImage, mem:VkDeviceMemory, memOffset:Int) {
		return false;
	}

	public function bindImageMemory64(b:VkImage, mem:VkDeviceMemory, memOffset:hl.I64) {
		return false;
	}

	public function findMemoryType(allowed:Int, required:haxe.EnumFlags<VkMemoryPropertyFlag>):Int {
		return 0;
	}

	public function mapMemory(mem:VkDeviceMemory, offset:Int, size:Int, flags:Int):hl.Bytes {
		return null;
	}

	public function mapMemory64(mem:VkDeviceMemory, offset:hl.I64, size:hl.I64, flags:Int):hl.Bytes {
		return null;
	}

	public function flushMappedMemory(mem:VkDeviceMemory, offset:hl.I64, size:hl.I64):Int {
		return 0;
	}

	public function invalidateMappedMemory(mem:VkDeviceMemory, offset:hl.I64, size:hl.I64):Int {
		return 0;
	}

	public function unmapMemory(mem:VkDeviceMemory) {}

	public function queueSubmit(submit:VkSubmitInfo, fence:VkFence):Int {
		return 0;
	}

	public function submitCommand(command:VkCommandBuffer, fence:VkFence):Int {
		return 0;
	}

	public function queueWaitIdle():Int {
		return 0;
	}

	public function waitIdle():Int {
		return 0;
	}

	public function present(sem:VkSemaphore, currentImage:Int):VkWsiStatus {
		return 0;
	}

	public function submitFrame(command:VkCommandBuffer, acquired:VkSemaphore, finished:VkSemaphore, fence:VkFence):Int {
		return 0;
	}

	public function destroyImage(img:VkImage) {}

	public function destroyImageView(view:VkImageView) {}

	public function destroyFramebuffer(buf:VkFramebuffer) {}

	public function destroyRenderPass(pass:VkRenderPass) {}

	public function freeCommandBuffers(pool:VkCommandPool, arr:hl.NativeArray<VkCommandBuffer>) {}

	public function destroyCommandPool(pool:VkCommandPool) {}

	public function destroyQueryPool(pool:VkQueryPool) {}

	public function destroyBuffer(buf:VkBuffer) {}

	public function destroyFence(fence:VkFence) {}

	public function destroySemaphore(sem:VkSemaphore) {}

	public function freeMemory(mem:VkDeviceMemory) {}

	public function destroyDescriptorPool(pool:VkDescriptorPool) {}

	public function destroySampler(sampler:VkSampler) {}

	public function destroyShaderModule(module:VkShaderModule) {}

	public function destroyPipelineLayout(layout:VkPipelineLayout) {}

	public function destroyGraphicsPipeline(pipeline:VkGraphicsPipeline) {}

	public function destroyComputePipeline(pipeline:VkComputePipeline) {}

	public function destroyDescriptorSetLayout(layout:VkDescriptorSetLayout) {}
}

abstract VkSurface(hl.Bytes) {}

@:hlNative("limen", "vulkan_vk_")
class VulkanBindings {
	public static var ENABLE_VALIDATION = false;

	@:hlNative("limen", "vulkan_vk_init")
	public static function initialize(enableValidation:Bool):Bool {
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

	public static function initContext(surface:VkSurface, queueFamily:hl.Ref<Int>, requiredCapabilities:Int):VkContext {
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
