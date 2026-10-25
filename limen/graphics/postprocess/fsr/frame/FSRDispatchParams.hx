package limen.graphics.postprocess.fsr.frame;

import limen.graphics.postprocess.TextureResource;

@:struct
class FSRDispatchParams {
	public var color:TextureResource;
	public var depth:TextureResource;
	public var motionVectors:TextureResource;
	public var exposure:TextureResource;
	public var reactive:TextureResource;
	public var transparencyAndComposition:TextureResource;
	public var output:TextureResource;
	public var jitterOffsetX:Single;
	public var jitterOffsetY:Single;
	public var motionVectorScaleX:Single;
	public var motionVectorScaleY:Single;
	public var renderWidth:Int;
	public var renderHeight:Int;
	public var upscaleWidth:Int;
	public var upscaleHeight:Int;
	public var sharpness:Single;
	public var frameTimeDelta:Single;
	public var preExposure:Single;
	public var cameraNear:Single;
	public var cameraFar:Single;
	public var cameraFovAngleVertical:Single;
	public var viewSpaceToMetersFactor:Single;
	public var flags:Int;
	public var enableSharpening:Bool;
	public var reset:Bool;

	public function new() {}
}
