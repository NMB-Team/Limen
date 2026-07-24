package limen.graphics.vulkan.descriptor;

import limen.graphics.vulkan.VulkanCore.ArrayStruct;
import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.VkStructureType;
import limen.graphics.vulkan.memory.Memory.VkBuffer;
import limen.graphics.vulkan.memory.Memory.VkBufferView;
import limen.graphics.vulkan.memory.Memory.VkImageLayout;
import limen.graphics.vulkan.memory.Memory.VkImageView;
import limen.graphics.vulkan.shader.ShaderModule.VkShaderStageFlag;
import limen.graphics.vulkan.sampler.Samplers.VkSampler;

import haxe.Int64;

@:struct class VkCopyDescriptorSet {
	var type:VkStructureType;
	var next:NextPtr;

	public var srcSet:VkDescriptorSet;
	public var srcBinding:Int;
	public var srcArrayElement:Int;
	public var dstSet:VkDescriptorSet;
	public var dstBinding:Int;
	public var dstArrayElement:Int;
	public var descriptorCount:Int;

	public function new() {
		type = COPY_DESCRIPTOR_SET;
	}
}

@:struct class VkDescriptorBufferInfo {
	public var buffer:VkBuffer;
	public var offset:hl.I64;
	public var range:hl.I64;

	public function new() {}
}

@:struct class VkDescriptorImageInfo {
	public var sampler:VkSampler;
	public var imageView:VkImageView;
	public var imageLayout:VkImageLayout;

	public function new() {}
}

abstract VkDescriptorPool(hl.Abstract<"vk_descriptor_pool">) {}

enum VkDescriptorPoolCreateFlag {
	FREE_DESCRIPTOR_SET;
	UPDATE_AFTER_BIND;
	HOST_ONLY_VALVE;
}

@:struct class VkDescriptorPoolCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkDescriptorPoolCreateFlag>;
	public var maxSets:Int;
	public var poolSizeCount:Int;
	public var pPoolSizes:ArrayStruct<VkDescriptorPoolSize>;

	public function new() {
		type = DESCRIPTOR_POOL_CREATE_INFO;
	}
}

@:struct class VkDescriptorPoolSize {
	public var type:VkDescriptorType;
	public var descriptorCount:Int;

	public function new() {}
}

abstract VkDescriptorSet(hl.Abstract<"vk_descriptor_set">) {}

@:struct class VkDescriptorSetAllocateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var descriptorPool:VkDescriptorPool;
	public var descriptorSetCount:Int;
	public var pSetLayouts:ArrayStruct<VkDescriptorSetLayout>;

	public function new() {
		type = DESCRIPTOR_SET_ALLOCATE_INFO;
	}
}

abstract VkDescriptorSetLayout(hl.Abstract<"vk_descriptor_layout">) {}

@:struct class VkDescriptorSetLayoutBinding {
	public var binding:Int;
	public var descriptorType:VkDescriptorType;
	public var descriptorCount:Int;
	public var stageFlags:haxe.EnumFlags<VkShaderStageFlag>;
	public var immutableSamplers:Any; // VkSampler

	public function new() {}
}

enum VkDescriptorSetLayoutCreateFlag {
	PUSH_DESCRIPTOR_KHR;
	UPDATE_AFTER_BIND_POOL;
	HOST_ONLY_POOL_VALVE;
}

@:struct class VkDescriptorSetLayoutCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;

	public var flags:haxe.EnumFlags<VkDescriptorSetLayoutCreateFlag>;
	public var bindingCount:Int;
	public var bindings:ArrayStruct<VkDescriptorSetLayoutBinding>;

	public function new() {
		type = DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
	}
}

enum abstract VkDescriptorType(Int) {
	final SAMPLER = 0;
	final COMBINED_IMAGE_SAMPLER = 1;
	final SAMPLED_IMAGE = 2;
	final STORAGE_IMAGE = 3;
	final UNIFORM_TEXEL_BUFFER = 4;
	final STORAGE_TEXEL_BUFFER = 5;
	final UNIFORM_BUFFER = 6;
	final STORAGE_BUFFER = 7;
	final UNIFORM_BUFFER_DYNAMIC = 8;
	final STORAGE_BUFFER_DYNAMIC = 9;
	final INPUT_ATTACHMENT = 10;
	final INLINE_UNIFORM_BLOCK_EXT = 1000138000;
	final ACCELERATION_STRUCTURE_KHR = 1000150000;
	final ACCELERATION_STRUCTURE_NV = 1000165000;
	final MUTABLE_VALVE = 1000351000;
}

@:struct class VkWriteDescriptorSet {
	var type:VkStructureType;
	var next:NextPtr;

	public var dstSet:VkDescriptorSet;
	public var dstBinding:Int;
	public var dstArrayElement:Int;
	public var descriptorCount:Int;
	public var descriptorType:VkDescriptorType;
	public var pImageInfo:ArrayStruct<VkDescriptorImageInfo>;
	public var pBufferInfo:ArrayStruct<VkDescriptorBufferInfo>;
	public var pTexelBufferView:ArrayStruct<VkBufferView>;

	public function new() {
		type = WRITE_DESCRIPTOR_SET;
	}
}
