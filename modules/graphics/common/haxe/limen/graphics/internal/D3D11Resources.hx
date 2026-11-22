package limen.graphics.internal;

enum abstract MapType(Int) {
	final Read = 1;
	final Write = 2;
	final ReadWrite = 3;
	final WriteDiscard = 4;
	final WriteNoOverwrite = 5;
}

@:native("limen.graphics.renderer.d3d11.resource.ResourceBox")
class ResourceBox {
	public var left:Int;
	public var top:Int;
	public var front:Int;
	public var right:Int;
	public var bottom:Int;
	public var back:Int;

	public function new() {}

	public function reset() {
		left = top = front = right = bottom = back = 0;
	}
}

abstract Resource(hl.Abstract<"dx_resource">) {
	@:hlNative("limen", "d3d11_map")
	public function map(subResource:Int, type:MapType, waitGpu:Bool, pitch:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public inline function updateSubresource(subResource:Int, box:Null<ResourceBox>, data:hl.Bytes, srcRowPitch:Int, srcDepthPitch:Int):Void {
		dxUpdateSubresource(subResource, box, data, srcRowPitch, srcDepthPitch);
	}

	public inline function copySubresourceRegion(subResource:Int, dstX:Int, dstY:Int, dstZ:Int, src:Resource, srcSubResource:Int, srcBox:Null<ResourceBox>):Void {
		dxCopySubresourceRegion(subResource, dstX, dstY, dstZ, src, srcSubResource, srcBox);
	}

	@:hlNative("limen", "d3d11_copy_resource")
	public function copyResource(from:Resource) {}

	@:hlNative("limen", "d3d11_update_subresource")
	private function dxUpdateSubresource(subResource:Int, box:Dynamic, data:hl.Bytes, srcRowPitch:Int, srcDepthPitch:Int):Void {}

	@:hlNative("limen", "d3d11_copy_subresource_region")
	private function dxCopySubresourceRegion(subResource:Int, dstX:Int, dstY:Int, dstZ:Int, src:Resource, srcSubResource:Int, srcBox:Dynamic):Void {}

	@:hlNative("limen", "d3d11_unmap")
	public function unmap(subResource:Int):Void {}

	@:hlNative("limen", "d3d11_release_resource")
	public function release() {}
}
