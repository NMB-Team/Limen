package limen.graphics;

enum abstract GraphicsDriver(Int) from Int to Int {
	final None = 0;

	final OpenGL = 1;
	final Vulkan = 2;

	final D3D11 = 3;
	final D3D12 = 4;

	public function toString():String {
		return switch (this) {
			case None: "None";

			// khronos
			case OpenGL: "OpenGL";
			case Vulkan: "Vulkan";

			// direct3d
			case D3D11: "D3D11";
			case D3D12: "D3D12";

			default: 'Unknown($this)';
		}
	}
}
