package limen.graphics.postprocess.dlss.reflex;

@:struct
class ReflexStateInfo {
	public var lowLatencyAvailable:Int;
	public var latencyReportAvailable:Int;
	public var flashIndicatorDriverControlled:Int;
	public var statsWindowMessage:Int;

	public function new() {}
}
