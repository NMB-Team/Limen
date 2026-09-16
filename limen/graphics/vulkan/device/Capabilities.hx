package limen.graphics.vulkan.device;

import limen.graphics.vulkan.internal.VulkanBindings.VkContext;

class Capabilities {
	public static inline final FOUNDATION = (1 << 0) | (1 << 1) | (1 << 2);
	public static inline final SWAPCHAIN_MAINTENANCE_1 = 1 << 3;
	public static inline final VULKAN_1_4 = 1 << 4;
	public static inline final PORTABILITY_SUBSET = 1 << 5;
	public static inline final SAMPLER_ANISOTROPY = 1 << 6;
	public static inline final INDEPENDENT_BLEND = 1 << 7;
	public static inline final DEPTH_CLAMP = 1 << 8;
	public static inline final FILL_MODE_NON_SOLID = 1 << 9;
	public static inline final MULTI_DRAW_INDIRECT = 1 << 10;
	public static inline final DRAW_INDIRECT_FIRST_INSTANCE = 1 << 11;
	public static inline final DRAW_INDIRECT_COUNT = 1 << 12;
	public static inline final OCCLUSION_QUERY_PRECISE = 1 << 13;
	public static inline final GRAPHICS_QUEUE_COMPUTE = 1 << 14;
	public static inline final DESCRIPTOR_INDEXING = 1 << 15;
	public static inline final SAMPLED_IMAGE_NON_UNIFORM = 1 << 16;
	public static inline final STORAGE_BUFFER_NON_UNIFORM = 1 << 17;
	public static inline final DESCRIPTOR_PARTIALLY_BOUND = 1 << 18;
	public static inline final SAMPLED_IMAGE_UPDATE_AFTER_BIND = 1 << 19;
	public static inline final STORAGE_BUFFER_UPDATE_AFTER_BIND = 1 << 20;

	public final deviceName:String;
	public final apiVersion:Int;
	public final vendorId:Int;
	public final deviceId:Int;
	public final driverVersion:Int;
	public final graphicsQueueFamily:Int;
	public final presentQueueFamily:Int;
	public final computeQueueFamily:Int;
	public final transferQueueFamily:Int;
	public final timestampValidBits:Int;
	public final timestampPeriod:Float;
	public final dynamicRendering:Bool;
	public final synchronization2:Bool;
	public final timelineSemaphore:Bool;
	public final swapchainMaintenance1:Bool;
	public final vulkan14:Bool;
	public final portabilitySubset:Bool;
	public final samplerAnisotropy:Bool;
	public final independentBlend:Bool;
	public final depthClamp:Bool;
	public final fillModeNonSolid:Bool;
	public final multiDrawIndirect:Bool;
	public final drawIndirectFirstInstance:Bool;
	public final drawIndirectCount:Bool;
	public final occlusionQueryPrecise:Bool;
	public final graphicsQueueCompute:Bool;
	public final descriptorIndexing:Bool;
	public final shaderSampledImageArrayNonUniformIndexing:Bool;
	public final shaderStorageBufferArrayNonUniformIndexing:Bool;
	public final descriptorBindingPartiallyBound:Bool;
	public final descriptorBindingSampledImageUpdateAfterBind:Bool;
	public final descriptorBindingStorageBufferUpdateAfterBind:Bool;
	public final bindless:Bool;
	public final maxUpdateAfterBindDescriptorsInAllPools:Int;
	public final maxPerStageDescriptorUpdateAfterBindResources:Int;
	public final maxPerStageDescriptorUpdateAfterBindSamplers:Int;
	public final maxPerStageDescriptorUpdateAfterBindSampledImages:Int;
	public final maxPerStageDescriptorUpdateAfterBindStorageBuffers:Int;
	public final maxDescriptorSetUpdateAfterBindSamplers:Int;
	public final maxDescriptorSetUpdateAfterBindSampledImages:Int;
	public final maxDescriptorSetUpdateAfterBindStorageBuffers:Int;
	public final diagnostics:String;

	@:allow(limen.graphics.vulkan.Runtime)
	function new(context:VkContext) {
		final flags = context.getCapabilityFlags();
		deviceName = context.getDeviceName();
		apiVersion = context.getDeviceApiVersion();
		vendorId = context.getVendorId();
		deviceId = context.getDeviceId();
		driverVersion = context.getDriverVersion();
		graphicsQueueFamily = context.getGraphicsQueueFamily();
		presentQueueFamily = context.getPresentQueueFamily();
		computeQueueFamily = context.getComputeQueueFamily();
		transferQueueFamily = context.getTransferQueueFamily();
		timestampValidBits = context.getGraphicsTimestampValidBits();
		timestampPeriod = context.getTimestampPeriod();
		dynamicRendering = (flags & (1 << 0)) != 0;
		synchronization2 = (flags & (1 << 1)) != 0;
		timelineSemaphore = (flags & (1 << 2)) != 0;
		swapchainMaintenance1 = (flags & (1 << 3)) != 0;
		vulkan14 = (flags & (1 << 4)) != 0;
		portabilitySubset = (flags & (1 << 5)) != 0;
		samplerAnisotropy = (flags & SAMPLER_ANISOTROPY) != 0;
		independentBlend = (flags & INDEPENDENT_BLEND) != 0;
		depthClamp = (flags & DEPTH_CLAMP) != 0;
		fillModeNonSolid = (flags & FILL_MODE_NON_SOLID) != 0;
		multiDrawIndirect = (flags & MULTI_DRAW_INDIRECT) != 0;
		drawIndirectFirstInstance = (flags & DRAW_INDIRECT_FIRST_INSTANCE) != 0;
		drawIndirectCount = (flags & DRAW_INDIRECT_COUNT) != 0;
		occlusionQueryPrecise = (flags & OCCLUSION_QUERY_PRECISE) != 0;
		graphicsQueueCompute = (flags & GRAPHICS_QUEUE_COMPUTE) != 0;
		descriptorIndexing = (flags & DESCRIPTOR_INDEXING) != 0;
		shaderSampledImageArrayNonUniformIndexing = (flags & SAMPLED_IMAGE_NON_UNIFORM) != 0;
		shaderStorageBufferArrayNonUniformIndexing = (flags & STORAGE_BUFFER_NON_UNIFORM) != 0;
		descriptorBindingPartiallyBound = (flags & DESCRIPTOR_PARTIALLY_BOUND) != 0;
		descriptorBindingSampledImageUpdateAfterBind = (flags & SAMPLED_IMAGE_UPDATE_AFTER_BIND) != 0;
		descriptorBindingStorageBufferUpdateAfterBind = (flags & STORAGE_BUFFER_UPDATE_AFTER_BIND) != 0;
		bindless = descriptorIndexing
			&& shaderSampledImageArrayNonUniformIndexing
			&& shaderStorageBufferArrayNonUniformIndexing
			&& descriptorBindingPartiallyBound
			&& descriptorBindingSampledImageUpdateAfterBind
			&& descriptorBindingStorageBufferUpdateAfterBind;
		maxUpdateAfterBindDescriptorsInAllPools = context.getMaxUpdateAfterBindDescriptors();
		maxPerStageDescriptorUpdateAfterBindResources = context.getMaxPerStageUpdateAfterBindResources();
		maxPerStageDescriptorUpdateAfterBindSamplers = context.getMaxPerStageUpdateAfterBindSamplers();
		maxPerStageDescriptorUpdateAfterBindSampledImages = context.getMaxPerStageUpdateAfterBindSampledImages();
		maxPerStageDescriptorUpdateAfterBindStorageBuffers = context.getMaxPerStageUpdateAfterBindStorageBuffers();
		maxDescriptorSetUpdateAfterBindSamplers = context.getMaxUpdateAfterBindSamplers();
		maxDescriptorSetUpdateAfterBindSampledImages = context.getMaxUpdateAfterBindSampledImages();
		maxDescriptorSetUpdateAfterBindStorageBuffers = context.getMaxUpdateAfterBindStorageBuffers();
		diagnostics = @:privateAccess String.fromUTF8(context.getContextReport());
	}
}
