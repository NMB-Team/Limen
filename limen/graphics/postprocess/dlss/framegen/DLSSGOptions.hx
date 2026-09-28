package limen.graphics.postprocess.dlss.framegen;

@:struct
class DLSSGOptions {
	public var mode:DLSSGModeNative;
	public var numFramesToGenerate:Int;
	public var flags:Int;
	public var dynamicResWidth:Int;
	public var dynamicResHeight:Int;
	public var dynamicTargetFrameRate:Single;
	public var enableUserInterfaceRecomposition:Bool;

	public function new() {}
}
