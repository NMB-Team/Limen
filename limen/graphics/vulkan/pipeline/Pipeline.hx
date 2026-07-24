package limen.graphics.vulkan.pipeline;

import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.VulkanCore.IntArray;
import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.UnusedFlags;
import limen.graphics.vulkan.VulkanCore.VkBool32;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.descriptor.Descriptors.VkDescriptorSetLayout;
import limen.graphics.vulkan.render.RenderPass.VkRenderPass;
import limen.graphics.vulkan.format.Formats.VkFormat;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderModule;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderStageFlag;
import limen.graphics.vulkan.shader.ShaderModule.VkSpecializationInfo;

import haxe.Int64;

enum abstract VkBlendFactor(Int) {
	final ZERO = 0;
	final ONE = 1;
	final SRC_COLOR = 2;
	final ONE_MINUS_SRC_COLOR = 3;
	final DST_COLOR = 4;
	final ONE_MINUS_DST_COLOR = 5;
	final SRC_ALPHA = 6;
	final ONE_MINUS_SRC_ALPHA = 7;
	final DST_ALPHA = 8;
	final ONE_MINUS_DST_ALPHA = 9;
	final CONSTANT_COLOR = 10;
	final ONE_MINUS_CONSTANT_COLOR = 11;
	final CONSTANT_ALPHA = 12;
	final ONE_MINUS_CONSTANT_ALPHA = 13;
	final SRC_ALPHA_SATURATE = 14;
	final SRC1_COLOR = 15;
	final ONE_MINUS_SRC1_COLOR = 16;
	final SRC1_ALPHA = 17;
	final ONE_MINUS_SRC1_ALPHA = 18;
}

enum abstract VkBlendOp(Int) {
	final ADD = 0;
	final SUBTRACT = 1;
	final REVERSE_SUBTRACT = 2;
	final MIN = 3;
	final MAX = 4;
	final ZERO_EXT = 1000148000;
	final SRC_EXT = 1000148001;
	final DST_EXT = 1000148002;
	final SRC_OVER_EXT = 1000148003;
	final DST_OVER_EXT = 1000148004;
	final SRC_IN_EXT = 1000148005;
	final DST_IN_EXT = 1000148006;
	final SRC_OUT_EXT = 1000148007;
	final DST_OUT_EXT = 1000148008;
	final SRC_ATOP_EXT = 1000148009;
	final DST_ATOP_EXT = 1000148010;
	final XOR_EXT = 1000148011;
	final MULTIPLY_EXT = 1000148012;
	final SCREEN_EXT = 1000148013;
	final OVERLAY_EXT = 1000148014;
	final DARKEN_EXT = 1000148015;
	final LIGHTEN_EXT = 1000148016;
	final COLORDODGE_EXT = 1000148017;
	final COLORBURN_EXT = 1000148018;
	final HARDLIGHT_EXT = 1000148019;
	final SOFTLIGHT_EXT = 1000148020;
	final DIFFERENCE_EXT = 1000148021;
	final EXCLUSION_EXT = 1000148022;
	final INVERT_EXT = 1000148023;
	final INVERT_RGB_EXT = 1000148024;
	final LINEARDODGE_EXT = 1000148025;
	final LINEARBURN_EXT = 1000148026;
	final VIVIDLIGHT_EXT = 1000148027;
	final LINEARLIGHT_EXT = 1000148028;
	final PINLIGHT_EXT = 1000148029;
	final HARDMIX_EXT = 1000148030;
	final HSL_HUE_EXT = 1000148031;
	final HSL_SATURATION_EXT = 1000148032;
	final HSL_COLOR_EXT = 1000148033;
	final HSL_LUMINOSITY_EXT = 1000148034;
	final PLUS_EXT = 1000148035;
	final PLUS_CLAMPED_EXT = 1000148036;
	final PLUS_CLAMPED_ALPHA_EXT = 1000148037;
	final PLUS_DARKER_EXT = 1000148038;
	final MINUS_EXT = 1000148039;
	final MINUS_CLAMPED_EXT = 1000148040;
	final CONTRAST_EXT = 1000148041;
	final INVERT_OVG_EXT = 1000148042;
	final RED_EXT = 1000148043;
	final GREEN_EXT = 1000148044;
	final BLUE_EXT = 1000148045;
}

enum abstract VkCompareOp(Int) {
	final NEVER = 0;
	final LESS = 1;
	final EQUAL = 2;
	final LESS_OR_EQUAL = 3;
	final GREATER = 4;
	final NOT_EQUAL = 5;
	final GREATER_OR_EQUAL = 6;
	final ALWAYS = 7;
}

enum abstract VkComponentSwizzle(Int) {
	final IDENTITY = 0;
	final ZERO = 1;
	final ONE = 2;
	final R = 3;
	final G = 4;
	final B = 5;
	final A = 6;
}

enum abstract VkCullModeFlags(Int) {
	final NONE = 0;
	final FRONT = 1;
	final BACK = 2;
	final FRONT_AND_BACK = 3;
}

enum abstract VkDynamicState(Int) {
	final VIEWPORT = 0;
	final SCISSOR = 1;
	final LINE_WIDTH = 2;
	final DEPTH_BIAS = 3;
	final BLEND_CONSTANTS = 4;
	final DEPTH_BOUNDS = 5;
	final STENCIL_COMPARE_MASK = 6;
	final STENCIL_WRITE_MASK = 7;
	final STENCIL_REFERENCE = 8;
	final VIEWPORT_W_SCALING_NV = 1000087000;
	final DISCARD_RECTANGLE_EXT = 1000099000;
	final SAMPLE_LOCATIONS_EXT = 1000143000;
	final RAY_TRACING_PIPELINE_STACK_SIZE_KHR = 1000347000;
	final VIEWPORT_SHADING_RATE_PALETTE_NV = 1000164004;
	final VIEWPORT_COARSE_SAMPLE_ORDER_NV = 1000164006;
	final EXCLUSIVE_SCISSOR_NV = 1000205001;
	final FRAGMENT_SHADING_RATE_KHR = 1000226000;
	final LINE_STIPPLE_EXT = 1000259000;
	final CULL_MODE_EXT = 1000267000;
	final FRONT_FACE_EXT = 1000267001;
	final PRIMITIVE_TOPOLOGY_EXT = 1000267002;
	final VIEWPORT_WITH_COUNT_EXT = 1000267003;
	final SCISSOR_WITH_COUNT_EXT = 1000267004;
	final VERTEX_INPUT_BINDING_STRIDE_EXT = 1000267005;
	final DEPTH_TEST_ENABLE_EXT = 1000267006;
	final DEPTH_WRITE_ENABLE_EXT = 1000267007;
	final DEPTH_COMPARE_OP_EXT = 1000267008;
	final DEPTH_BOUNDS_TEST_ENABLE_EXT = 1000267009;
	final STENCIL_TEST_ENABLE_EXT = 1000267010;
	final STENCIL_OP_EXT = 1000267011;
}

enum abstract VkFilter(Int) {
	final NEAREST = 0;
	final LINEAR = 1;
	final CUBIC_IMG = 1000015000;
}

enum abstract VkFrontFace(Int) {
	final COUNTER_CLOCKWISE = 0;
	final CLOCKWISE = 1;
}

abstract VkGraphicsPipeline(hl.Abstract<"vk_gpipeline">) {}

@:struct class VkGraphicsPipelineCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkPipelineCreateFlags>;
	public var stageCount:Int;
	public var stages:ArrayStruct<VkPipelineShaderStage>;
	public var vertexInput:VkPipelineVertexInput;
	public var inputAssembly:VkPipelineInputAssembly;
	public var tessellation:VkPipelineTessellation;
	public var viewport:VkPipelineViewport;
	public var rasterization:VkPipelineRasterization;
	public var multisample:VkPipelineMultisample;
	public var depthStencil:VkPipelineDepthStencil;
	public var colorBlend:VkPipelineColorBlend;
	public var dynamicDef:VkPipelineDynamic;
	public var layout:VkPipelineLayout;
	public var renderPass:VkRenderPass;
	public var subpass:Int;
	public var basePipelineHandle:VkGraphicsPipeline;
	public var basePipelineIndex:Int;

	public function new() {
		type = GRAPHICS_PIPELINE_CREATE_INFO;
	}
}

enum abstract VkLogicOp(Int) {
	final CLEAR = 0;
	final AND = 1;
	final AND_REVERSE = 2;
	final COPY = 3;
	final AND_INVERTED = 4;
	final NO_OP = 5;
	final XOR = 6;
	final OR = 7;
	final NOR = 8;
	final EQUIVALENT = 9;
	final INVERT = 10;
	final OR_REVERSE = 11;
	final COPY_INVERTED = 12;
	final OR_INVERTED = 13;
	final NAND = 14;
	final SET = 15;
}

enum abstract VkPipelineBindPoint(Int) {
	final GRAPHICS = 0;
	final COMPUTE = 1;
	final RAY_TRACING_KHR = 1000165000;
}

@:struct class VkPipelineColorBlend {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var logicOpEnable:VkBool32;
	public var logicOp:VkLogicOp;
	public var attachmentCount:Int;
	public var attachments:ArrayStruct<VkPipelineColorBlendAttachmentState>;
	public var blendConstant0:Single;
	public var blendConstant1:Single;
	public var blendConstant2:Single;
	public var blendConstant3:Single;

	public function new() {
		type = PIPELINE_COLOR_BLEND_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineColorBlendAttachmentState {
	public var blendEnable:VkBool32;
	public var srcColorBlendFactor:VkBlendFactor;
	public var dstColorBlendFactor:VkBlendFactor;
	public var colorBlendOp:VkBlendOp;
	public var srcAlphaBlendFactor:VkBlendFactor;
	public var dstAlphaBlendFactor:VkBlendFactor;
	public var alphaBlendOp:VkBlendOp;
	public var colorWriteMask:Int; // RGBA

	public function new() {}
}

enum VkPipelineCreateFlags {
	DISABLE_OPTIMIZATION;
	ALLOW_DERIVATIVES;
	DERIVATIVE;
	VIEW_INDEX_FROM_DEVICE_INDEX;
	DISPATCH_BASE;
	DEFER_COMPILE_NV;
	CAPTURE_STATISTICS_KHR;
	CAPTURE_INTERNAL_REPRESENTATIONS_KHR;
	FAIL_ON_PIPELINE_COMPILE_REQUIRED_EXT;
	EARLY_RETURN_ON_FAILURE_EXT;
	LIBRARY_KHR;
	RAY_TRACING_SKIP_TRIANGLES_KHR;
	RAY_TRACING_SKIP_AABBS_KHR;
	RAY_TRACING_NO_NULL_ANY_HIT_SHADERS_KHR;
	RAY_TRACING_NO_NULL_CLOSEST_HIT_SHADERS_KHR;
	RAY_TRACING_NO_NULL_MISS_SHADERS_KHR;
	RAY_TRACING_NO_NULL_INTERSECTION_SHADERS_KHR;
	INDIRECT_BINDABLE_NV;
	RAY_TRACING_SHADER_GROUP_HANDLE_CAPTURE_REPLAY_KHR;
}

@:struct class VkPipelineDepthStencil {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var depthTestEnable:VkBool32;
	public var depthWriteEnable:VkBool32;
	public var depthCompareOp:VkCompareOp;
	public var depthBoundsTestEnable:VkBool32;
	public var stencilTestEnable:VkBool32;
	public var frontFail:VkStencilOp;
	public var frontPass:VkStencilOp;
	public var frontDepthFail:VkStencilOp;
	public var frontCompare:VkStencilOp;
	public var frontMask:Int;
	public var frontWrite:Int;
	public var frontReference:Int;
	public var backFail:VkStencilOp;
	public var backPass:VkStencilOp;
	public var backDepthFail:VkStencilOp;
	public var backCompare:VkStencilOp;
	public var backMask:Int;
	public var backWrite:Int;
	public var backReference:Int;
	public var minDepthBounds:Single;
	public var maxDepthBounds:Single;

	public function new() {
		type = PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineDynamic {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var dynamicStateCount:Int;
	public var dynamicStates:IntArray<VkDynamicState>;

	public function new() {
		type = PIPELINE_DYNAMIC_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineInputAssembly {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var topology:VkPrimitiveTopology;
	public var primitiveRestartEnable:VkBool32;

	public function new() {
		type = PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO;
	}
}

abstract VkPipelineLayout(hl.Abstract<"vk_pipeline_layout">) {}

@:struct class VkPipelineLayoutCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var setLayoutCount:Int;
	public var setLayouts:ArrayStruct<VkDescriptorSetLayout>;
	public var pushConstantRangeCount:Int;
	public var pushConstantRanges:ArrayStruct<VkPushConstantRange>;

	public function new() {
		type = PIPELINE_LAYOUT_CREATE_INFO;
	}
}

@:struct class VkPipelineMultisample {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var rasterizationSamples:Int;
	public var sampleShadingEnable:VkBool32;
	public var minSampleShading:Single;
	public var sampleMask:IntArray<Int>;
	public var alphaToCoverageEnable:VkBool32;
	public var alphaToOneEnable:VkBool32;

	public function new() {
		type = PIPELINE_MULTISAMPLE_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineRasterization {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var depthClampEnable:VkBool32;
	public var rasterizerDiscardEnable:VkBool32;
	public var polygonMode:VkPolygonMode;
	public var cullMode:VkCullModeFlags;
	public var frontFace:VkFrontFace;
	public var depthBiasEnable:VkBool32;
	public var depthBiasConstantFactor:Single;
	public var depthBiasClamp:Single;
	public var depthBiasSlopeFactor:Single;
	public var lineWidth:Single;

	public function new() {
		type = PIPELINE_RASTERIZATION_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineShaderStage {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkPipelineShaderStageCreateFlag>;
	public var stage:haxe.EnumFlags<VkShaderStageFlag>;
	public var module:VkShaderModule;
	public var name:hl.Bytes;
	public var specializationInfo:VkSpecializationInfo;

	public function new() {
		type = PIPELINE_SHADER_STAGE_CREATE_INFO;
	}
}

enum VkPipelineShaderStageCreateFlag {
	ALLOW_VARYING_SUBGROUP_SIZE_EXT;
	REQUIRE_FULL_SUBGROUPS_EXT;
}

@:struct class VkPipelineTessellation {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var patchControlPoints:Int;

	public function new() {
		type = PIPELINE_TESSELLATION_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineVertexInput {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var vertexBindingDescriptionCount:Int;
	public var vertexBindingDescriptions:ArrayStruct<VkVertexInputBindingDescription>;
	public var vertexAttributeDescriptionCount:Int;
	public var vertexAttributeDescriptions:ArrayStruct<VkVertexInputAttributeDescription>;

	public function new() {
		type = PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO;
	}
}

@:struct class VkPipelineViewport {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:UnusedFlags;
	public var viewportCount:Int;
	public var viewports:ArrayStruct<VkViewport>;
	public var scissorCount:Int;
	public var scissors:ArrayStruct<VkRect2D>;

	public function new() {
		type = PIPELINE_VIEWPORT_STATE_CREATE_INFO;
	}
}

enum abstract VkPolygonMode(Int) {
	final FILL = 0;
	final LINE = 1;
	final POINT = 2;
	final FILL_RECTANGLE_NV = 1000153000;
}

enum abstract VkPrimitiveTopology(Int) {
	final POINT_LIST = 0;
	final LINE_LIST = 1;
	final LINE_STRIP = 2;
	final TRIANGLE_LIST = 3;
	final TRIANGLE_STRIP = 4;
	final TRIANGLE_FAN = 5;
	final LINE_LIST_WITH_ADJACENCY = 6;
	final LINE_STRIP_WITH_ADJACENCY = 7;
	final TRIANGLE_LIST_WITH_ADJACENCY = 8;
	final TRIANGLE_STRIP_WITH_ADJACENCY = 9;
	final PATCH_LIST = 10;
}

@:struct class VkPushConstantRange {
	public var stageFlags:haxe.EnumFlags<VkShaderStageFlag>;
	public var offset:Int;
	public var size:Int;

	public function new() {}
}

@:struct class VkRect2D {
	public var offsetX:Int;
	public var offsetY:Int;
	public var extendX:Int;
	public var extendY:Int;

	public function new() {}
}

enum abstract VkStencilOp(Int) {
	final KEEP = 0;
	final ZERO = 1;
	final REPLACE = 2;
	final INCREMENT_AND_CLAMP = 3;
	final DECREMENT_AND_CLAMP = 4;
	final INVERT = 5;
	final INCREMENT_AND_WRAP = 6;
	final DECREMENT_AND_WRAP = 7;
}

@:struct class VkVertexInputAttributeDescription {
	public var location:Int;
	public var binding:Int;
	public var format:VkFormat;
	public var offset:Int;

	public function new() {}
}

@:struct class VkVertexInputBindingDescription {
	public var binding:Int;
	public var stride:Int;
	public var inputRate:VkVertexInputRate;

	public function new() {}
}

enum abstract VkVertexInputRate(Int) {
	final VERTEX = 0;
	final INSTANCE = 1;
}

@:struct class VkViewport {
	public var x:Single;
	public var y:Single;
	public var width:Single;
	public var height:Single;
	public var minDepth:Single;
	public var maxDepth:Single;

	public function new() {}
}
