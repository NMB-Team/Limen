package limen.graphics.postprocess;

import limen.graphics.GraphicsDriver;

enum abstract Upscaler(Int) from Int to Int {
	final DLSS = 0;
	final FSR = 1;
	final XeSS = 2;

	public function supportsBackend(backend:GraphicsDriver):Bool {
		return switch (this) {
			case DLSS: backend == D3D11 || backend == D3D12 || backend == Vulkan;
			case FSR: backend == D3D12 || backend == Vulkan;
			case XeSS: false;
			default: false;
		}
	}
}
