package limen.graphics.internal;

typedef Device = hl.Abstract<"dx_device">;
typedef Factory = hl.Abstract<"dx_factory">;
typedef SwapChain = hl.Abstract<"dx_swapchain">;

@:hlNative("limen", "d3d12_resource_")
abstract Dx12Resource(hl.Abstract<"dx_resource">) {
	public function release() {}

	public inline function setName(name:String) {
		set_name(@:privateAccess name.bytes);
	}

	@:noCompletion
	private function set_name(name:hl.Bytes) {}
}
