package limen.graphics.postprocess.dlss.upscaling;

@:struct
class DLSSOptions {
	public var mode:DLSSMode;
	public var outputWidth:Int;
	public var outputHeight:Int;
	public var preset:DLSSPreset;
	public var colorBufferHDR:Bool;
	public var autoExposure:Bool;

	public function new() {}
}
