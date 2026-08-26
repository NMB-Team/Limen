<div align=center>

<img src=".github/img/limen-logo.svg" width=300 />

# LIMEN
#### SDL3 platform and graphics integration for HashLink.

LIMEN provides windows, displays, fullscreen state, input, cursors, clipboard,
drag-and-drop and native event delivery through `SDL3`.

GPU rendering is provided separately by the `OpenGL`, `Vulkan`, `Direct3D 11` and `Direct3D 12` backends.

</div>

> [!IMPORTANT]
> This repository is the canonical implementation. HashLink embeds it through
> its `LIMEN_SOURCE_DIR` CMake option.

## Haxe API

The public API follows the native subsystem layout.

A window does not require a graphics backend. Use `GraphicsDriver.None` when
LIMEN is only needed for platform, window and input functionality:

```haxe
import limen.graphics.GraphicsDriver;
import limen.platform.Platform;
import limen.platform.window.Window;
import limen.platform.event.Event;
import limen.platform.event.EventType;

Platform.init(GraphicsDriver.None);

final window = Window.create({
	title: "LIMEN",
	width: 1280,
	height: 720,
	resizable: true
});

final event = new Event();
var running = true;

while (running) {
	while (Platform.pollEvent(event)) {
		switch (event.type) {
			case EventType.Quit:
				running = false;

			default:
		}
	}
}

window.destroy();
Platform.quit();
```

Platform types are grouped under
- `limen.platform.event`,
- `limen.platform.cursor`,
- `limen.platform.input`,
- `limen.platform.display`,
- `limen.platform.window`,
- `limen.platform.system`.

Graphics backends own their context and device setup.

For example, an OpenGL window uses `WindowFlags.SDL_WINDOW_OPENGL` and

```haxe
limen.graphics.opengl.Context.create(window)
```

D3D12 concepts live under
`limen.graphics.d3d12.command`, `descriptor`, `pipeline`, `query`, `resource`, and `shader`.

Vulkan follows the equivalent package structure.

The native build produces:

```text
limen.hdll   - Core platform, window, input and system module
opengl.limen - OpenGL graphics driver
vulkan.limen - Vulkan graphics driver
d3d11.limen  - Direct3D 11 graphics driver (Windows)
d3d12.limen  - Direct3D 12 graphics driver (Windows x64)
dlss.limen   - Optional DLSS integration for D3D12 (Windows x64)
```

##### `limen.hdll` is always required.

Graphics modules are only required when the application selects a graphics
backend. A platform-only application initialized with `GraphicsDriver.None`
only requires `limen.hdll`.

HashLink loads only `limen.hdll`. LIMEN loads backend modules itself and
resolves their HashLink primitives through the modules' existing `hlp_*`
exports, so no custom HashLink runtime support is required.

### Graphics driver selection

`Platform.init()` initializes LIMEN and selects a graphics backend. OpenGL is
preferred by default:

```haxe
Platform.init();
```

A different backend can be requested explicitly:

```haxe
Platform.init(GraphicsDriver.Vulkan);
```

Applications that only use LIMEN for windows, input, displays and other
platform functionality can disable graphics backend selection entirely:

```haxe
Platform.init(GraphicsDriver.None);
```

In platform-only mode, no graphics driver module is required and `Platform.graphicsDriver` remains `GraphicsDriver.None`.

When graphics are enabled, LIMEN attempts to select the requested backend and may fall back to another supported backend. The selected backend is exposed as `Platform.graphicsDriver`.

Applications that support only a specific set of renderers can provide that
set as the second argument:

```haxe
Platform.init(GraphicsDriver.OpenGL, [GraphicsDriver.OpenGL]);
```

Graphics-enabled initialization fails with
No LIMEN graphics driver was found when no supported graphics module can be
loaded.

`DLSS.isAvailable()` is true only when D3D12 is selected and
`dlss.limen` loads successfully.

Windows build and install directories also contain the dynamically linked
runtime DLLs beside the modules:

Contains and using only by **Direct3D 12**

```text
dxcompiler.dll
dxil.dll
```

## Examples

Small self-contained examples are available in [`examples/`](examples/).

#### Window

[`examples/window`](examples/window/) demonstrates the platform layer without
a graphics backend:

It uses:

```haxe
Platform.init(GraphicsDriver.None);
```

and only requires `limen.hdll`.

Build and run:

```sh
cd examples/window
haxe build-window.hxml
hl exwindow.hl
```

#### OpenGL

[examples/gl](examples/gl) demonstrates LIMEN's OpenGL integration with a
small interactive shader demo:

Build and run:

```sh
cd examples/gl
haxe build-gl.hxml
hl exgl.hl
```

The OpenGL example requires both `limen.hdll` and `opengl.limen`.

See [examples/README.md](examples/README.md) for more details

## Standalone build

```sh
cmake --preset "SEE CMakePresets.json" --fresh \
  -DLIMEN_HASHLINK_ROOT=/path/to/hashlink \
  -DLIMEN_HASHLINK_LIBRARY=/path/to/hashlink/compiled_dependencies/libhl.lib
cmake --build --preset "SEE CMakePresets.json"
```

SDL3 is built statically by CMake. Set `LIMEN_SDL3_SOURCE_DIR` to use a local
SDL3 source tree instead of the pinned fetched release.

DLSS support is disabled by default and is not required to build or install
LIMEN. On Windows x64, set `LIMEN_BUILD_DLSS=ON` and
`LIMEN_STREAMLINE_SDK_ROOT` to build `dlss.limen`; the Streamline import
library and runtime DLLs are required only for that opt-in module.

CMake locates the DXC runtime DLLs from the Vulkan SDK or HashLink's
`include/dx` distribution. Their locations can be overridden with
`LIMEN_DXCOMPILER_RUNTIME_DLL` and `LIMEN_DXIL_RUNTIME_DLL`.

Set `LIMEN_BUILD_AFTERMATH=ON` to add NVIDIA Nsight Aftermath GPU crash
diagnostics to the D3D12 backend. Set `LIMEN_AFTERMATH_SDK_ROOT` to the SDK
root, or define `NSIGHT_AFTERMATH_SDK`; CMake links the matching x64 or x86
import library and packages its runtime DLL beside `d3d12.limen`. The
include directory, library, and runtime DLL can be overridden with
`LIMEN_AFTERMATH_INCLUDE_DIR`, `LIMEN_AFTERMATH_LIBRARY`, and
`LIMEN_AFTERMATH_RUNTIME_DLL`.

Enable `LIMEN_BUILD_TESTS` for the native event-translation tests.