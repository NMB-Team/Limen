package limen.graphics.vulkan.sampler;

import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.VkBool32;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.pipeline.Pipeline.VkCompareOp;
import limen.graphics.vulkan.pipeline.Pipeline.VkFilter;

import haxe.Int64;

enum abstract VkBorderColor(Int) {
	final FLOAT_TRANSPARENT_BLACK = 0;
	final INT_TRANSPARENT_BLACK = 1;
	final FLOAT_OPAQUE_BLACK = 2;
	final INT_OPAQUE_BLACK = 3;
	final FLOAT_OPAQUE_WHITE = 4;
	final INT_OPAQUE_WHITE = 5;
	final FLOAT_CUSTOM_EXT = 1000287003;
	final INT_CUSTOM_EXT = 1000287004;
}

abstract VkSampler(hl.Abstract<"vk_sampler">) {}

enum abstract VkSamplerAddressMode(Int) {
	final REPEAT = 0;
	final MIRRORED_REPEAT = 1;
	final CLAMP_TO_EDGE = 2;
	final CLAMP_TO_BORDER = 3;
	final MIRROR_CLAMP_TO_EDGE = 4;
}

enum VkSamplerCreateFlag {
	SUBSAMPLED_EXT;
	SUBSAMPLED_COARSE_EXT;
}

@:struct class VkSamplerCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkSamplerCreateFlag>;
	public var magFilter:VkFilter;
	public var minFilter:VkFilter;
	public var mipmapMode:VkSamplerMipmapMode;
	public var addressModeU:VkSamplerAddressMode;
	public var addressModeV:VkSamplerAddressMode;
	public var addressModeW:VkSamplerAddressMode;
	public var mipLodBias:Single;
	public var anisotropyEnable:VkBool32;
	public var maxAnisotropy:Single;
	public var compareEnable:VkBool32;
	public var compareOp:VkCompareOp;
	public var minLod:Single;
	public var maxLod:Single;
	public var borderColor:VkBorderColor;
	public var unnormalizedCoordinates:VkBool32;

	public function new() {
		type = SAMPLER_CREATE_INFO;
	}
}

enum abstract VkSamplerMipmapMode(Int) {
	final NEAREST = 0;
	final LINEAR = 1;
}
