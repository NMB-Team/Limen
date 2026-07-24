package limen.graphics.vulkan.command;

import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.UnusedFlags;
import limen.graphics.vulkan.VulkanCore.VkDeviceSize;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSet;
import limen.graphics.vulkan.memory.Memory.VkBuffer;
import limen.graphics.vulkan.memory.Memory.VkBufferImageCopy;
import limen.graphics.vulkan.memory.Memory.VkBufferMemoryBarrier;
import limen.graphics.vulkan.memory.Memory.VkDependencyFlag;
import limen.graphics.vulkan.memory.Memory.VkImage;
import limen.graphics.vulkan.memory.Memory.VkImageLayout;
import limen.graphics.vulkan.memory.Memory.VkImageMemoryBarrier;
import limen.graphics.vulkan.memory.Memory.VkImageSubResourceRange;
import limen.graphics.vulkan.memory.Memory.VkMemoryBarrier;
import limen.graphics.vulkan.memory.Memory.VkPipelineStageFlag;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineBindPoint;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayout;
import limen.graphics.vulkan.pipeline.Pipeline.VkRect2D;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderStageFlag;
import limen.graphics.vulkan.pipeline.Pipeline.VkViewport;
import limen.graphics.vulkan.render.RenderPass.VkClearAttachment;
import limen.graphics.vulkan.render.RenderPass.VkClearColorValue;
import limen.graphics.vulkan.render.RenderPass.VkClearDepthStencilValue;
import limen.graphics.vulkan.render.RenderPass.VkClearRect;
import limen.graphics.vulkan.render.RenderPass.VkRenderPassBeginInfo;
import limen.graphics.vulkan.render.RenderPass.VkSubpassContents;

import haxe.Int64;

@:hlNative("?limen_vulkan", "vk_")
abstract VkCommandBuffer(hl.Abstract<"vk_command_buffer">) {
	@:hlNative("?limen_vulkan", "vk_command_begin")
	public function begin(inf:VkCommandBufferBeginInfo) {}

	@:hlNative("?limen_vulkan", "vk_command_end")
	public function end() {}

	public function clearColorImage(img:VkImage, layout:VkImageLayout, colors:ArrayStruct<VkClearColorValue>, colorCount:Int, range:VkImageSubResourceRange) {}

	public function clearDepthStencilImage(img:VkImage, layout:VkImageLayout, values:ArrayStruct<VkClearDepthStencilValue>, valuesCount:Int, range:VkImageSubResourceRange) {}

	public function clearAttachments(attachCount:Int, attachs:ArrayStruct<VkClearAttachment>, rectCount:Int, rects:ArrayStruct<VkClearRect>) {}

	public function drawIndexed(indexCount:Int, instanceCount:Int, firstIndex:Int, vertexOffset:Int, firstInstance:Int) {}

	public function bindPipeline(bindPoint:VkPipelineBindPoint, pipeline:VkGraphicsPipeline) {}

	public function bindIndexBuffer(buffer:VkBuffer, offset:Int, indexType:Int) {}

	public function bindVertexBuffers(first:Int, count:Int, buffers:ArrayStruct<VkBuffer>, offsets:ArrayStruct<VkDeviceSize>) {}

	public function bindVertexBuffer(first:Int, buffer:VkBuffer, offset:Int) {}

	public function setViewport(first:Int, count:Int, viewports:ArrayStruct<VkViewport>) {}

	public function setViewport1(first:Int, x:hl.F32, y:hl.F32, width:hl.F32, height:hl.F32, minDepth:hl.F32, maxDepth:hl.F32) {}

	public function setScissor(first:Int, count:Int, scissors:ArrayStruct<VkRect2D>) {}

	public function setScissor1(first:Int, x:Int, y:Int, width:Int, height:Int) {}

	public function beginRenderPass(begin:VkRenderPassBeginInfo, contents:VkSubpassContents) {}

	public function endRenderPass() {}

	public function pushConstants(layout:VkPipelineLayout, flags:haxe.EnumFlags<VkShaderStageFlag>, offset:Int, size:Int, data:hl.Bytes) {}

	public function copyBufferToImage(buf:VkBuffer, img:VkImage, layout:VkImageLayout, count:Int, regions:ArrayStruct<VkBufferImageCopy>) {}

	public function pipelineBarrier(srcMask:haxe.EnumFlags<VkPipelineStageFlag>, dstMask:haxe.EnumFlags<VkPipelineStageFlag>, flags:haxe.EnumFlags<VkDependencyFlag>, memCount:Int, memBarriers:ArrayStruct<VkMemoryBarrier>, bufferCount:Int,
		bufBarriers:ArrayStruct<VkBufferMemoryBarrier>, imageCount:Int, imgBarriers:ArrayStruct<VkImageMemoryBarrier>) {}

	public function bindDescriptorSets(bind:VkPipelineBindPoint, layout:VkPipelineLayout, first:Int, count:Int, sets:ArrayStruct<VkDescriptorSet>, offsetCount:Int, offsets:hl.Bytes) {}

	public function bindDescriptorSet(bind:VkPipelineBindPoint, layout:VkPipelineLayout, first:Int, set:VkDescriptorSet) {}
}

@:struct class VkCommandBufferAllocateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var commandPool:VkCommandPool;
	public var level:VkCommandBufferLevel;
	public var commandBufferCount:Int;

	public function new() {
		type = COMMAND_BUFFER_ALLOCATE_INFO;
	}
}

@:struct class VkCommandBufferBeginInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkCommandBufferUsageFlag>;
	public var pInheritanceInfo:{};

	public function new() {
		type = COMMAND_BUFFER_BEGIN_INFO;
	}
}

enum abstract VkCommandBufferLevel(Int) {
	final PRIMARY = 0;
	final SECONDARY = 1;
}

enum VkCommandBufferUsageFlag {
	ONE_TIME_SUBMIT;
	RENDER_PASS_CONTINUE;
	SIMULTANEOUS_USE;
}

abstract VkCommandPool(hl.Abstract<"vk_command_pool">) {}

enum VkCommandPoolCreateFlag {
	TRANSIENT;
	RESET_COMMAND_BUFFER;
	PROTECTED;
}

@:struct class VkCommandPoolCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkCommandPoolCreateFlag>;
	public var queueFamilyIndex:Int;

	public function new() {
		type = COMMAND_POOL_CREATE_INFO;
	}
}

abstract VkFence(hl.Abstract<"vk_fence">) {}

enum VkFenceCreateFlag {
	SIGNALED;
}

@:struct class VkFenceCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkFenceCreateFlag>;

	public function new() {
		type = FENCE_CREATE_INFO;
	}
}

abstract VkSemaphore(hl.Abstract<"vk_semaphore">) {}

@:struct class VkSemaphoreCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;
	var unusedFlags:Int;

	public function new() {
		type = SEMAPHORE_CREATE_INFO;
	}
}

@:struct class VkSubmitInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var waitSemaphoreCount:Int;
	public var pWaitSemaphores:ArrayStruct<VkSemaphore>;
	public var pWaitDstStageMask:ArrayStruct<haxe.EnumFlags<VkPipelineStageFlag>>;
	public var commandBufferCount:Int;
	public var pCommandBuffers:ArrayStruct<VkCommandBuffer>;
	public var signalSemaphoreCount:Int;
	public var pSignalSemaphores:ArrayStruct<VkSemaphore>;

	public function new() {
		type = SUBMIT_INFO;
	}
}
