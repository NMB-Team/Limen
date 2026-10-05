package limen.graphics.postprocess.fsr.frame;

import limen.graphics.renderer.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.renderer.d3d12.resource.Resources.ResourceState;

@:struct
class FSRDispatchParams {
	public var color:Dx12Resource;
	public var depth:Dx12Resource;
	public var motionVectors:Dx12Resource;
	public var exposure:Dx12Resource;
	public var reactive:Dx12Resource;
	public var transparencyAndComposition:Dx12Resource;
	public var output:Dx12Resource;
	public var colorState:ResourceState;
	public var depthState:ResourceState;
	public var motionVectorsState:ResourceState;
	public var exposureState:ResourceState;
	public var reactiveState:ResourceState;
	public var transparencyAndCompositionState:ResourceState;
	public var outputState:ResourceState;
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
