package limen.graphics.vulkan.query;

import limen.graphics.vulkan.VulkanCore.NextPtr;
import limen.graphics.vulkan.VulkanCore.UnusedFlags;
import limen.graphics.vulkan.VulkanCore.VkStructureType;

abstract VkQueryPool(hl.Abstract<"vk_query_pool">) {}

enum abstract VkQueryType(Int) {
	final OCCLUSION = 0;
	final PIPELINE_STATISTICS = 1;
	final TIMESTAMP = 2;
}

enum VkQueryControlFlag {
	PRECISE;
}

enum VkQueryResultFlag {
	RESULT_64;
	WAIT;
	WITH_AVAILABILITY;
	PARTIAL;
}

@:struct class VkQueryPoolCreateInfo {
	var type:VkStructureType;
	var next:NextPtr;
	var flags:UnusedFlags;

	public var queryType:VkQueryType;
	public var queryCount:Int;
	public var pipelineStatistics:Int;

	public function new() {
		type = QUERY_POOL_CREATE_INFO;
	}
}
