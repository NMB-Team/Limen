package limen.graphics.postprocess.dlss.framegen;

@:struct
class DLSSGStateInfo {
	public var status:Int;
	public var minWidthOrHeight:Int;
	public var numFramesActuallyPresented:Int;
	public var numFramesToGenerateMax:Int;
	public var dynamicMFGSupported:Int;
	public var vsyncSupportAvailable:Int;

	public function new() {}
}
