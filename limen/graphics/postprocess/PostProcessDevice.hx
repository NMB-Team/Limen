package limen.graphics.postprocess;

import limen.graphics.GraphicsDriver;

@:struct
class PostProcessDevice {
	public var backend:GraphicsDriver;
	public var device:NativeHandle;
	public var instance:NativeHandle;
	public var physicalDevice:NativeHandle;
	public var graphicsQueueFamily:Int = 0;
	public var graphicsQueueIndex:Int = 0;
	public var computeQueueFamily:Int = 0;
	public var computeQueueIndex:Int = 0;

	public function new(backend:GraphicsDriver, device:NativeHandle) {
		this.backend = backend;
		this.device = device;
	}
}
