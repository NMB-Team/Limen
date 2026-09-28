package limen.graphics.postprocess.dlss.reflex;

@:struct
class ReflexFrameReport {
	public var frameID:Float;
	public var inputSampleTime:Float;
	public var simStartTime:Float;
	public var simEndTime:Float;
	public var renderSubmitStartTime:Float;
	public var renderSubmitEndTime:Float;
	public var presentStartTime:Float;
	public var presentEndTime:Float;
	public var driverStartTime:Float;
	public var driverEndTime:Float;
	public var osRenderQueueStartTime:Float;
	public var osRenderQueueEndTime:Float;
	public var gpuRenderStartTime:Float;
	public var gpuRenderEndTime:Float;
	public var cameraConstructedTime:Float;
	public var gpuActiveRenderTimeUs:Int;
	public var gpuFrameTimeUs:Int;
	public var crossAdapterCopyTimeUs:Int;

	public function new() {}
}
