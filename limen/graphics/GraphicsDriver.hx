package limen.graphics;

enum abstract GraphicsDriver(Int) from Int to Int {
	final None = 0;
	final OpenGL = 1;
	final Vulkan = 2;
	final D3D11 = 3;
	final D3D12 = 4;
}
