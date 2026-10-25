package limen.graphics.postprocess.fsr.framegen;

import limen.graphics.renderer.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.renderer.d3d12.resource.Resources.ResourceState;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.SwapChain;

@:struct
class FSRFrameGenPrepareParams {
	public var depth:Dx12Resource;
	public var motionVectors:Dx12Resource;
	public var depthState:ResourceState;
	public var motionVectorsState:ResourceState;
	public var renderWidth:Int;
	public var renderHeight:Int;
	public var jitterOffsetX:Single;
	public var jitterOffsetY:Single;
	public var motionVectorScaleX:Single;
	public var motionVectorScaleY:Single;
	public var frameTimeDelta:Single;
	public var cameraNear:Single;
	public var cameraFar:Single;
	public var cameraFovAngleVertical:Single;
	public var viewSpaceToMetersFactor:Single;
	public var cameraPositionX:Single;
	public var cameraPositionY:Single;
	public var cameraPositionZ:Single;
	public var cameraUpX:Single;
	public var cameraUpY:Single;
	public var cameraUpZ:Single;
	public var cameraRightX:Single;
	public var cameraRightY:Single;
	public var cameraRightZ:Single;
	public var cameraForwardX:Single;
	public var cameraForwardY:Single;
	public var cameraForwardZ:Single;
	public var frameID:Int;
	public var flags:Int;
	public var reset:Bool;
	public function new() {
	}
}
