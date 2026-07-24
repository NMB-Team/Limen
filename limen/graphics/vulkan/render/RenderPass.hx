package limen.graphics.vulkan.render;

import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.VulkanCore.IntArray;
import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.UnusedFlags;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.memory.Memory.VkAccessFlag;
import limen.graphics.vulkan.memory.Memory.VkDependencyFlag;
import limen.graphics.vulkan.memory.Memory.VkImageAspectFlag;
import limen.graphics.vulkan.memory.Memory.VkImageLayout;
import limen.graphics.vulkan.memory.Memory.VkImageView;
import limen.graphics.vulkan.memory.Memory.VkPipelineStageFlag;
import limen.graphics.vulkan.format.Formats.VkFormat;
import limen.graphics.vulkan.pipeline.Pipeline.VkPipelineBindPoint;

import haxe.Int64;

@:struct class VkAttachmentDescription {
	public var flags:haxe.EnumFlags<VkAttachmentDescriptionFlag>;
	public var format:VkFormat;
	public var samples:Int;
	public var loadOp:VkAttachmentLoadOp;
	public var storeOp:VkAttachmentStoreOp;
	public var stencilLoadOp:VkAttachmentLoadOp;
	public var stencilStoreOp:VkAttachmentStoreOp;
	public var initialLayout:VkImageLayout;
	public var finalLayout:VkImageLayout;

	public function new() {}
}

enum VkAttachmentDescriptionFlag {
	MAY_ALIAS;
}

enum abstract VkAttachmentLoadOp(Int) {
	final LOAD = 0;
	final CLEAR = 1;
	final DONT_CARE = 2;
}

@:struct class VkAttachmentReference {
	public var attachment:Int;
	public var layout:VkImageLayout;

	public function new() {}
}

enum abstract VkAttachmentStoreOp(Int) {
	final STORE = 0;
	final DONT_CARE = 1;
	final STORE_OP_NONE_QCOM = 1000301000;
}

@:struct class VkClearAttachment {
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var colorAttachment:Int;
	public var r:Single;
	public var g:Single;
	public var b:Single;
	public var a:Single;
	public var depth(get, set):Single;
	public var stencil(get, set):Int;

	public function new() {}

	@:noCompletion
	inline function get_depth() {
		return r;
	}

	@:noCompletion
	inline function set_depth(v) {
		return r = v;
	}

	@:noCompletion
	inline function get_stencil() {
		return haxe.io.FPHelper.floatToI32(g);
	}

	@:noCompletion
	inline function set_stencil(v:Int) {
		g = haxe.io.FPHelper.floatToI32(v);
		return v;
	}
}

typedef VkClearColorValue = VkClearValue;

@:struct class VkClearDepthStencilValue {
	public var depth:Single;
	public var stencil:Int;

	public function new() {}
}

@:struct class VkClearRect {
	public var offsetX:Int;
	public var offsetY:Int;
	public var extendX:Int;
	public var extendY:Int;
	public var baseArrayLayer:Int;
	public var layerCount:Int;

	public function new() {}
}

@:struct class VkClearValue {
	public var r:Single;
	public var g:Single;
	public var b:Single;
	public var a:Single;
	public var depth(get, set):Single;
	public var stencil(get, set):Int;

	public function new() {}

	@:noCompletion
	inline function get_depth() {
		return r;
	}

	@:noCompletion
	inline function set_depth(v) {
		return r = v;
	}

	@:noCompletion
	inline function get_stencil() {
		return haxe.io.FPHelper.floatToI32(g);
	}

	@:noCompletion
	inline function set_stencil(v:Int) {
		g = haxe.io.FPHelper.floatToI32(v);
		return v;
	}
}

abstract VkFramebuffer(hl.Abstract<"vk_framebuffer">) {}

enum VkFramebufferCreateFlag {
	IMAGELESS;
}

@:struct class VkFramebufferCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkFramebufferCreateFlag>;
	public var renderPass:VkRenderPass;
	public var attachmentCount:Int;
	public var attachments:ArrayStruct<VkImageView>;
	public var width:Int;
	public var height:Int;
	public var layers:Int;

	public function new() {
		type = FRAMEBUFFER_CREATE_INFO;
	}
}

abstract VkRenderPass(hl.Abstract<"vk_render_pass">) {}

@:struct class VkRenderPassBeginInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var renderPass:VkRenderPass;
	public var framebuffer:VkFramebuffer;
	public var renderAreaOffsetX:Int;
	public var renderAreaOffsetY:Int;
	public var renderAreaExtentX:Int;
	public var renderAreaExtentY:Int;
	public var clearValueCount:Int;
	public var clearValues:ArrayStruct<VkClearValue>;

	public function new() {
		type = RENDER_PASS_BEGIN_INFO;
	}
}

@:struct class VkRenderPassCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var attachmentCount:Int;
	public var attachments:ArrayStruct<VkAttachmentDescription>;
	public var subpassCount:Int;
	public var subpasses:ArrayStruct<VkSubpassDescription>;
	public var dependencyCount:Int;
	public var dependencies:ArrayStruct<VkSubpassDependency>;

	public function new() {
		type = RENDER_PASS_CREATE_INFO;
	}
}

enum abstract VkSubpassContents(Int) {
	final INLINE = 0;
	final SECONDARY_COMMAND_BUFFERS = 1;
}

@:struct class VkSubpassDependency {
	public var srcSubpass:Int;
	public var dstSubpass:Int;
	public var srcStageMask:haxe.EnumFlags<VkPipelineStageFlag>;
	public var dstStageMask:haxe.EnumFlags<VkPipelineStageFlag>;
	public var srcAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var dstAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var dependencyFlags:haxe.EnumFlags<VkDependencyFlag>;

	public function new() {}
}

@:struct class VkSubpassDescription {
	public var flags:haxe.EnumFlags<VkSubpassDescriptionFlag>;
	public var pipelineBindPoint:VkPipelineBindPoint;
	public var inputAttachmentCount:Int;
	public var inputAttachments:ArrayStruct<VkAttachmentReference>;
	public var colorAttachmentCount:Int;
	public var colorAttachments:ArrayStruct<VkAttachmentReference>;
	public var resolveAttachments:ArrayStruct<VkAttachmentReference>;
	public var depthStencilAttachment:ArrayStruct<VkAttachmentReference>;
	public var preserveAttachmentCount:Int;
	public var preserveAttachments:IntArray<Int>;

	public function new() {}
}

enum VkSubpassDescriptionFlag {
	PER_VIEW_ATTRIBUTES_NVX;
	PER_VIEW_POSITION_X_ONLY_NVX;
	FRAGMENT_REGION_QCOM;
	SHADER_RESOLVE_QCOM;
}
