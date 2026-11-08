package limen.graphics.postprocess.dlss.resource;

import limen.graphics.postprocess.TextureResource;

@:keep @:struct
class DLSSResource {
	public var res:TextureResource;
	public var width:Int;
	public var height:Int;
	public var type:DLSSBufferType;
	public var lifecycle:DLSSResourceLifecycle;

	public function new() {}
}
