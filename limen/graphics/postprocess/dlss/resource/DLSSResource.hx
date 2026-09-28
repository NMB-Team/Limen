package limen.graphics.postprocess.dlss.resource;

import limen.graphics.renderer.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.renderer.d3d12.resource.Resources.ResourceState;

@:struct
class DLSSResource {
	public var res:Dx12Resource;
	public var width:Int;
	public var height:Int;
	public var type:DLSSBufferType;
	public var state:ResourceState;
	public var lifecycle:DLSSResourceLifecycle;

	public function new() {}
}
