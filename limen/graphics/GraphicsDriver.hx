package limen.graphics;

enum abstract GraphicsDriver(Int) from Int to Int {
	/**
		No graphics driver is selected or available.

		This value can be used when graphics rendering is disabled, unsupported,
		or before a rendering backend has been initialized.
	**/
	final None = 0;

	/**
		OpenGL graphics backend.

		Uses the OpenGL API for rendering. Availability and supported features
		depend on the platform, graphics driver, and OpenGL context version.
	**/
	final OpenGL = 1;

	/**
		Vulkan graphics backend.

		Uses the Vulkan API for explicit GPU control, resource management,
		synchronization, and command submission.

		Requires Vulkan support from both the operating system and graphics driver.
	**/
	final Vulkan = 2;

	/**
		Direct3D 11 graphics backend.

		Uses the Direct3D 11 API and is available on supported Microsoft platforms.
		It provides a higher-level rendering model compared to Direct3D 12.
	**/
	final D3D11 = 3;

	/**
		Direct3D 12 graphics backend.

		Uses the Direct3D 12 API and provides explicit control over GPU resources,
		synchronization, command queues, and memory management.

		Available on supported Microsoft platforms and compatible hardware.
	**/
	final D3D12 = 4;

	/**
		Metal graphics backend.

		Uses Apple's Metal API for GPU rendering and compute workloads.
		It is intended for supported Apple platforms such as macOS, iOS,
		iPadOS, and related operating systems.

		This value is reserved for the future Metal backend.
	**/
	final Metal = 5;

	/**
		Returns a human-readable name for this graphics driver.
		Unknown numeric values are returned in the form `Unknown(value)`.
	**/
	public function toString():String {
		return switch (this) {
			case None: "None";

			// khronos
			case OpenGL: "OpenGL";
			case Vulkan: "Vulkan";

			// direct3d
			case D3D11: "D3D11";
			case D3D12: "D3D12";

			// apple
			case Metal: "Metal";

			default: 'Unknown($this)';
		}
	}
}
