package limen.graphics.renderer.vulkan;

@:struct
class VulkanRequirements {
	public var instanceExtensions:hl.NativeArray<hl.Bytes>;
	public var deviceExtensions:hl.NativeArray<hl.Bytes>;
	public var features12:hl.Bytes;
	public var features13:hl.Bytes;
	public var graphicsQueues:Int = 0;
	public var computeQueues:Int = 0;

	public function new() {}
}
