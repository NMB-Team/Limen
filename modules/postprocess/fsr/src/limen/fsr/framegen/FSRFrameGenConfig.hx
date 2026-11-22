package limen.fsr.framegen;

import limen.d3d12.resource.Resources.Dx12Resource;
import limen.d3d12.Types.SwapChain;
import limen.d3d12.resource.Resources.ResourceState;

@:keep @:struct
class FSRFrameGenConfig {
	public var swapChain:SwapChain;
	public var hudless:Dx12Resource;
	public var hudlessState:ResourceState;
	public var flags:Int;
	public var rectX:Int;
	public var rectY:Int;
	public var rectWidth:Int;
	public var rectHeight:Int;
	public var frameID:Int;
	public var enabled:Bool;
	public var allowAsyncWorkloads:Bool;
	public var onlyPresentGenerated:Bool;
	public function new() {
	}
}
