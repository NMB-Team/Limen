#pragma once

typedef struct VulkanRequirements {
	varray* instanceExtensions;
	varray* deviceExtensions;
	vbyte* features12;
	vbyte* features13;
	uint32_t graphicsQueues;
	uint32_t computeQueues;
} VulkanRequirements;
