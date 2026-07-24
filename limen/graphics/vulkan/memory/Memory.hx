package limen.graphics.vulkan.memory;

import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.VulkanCore.IntArray;
import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.pipeline.Pipeline.VkComponentSwizzle;
import limen.graphics.vulkan.format.Formats.VkFormat;

import haxe.Int64;

enum VkAccessFlag {
	INDIRECT_COMMAND_READ;
	INDEX_READ;
	VERTEX_ATTRIBUTE_READ;
	UNIFORM_READ;
	INPUT_ATTACHMENT_READ;
	SHADER_READ;
	SHADER_WRITE;
	COLOR_ATTACHMENT_READ;
	COLOR_ATTACHMENT_WRITE;
	DEPTH_STENCIL_ATTACHMENT_READ;
	DEPTH_STENCIL_ATTACHMENT_WRITE;
	TRANSFER_READ;
	TRANSFER_WRITE;
	HOST_READ;
	HOST_WRITE;
	MEMORY_READ;
	MEMORY_WRITE;
	COMMAND_PREPROCESS_READ_NV;
	COMMAND_PREPROCESS_WRITE_NV;
	COLOR_ATTACHMENT_READ_NONCOHERENT_EXT;
	CONDITIONAL_RENDERING_READ_EXT;
	ACCELERATION_STRUCTURE_READ_KHR;
	ACCELERATION_STRUCTURE_WRITE_KHR;
	SHADING_RATE_IMAGE_READ_NV;
	FRAGMENT_DENSITY_MAP_READ_EXT;
	TRANSFORM_FEEDBACK_WRITE_EXT;
	TRANSFORM_FEEDBACK_COUNTER_READ_EXT;
	TRANSFORM_FEEDBACK_COUNTER_WRITE_EXT;
}

abstract VkBuffer(hl.Abstract<"vk_buffer">) {}

enum VkBufferCreateFlag {
	SPARSE_BINDING;
	SPARSE_RESIDENCY;
	SPARSE_ALIASED;
	PROTECTED;
	DEVICE_ADDRESS_CAPTURE_REPLAY;
}

@:struct class VkBufferCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkBufferCreateFlag>;

	var __align:Int;

	public var size:Int;
	public var size64:Int;
	public var usage:haxe.EnumFlags<VkBufferUsageFlag>;
	public var sharingMode:VkSharingMode;
	public var queueFamilyIndexCount:Int;
	public var queueFamilyIndices:IntArray<Int>;

	public function new() {
		type = BUFFER_CREATE_INFO;
	}
}

@:struct class VkBufferImageCopy {
	public var bufferOffset:hl.I64;
	public var bufferRowLength:Int;
	public var bufferImageHeight:Int;
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var mipLevel:Int;
	public var baseArrayLayer:Int;
	public var layerCount:Int;
	public var imageOffsetX:Int;
	public var imageOffsetY:Int;
	public var imageOffsetZ:Int;
	public var imageWidth:Int;
	public var imageHeight:Int;
	public var imageDepth:Int;

	public function new() {}
}

@:struct class VkBufferMemoryBarrier {
	var type:VkStructureType;
	var next:NextPtr;

	public var srcAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var dstAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var srcQueueFamilyIndex:Int;
	public var dstQueueFamilyIndex:Int;
	public var buffer:VkBuffer;
	public var offset:hl.I64;
	public var size:hl.I64;

	public function new() {
		type = BUFFER_MEMORY_BARRIER;
	}
}

enum VkBufferUsageFlag {
	TRANSFER_SRC;
	TRANSFER_DST;
	UNIFORM_TEXEL_BUFFER;
	STORAGE_TEXEL_BUFFER;
	UNIFORM_BUFFER;
	STORAGE_BUFFER;
	INDEX_BUFFER;
	VERTEX_BUFFER;
	INDIRECT_BUFFER;
}

abstract VkBufferView(hl.Abstract<"vk_buffer_view">) {}

enum VkDependencyFlag {
	BY_REGION;
	VIEW_LOCAL;
	DEVICE_GROUP;
}

abstract VkDeviceMemory(hl.Abstract<"vk_device_memory">) {}
abstract VkImage(hl.Abstract<"vk_image">) {}

enum VkImageAspectFlag {
	COLOR;
	DEPTH;
	STENCIL;
	METADATA;
	PLANE_0;
	PLANE_1;
	PLANE_2;
	MEMORY_PLANE_0;
	MEMORY_PLANE_1;
	MEMORY_PLANE_2;
	MEMORY_PLANE_3;
}

enum VkImageCreateFlag {
	SPARSE_BINDING;
	SPARSE_RESIDENCY;
	SPARSE_ALIASED;
	MUTABLE_FORMAT;
	CUBE_COMPATIBLE;
	// Provided by VK_VERSION_1_1
	_2D_ARRAY_COMPATIBLE;
	SPLIT_INSTANCE_BIND_REGIONS;
	BLOCK_TEXEL_VIEW_COMPATIBLE;
	EXTENDED_USAGE;
	DISJOINT;
	ALIAS;
	PROTECTED;
	// Provided by VK_EXT_sample_locations
	SAMPLE_LOCATIONS_COMPATIBLE_DEPTH_EXT;
	// Provided by VK_NV_corner_sampled_image
	CORNER_SAMPLED_NV;
	// Provided by VK_EXT_fragment_density_map
	SUBSAMPLED_EXT;
}

@:struct class VkImageCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkImageCreateFlag>;
	public var imageType:VkImageType;
	public var format:VkFormat;
	public var width:Int;
	public var height:Int;
	public var depth:Int;
	public var mipLevels:Int;
	public var arrayLayers:Int;
	public var samples:Int;
	public var tiling:VkImageTiling;
	public var usage:haxe.EnumFlags<VkImageUsageFlag>;
	public var sharingMode:VkSharingMode;
	public var queueFamilyIndexCount:Int;
	public var pQueueFamilyIndices:ArrayStruct<Int>;
	public var initialLayout:VkImageLayout;

	public function new() {
		type = IMAGE_CREATE_INFO;
	}
}

enum abstract VkImageLayout(Int) {
	final UNDEFINED = 0;
	final GENERAL = 1;
	final COLOR_ATTACHMENT_OPTIMAL = 2;
	final DEPTH_STENCIL_ATTACHMENT_OPTIMAL = 3;
	final DEPTH_STENCIL_READ_ONLY_OPTIMAL = 4;
	final SHADER_READ_ONLY_OPTIMAL = 5;
	final TRANSFER_SRC_OPTIMAL = 6;
	final TRANSFER_DST_OPTIMAL = 7;
	final PREINITIALIZED = 8;
	final DEPTH_READ_ONLY_STENCIL_ATTACHMENT_OPTIMAL = 1000117000;
	final DEPTH_ATTACHMENT_STENCIL_READ_ONLY_OPTIMAL = 1000117001;
	final DEPTH_ATTACHMENT_OPTIMAL = 1000241000;
	final DEPTH_READ_ONLY_OPTIMAL = 1000241001;
	final STENCIL_ATTACHMENT_OPTIMAL = 1000241002;
	final STENCIL_READ_ONLY_OPTIMAL = 1000241003;
	final PRESENT_SRC_KHR = 1000001002;
	final SHARED_PRESENT_KHR = 1000111000;
	final SHADING_RATE_OPTIMAL_NV = 1000164003;
	final FRAGMENT_DENSITY_MAP_OPTIMAL_EXT = 1000218000;
	final READ_ONLY_OPTIMAL_KHR = 1000314000;
	final ATTACHMENT_OPTIMAL_KHR = 1000314001;
}

@:struct class VkImageMemoryBarrier {
	var type:VkStructureType;
	var next:NextPtr;

	public var srcAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var dstAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var oldLayout:VkImageLayout;
	public var newLayout:VkImageLayout;
	public var srcQueueFamilyIndex:Int;
	public var dstQueueFamilyIndex:Int;
	public var image:VkImage;
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var baseMipLevel:Int;
	public var levelCount:Int;
	public var baseArrayLayer:Int;
	public var layerCount:Int;

	public function new() {
		type = IMAGE_MEMORY_BARRIER;
	}
}

@:struct class VkImageSubResourceRange {
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var baseMipLevel:Int;
	public var levelCount:Int;
	public var baseArrayLayer:Int;
	public var layerCount:Int;

	public function new() {}
}

enum abstract VkImageTiling(Int) {
	final OPTIMAL = 0;
	final LINEAR = 1;
}

enum abstract VkImageType(Int) {
	final TYPE_1D = 0;
	final TYPE_2D = 1;
	final TYPE_3D = 2;
}

enum VkImageUsageFlag {
	TRANSFER_SRC;
	TRANSFER_DST;
	SAMPLED;
	STORAGE;
	COLOR_ATTACHMENT;
	DEPTH_STENCIL_ATTACHMENT;
	TRANSIENT_ATTACHMENT;
	INPUT_ATTACHMENT;
	SHADING_RATE_IMAGE_NV;
	FRAGMENT_DENSITY_MAP_EXT;
}

abstract VkImageView(hl.Abstract<"vk_image_view">) {}

enum VkImageViewCreateFlag {
	FRAGMENT_DENSITY_MAP_DYNAMIC_EXT;
	FRAGMENT_DENSITY_MAP_DEFERRED_EXT;
}

@:struct class VkImageViewCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkImageViewCreateFlag>;
	public var image:VkImage;
	public var viewType:VkImageViewType;
	public var format:VkFormat;
	public var componentR:VkComponentSwizzle;
	public var componentG:VkComponentSwizzle;
	public var componentB:VkComponentSwizzle;
	public var componentA:VkComponentSwizzle;
	// 	subresourceRange : VkImageSubresourceRange;
	public var aspectMask:haxe.EnumFlags<VkImageAspectFlag>;
	public var baseMipLevel:Int;
	public var levelCount:Int;
	public var baseArrayLayer:Int;
	public var layerCount:Int;

	public function new() {
		type = IMAGE_VIEW_CREATE_INFO;
	}
}

enum abstract VkImageViewType(Int) {
	final TYPE_1D = 0;
	final TYPE_2D = 1;
	final TYPE_3D = 2;
	final TYPE_CUBE = 3;
	final TYPE_1D_ARRAY = 4;
	final TYPE_2D_ARRAY = 5;
	final TYPE_CUBE_ARRAY = 6;
}

@:struct class VkMemoryAllocateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var size:Int;
	public var size64:Int;
	public var memoryTypeIndex:Int;

	public function new() {
		type = MEMORY_ALLOCATE_INFO;
	}
}

@:struct class VkMemoryBarrier {
	var type:VkStructureType;
	var next:NextPtr;

	public var srcAccessMask:haxe.EnumFlags<VkAccessFlag>;
	public var dstAccessMask:haxe.EnumFlags<VkAccessFlag>;

	public function new() {
		type = MEMORY_BARRIER;
	}
}

enum VkMemoryPropertyFlag {
	DEVICE_LOCAL;
	HOST_VISIBLE;
	HOST_COHERENT;
	HOST_CACHED;
	LAZILY_ALLOCATED;
	PROTECTED;
	DEVICE_COHERENT_AMD;
	DEVICE_UNCACHED_AMD;
}

@:struct class VkMemoryRequirements {
	public var size:Int;
	public var size64:Int;
	public var alignment:Int;
	public var alignment64:Int;
	public var memoryTypeBits:Int;

	public function new() {}
}

enum VkPipelineStageFlag {
	TOP_OF_PIPE;
	DRAW_INDIRECT;
	VERTEX_INPUT;
	VERTEX_SHADER;
	TESSELLATION_CONTROL_SHADER;
	TESSELLATION_EVALUATION_SHADER;
	GEOMETRY_SHADER;
	FRAGMENT_SHADER;
	EARLY_FRAGMENT_TESTS;
	LATE_FRAGMENT_TESTS;
	COLOR_ATTACHMENT_OUTPUT;
	COMPUTE_SHADER;
	TRANSFER;
	BOTTOM_OF_PIPE;
	HOST;
	ALL_GRAPHICS;
	ALL_COMMANDS;
	COMMAND_PREPROCESS_NV;
	CONDITIONAL_RENDERING_EXT;
	TASK_SHADER_NV;
	MESH_SHADER_NV;
	RAY_TRACING_SHADER_KHR;
	SHADING_RATE_IMAGE_NV;
	FRAGMENT_DENSITY_PROCESS_EXT;
	TRANSFORM_FEEDBACK_EXT;
	ACCELERATION_STRUCTURE_BUILD_KHR;
}

enum abstract VkSharingMode(Int) {
	final EXCLUSIVE = 0;
	final CONCURRENT = 1;
}
