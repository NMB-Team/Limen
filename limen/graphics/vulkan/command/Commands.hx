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
import limen.graphics.vulkan.memory.Memory.VkImageAspectFlag;
import limen.graphics.vulkan.memory.Memory.VkImageLayout;
import limen.graphics.vulkan.memory.Memory.VkImageView;
import limen.graphics.vulkan.memory.Memory.VkImageMemoryBarrier;
import limen.graphics.vulkan.memory.Memory.VkImageSubResourceRange;
import limen.graphics.vulkan.memory.Memory.VkMemoryBarrier;
import limen.graphics.vulkan.memory.Memory.VkPipelineStageFlag;
import limen.graphics.vulkan.pipeline.Pipeline.VkGraphicsPipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkComputePipeline;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineBindPoint;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineLayout;
import limen.graphics.vulkan.pipeline.Pipeline.VkRect2D;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderStageFlag;
import limen.graphics.vulkan.pipeline.Pipeline.VkViewport;
import limen.graphics.vulkan.pipeline.Pipeline.VkCompareOp;
import limen.graphics.vulkan.pipeline.Pipeline.VkCullModeFlags;
import limen.graphics.vulkan.pipeline.Pipeline.VkFrontFace;
import limen.graphics.vulkan.pipeline.Pipeline.VkPrimitiveTopology;
import limen.graphics.vulkan.query.Queries.VkQueryControlFlag;
import limen.graphics.vulkan.query.Queries.VkQueryPool;
import limen.graphics.vulkan.render.RenderPass.VkClearAttachment;
import limen.graphics.vulkan.render.RenderPass.VkClearColorValue;
import limen.graphics.vulkan.render.RenderPass.VkClearDepthStencilValue;
import limen.graphics.vulkan.render.RenderPass.VkClearRect;
import limen.graphics.vulkan.render.RenderPass.VkRenderPassBeginInfo;
import limen.graphics.vulkan.render.RenderPass.VkSubpassContents;

import haxe.Int64;

class VkPipelineStage2 {
	public static final NONE:hl.I64 = (Int64.ofInt(0) : hl.I64);
	public static final TOP_OF_PIPE:hl.I64 = (Int64.ofInt(0x1) : hl.I64);
	public static final DRAW_INDIRECT:hl.I64 = (Int64.ofInt(0x2) : hl.I64);
	public static final VERTEX_INPUT:hl.I64 = (Int64.ofInt(0x4) : hl.I64);
	public static final VERTEX_SHADER:hl.I64 = (Int64.ofInt(0x8) : hl.I64);
	public static final FRAGMENT_SHADER:hl.I64 = (Int64.ofInt(0x80) : hl.I64);
	public static final EARLY_FRAGMENT_TESTS:hl.I64 = (Int64.ofInt(0x100) : hl.I64);
	public static final LATE_FRAGMENT_TESTS:hl.I64 = (Int64.ofInt(0x200) : hl.I64);
	public static final COLOR_ATTACHMENT_OUTPUT:hl.I64 = (Int64.ofInt(0x400) : hl.I64);
	public static final COMPUTE_SHADER:hl.I64 = (Int64.ofInt(0x800) : hl.I64);
	public static final HOST:hl.I64 = (Int64.ofInt(0x4000) : hl.I64);
	public static final ALL_TRANSFER:hl.I64 = (Int64.ofInt(0x1000) : hl.I64);
	public static final BOTTOM_OF_PIPE:hl.I64 = (Int64.ofInt(0x2000) : hl.I64);
	public static final ALL_GRAPHICS:hl.I64 = (Int64.ofInt(0x8000) : hl.I64);
	public static final ALL_COMMANDS:hl.I64 = (Int64.ofInt(0x10000) : hl.I64);
	public static final COPY:hl.I64 = (Int64.make(1, 0) : hl.I64);
	public static final BLIT:hl.I64 = (Int64.make(4, 0) : hl.I64);
}

enum abstract VkIndexType(Int) {
	final UINT16 = 0;
	final UINT32 = 1;
}

@:hlNative("limen", "vulkan_vk_")
abstract VkCommandBuffer(hl.Abstract<"vk_command_buffer">) {
	@:hlNative("limen", "vulkan_vk_command_reset")
	public function reset():Int {
		return 0;
	}

	@:hlNative("limen", "vulkan_vk_command_begin")
	public function begin(inf:VkCommandBufferBeginInfo):Int {
		return 0;
	}

	@:hlNative("limen", "vulkan_vk_command_end")
	public function end():Int {
		return 0;
	}

	public function beginDynamicRenderingClear(inf:VkDynamicRenderingClearInfo) {}

	public function beginDynamicRendering(width:Int, height:Int, colorCount:Int, colorViews:ArrayStruct<VkImageView>, colorLayout:VkImageLayout, depthView:VkImageView, depthLayout:VkImageLayout, stencilView:VkImageView,
		stencilLayout:VkImageLayout) {}

	public function beginDynamicRenderingNative(width:Int, height:Int, colorCount:Int, colorViews:hl.NativeArray<VkImageView>, colorLayout:VkImageLayout, depthView:VkImageView, depthLayout:VkImageLayout, stencilView:VkImageView,
		stencilLayout:VkImageLayout) {}

	public function endDynamicRenderingPresent(colorImage:VkImage) {}

	public function endDynamicRendering() {}

	public function clearColorImage(img:VkImage, layout:VkImageLayout, colors:ArrayStruct<VkClearColorValue>, colorCount:Int, range:VkImageSubResourceRange) {}

	public function clearDepthStencilImage(img:VkImage, layout:VkImageLayout, values:ArrayStruct<VkClearDepthStencilValue>, valuesCount:Int, range:VkImageSubResourceRange) {}

	public function clearAttachments(attachCount:Int, attachs:ArrayStruct<VkClearAttachment>, rectCount:Int, rects:ArrayStruct<VkClearRect>) {}

	public function clearAttachmentsNative(attachCount:Int, attachs:hl.NativeArray<Int>, rectCount:Int, rects:hl.NativeArray<Int>) {}

	public function resetQueryPool(pool:VkQueryPool, firstQuery:Int, queryCount:Int) {}

	public function beginQuery(pool:VkQueryPool, query:Int, flags:haxe.EnumFlags<VkQueryControlFlag>) {}

	public function endQuery(pool:VkQueryPool, query:Int) {}

	public function writeTimestamp2(stageMask:hl.I64, pool:VkQueryPool, query:Int) {}

	public function drawIndexed(indexCount:Int, instanceCount:Int, firstIndex:Int, vertexOffset:Int, firstInstance:Int) {}

	public function drawIndexedIndirect(buffer:VkBuffer, offset:hl.I64, drawCount:Int, stride:Int) {}

	public function drawIndexedIndirectCount(buffer:VkBuffer, offset:hl.I64, countBuffer:VkBuffer, countOffset:hl.I64, maxDrawCount:Int, stride:Int) {}

	public function bindPipeline(bindPoint:VkPipelineBindPoint, pipeline:VkGraphicsPipeline) {}

	public function bindComputePipeline(pipeline:VkComputePipeline) {}

	public function dispatch(groupCountX:Int, groupCountY:Int, groupCountZ:Int) {}

	public function bindIndexBuffer(buffer:VkBuffer, offset:Int, indexType:Int) {}

	public function bindIndexBuffer64(buffer:VkBuffer, offset:hl.I64, indexType:VkIndexType) {}

	public function bindVertexBuffers(first:Int, count:Int, buffers:ArrayStruct<VkBuffer>, offsets:ArrayStruct<VkDeviceSize>) {}

	public function bindVertexBuffersNative(first:Int, count:Int, buffers:hl.NativeArray<VkBuffer>, offsets:hl.NativeArray<hl.I64>) {}

	public function bindVertexBuffer(first:Int, buffer:VkBuffer, offset:Int) {}

	public function setViewport(first:Int, count:Int, viewports:ArrayStruct<VkViewport>) {}

	public function setViewport1(first:Int, x:hl.F32, y:hl.F32, width:hl.F32, height:hl.F32, minDepth:hl.F32, maxDepth:hl.F32) {}

	public function setScissor(first:Int, count:Int, scissors:ArrayStruct<VkRect2D>) {}

	public function setScissor1(first:Int, x:Int, y:Int, width:Int, height:Int) {}

	public function setCullMode(mode:VkCullModeFlags) {}

	public function setFrontFace(face:VkFrontFace) {}

	public function setPrimitiveTopology(topology:VkPrimitiveTopology) {}

	public function setDepthTestEnable(enabled:Bool) {}

	public function setDepthWriteEnable(enabled:Bool) {}

	public function setDepthCompareOp(compare:VkCompareOp) {}

	public function setDepthBiasEnable(enabled:Bool) {}

	public function setDepthBias(constantFactor:hl.F32, clamp:hl.F32, slopeFactor:hl.F32) {}

	public function beginRenderPass(begin:VkRenderPassBeginInfo, contents:VkSubpassContents) {}

	public function endRenderPass() {}

	public function pushConstants(layout:VkPipelineLayout, flags:haxe.EnumFlags<VkShaderStageFlag>, offset:Int, size:Int, data:hl.Bytes) {}

	public function copyBufferToImage(buf:VkBuffer, img:VkImage, layout:VkImageLayout, count:Int, regions:ArrayStruct<VkBufferImageCopy>) {}

	public function copyBufferToImage2(buf:VkBuffer, img:VkImage, layout:VkImageLayout, count:Int, regions:ArrayStruct<VkBufferImageCopy>) {}

	public function copyImageToBuffer2(img:VkImage, layout:VkImageLayout, buf:VkBuffer, count:Int, regions:ArrayStruct<VkBufferImageCopy>) {}

	public function blitImage2(srcImage:VkImage, srcLayout:VkImageLayout, dstImage:VkImage, dstLayout:VkImageLayout, filter:VkFilter, count:Int, regions:ArrayStruct<VkImageBlitRegion>) {}

	public function copyBuffer2(src:VkBuffer, dst:VkBuffer, srcOffset:hl.I64, dstOffset:hl.I64, size:hl.I64) {}

	public function bufferBarrier2(buffer:VkBuffer, offset:hl.I64, size:hl.I64, srcStageMask:hl.I64, srcAccessMask:hl.I64, dstStageMask:hl.I64, dstAccessMask:hl.I64) {}

	public function imageBarrier2(image:VkImage, aspectMask:haxe.EnumFlags<VkImageAspectFlag>, baseMipLevel:Int, levelCount:Int, baseArrayLayer:Int, layerCount:Int, oldLayout:VkImageLayout, newLayout:VkImageLayout, srcStageMask:hl.I64,
		srcAccessMask:hl.I64, dstStageMask:hl.I64, dstAccessMask:hl.I64) {}

	public function memoryBarrier2(srcStageMask:hl.I64, srcAccessMask:hl.I64, dstStageMask:hl.I64, dstAccessMask:hl.I64) {}

	public function pipelineBarrier(srcMask:haxe.EnumFlags<VkPipelineStageFlag>, dstMask:haxe.EnumFlags<VkPipelineStageFlag>, flags:haxe.EnumFlags<VkDependencyFlag>, memCount:Int, memBarriers:ArrayStruct<VkMemoryBarrier>, bufferCount:Int,
		bufBarriers:ArrayStruct<VkBufferMemoryBarrier>, imageCount:Int, imgBarriers:ArrayStruct<VkImageMemoryBarrier>) {}

	public function bindDescriptorSets(bind:VkPipelineBindPoint, layout:VkPipelineLayout, first:Int, count:Int, sets:ArrayStruct<VkDescriptorSet>, offsetCount:Int, offsets:hl.Bytes) {}

	public function bindDescriptorSetsNative(bind:VkPipelineBindPoint, layout:VkPipelineLayout, first:Int, count:Int, sets:hl.NativeArray<VkDescriptorSet>, offsetCount:Int, offsets:hl.NativeArray<Int>) {}

	public function bindDescriptorSet(bind:VkPipelineBindPoint, layout:VkPipelineLayout, first:Int, set:VkDescriptorSet) {}
}

enum abstract VkFilter(Int) {
	final NEAREST = 0;
	final LINEAR = 1;
}

@:struct class VkImageBlitRegion {
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var srcMipLevel:Int;
	public var srcBaseArrayLayer:Int;
	public var srcLayerCount:Int;
	public var srcX0:Int;
	public var srcY0:Int;
	public var srcZ0:Int;
	public var srcX1:Int;
	public var srcY1:Int;
	public var srcZ1:Int;
	public var dstMipLevel:Int;
	public var dstBaseArrayLayer:Int;
	public var dstLayerCount:Int;
	public var dstX0:Int;
	public var dstY0:Int;
	public var dstZ0:Int;
	public var dstX1:Int;
	public var dstY1:Int;
	public var dstZ1:Int;

	public function new() {}
}

@:struct class VkDynamicRenderingClearInfo {
	public var colorImage:VkImage;
	public var colorView:limen.graphics.vulkan.memory.Memory.VkImageView;
	public var depthImage:VkImage;
	public var depthView:limen.graphics.vulkan.memory.Memory.VkImageView;
	public var width:Int;
	public var height:Int;
	public var firstUse:Int;
	public var resume:Int;
	public var depthAspect:haxe.EnumFlags<VkImageAspectFlag>;
	public var red:hl.F32;
	public var green:hl.F32;
	public var blue:hl.F32;
	public var alpha:hl.F32;
	public var depth:hl.F32;
	public var stencil:Int;

	public function new() {}
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
