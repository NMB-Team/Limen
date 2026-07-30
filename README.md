<div align=center>

<img src=".github/img/limen-logo.svg" width=300 />

# LIMEN
#### is the SDL3 platform and graphics integration for HashLink NMB.

SDL owns windows, displays, fullscreen state, input, cursors, clipboard,
drag-and-drop, and native event delivery. OpenGL, Vulkan, Direct3D 11, and
Direct3D 12 own GPU rendering only.

</div>

> [!IMPORTANT]
> This repository is the canonical implementation. HashLink embeds it through
> its `LIMEN_SOURCE_DIR` CMake option.

## Haxe API

The public API follows the native subsystem layout:

```haxe
import limen.platform.Platform;
import limen.platform.Window;
import limen.platform.event.Event;
import limen.platform.input.gamepad.Gamepad;

Platform.init();

final window = Window.create({
	title: "LIMEN",
	width: 1280,
	height: 720,
	resizable: true
});
final displays = limen.platform.display.Display.all();
final modes = limen.platform.display.Display.modes(displays[0].id);

final event = new Event();
while (Platform.pollEvent(event)) {
	// Handle the event.
}

window.destroy();
Platform.quit();
```

Platform types are grouped under `limen.platform.event`,
`limen.platform.cursor`, `limen.platform.input`, `limen.platform.display`,
and `limen.platform.system`.

Graphics backends own their context and device setup. For example, an OpenGL
window uses `Window.SDL_WINDOW_OPENGL` and
`limen.graphics.opengl.Context.create(window)`. D3D12 concepts live under
`limen.graphics.d3d12.command`, `descriptor`, `pipeline`, `query`, `resource`,
and `shader`. Vulkan follows the equivalent package structure.

The native build produces exactly:

```text
limen.hdll - Core of LIMEN
limen_opengl.hdll - GL driver (includes on all targets)
limen_vulkan.hdll - Vulkan driver (includes on all targets)
limen_d3d11.hdll - Direct3D 11 (includes on all windows targets)
limen_d3d12.hdll - Direct3D 12 (includes on WinX64 ONLY)
```

Windows build and install directories also contain the dynamically linked
runtime DLLs beside the modules:

Contains and using only by **Direct3D 12**

```text
dxcompiler.dll
dxil.dll
```

## Standalone build

```sh
cmake -S . -B build \
  -DLIMEN_HASHLINK_ROOT=/path/to/hashlink-nmb \
  -DLIMEN_BUILD_OPENGL=ON \
  -DLIMEN_BUILD_VULKAN=ON \
  -DLIMEN_BUILD_D3D11=ON \
  -DLIMEN_BUILD_D3D12=ON
cmake --build build
```

SDL3 is built statically by CMake. Set `LIMEN_SDL3_SOURCE_DIR` to use a local
SDL3 source tree instead of the pinned fetched release.

DLSS support is disabled by default and is not required to build or install
LIMEN. On Windows x64, set `LIMEN_BUILD_DLSS=ON` and
`LIMEN_STREAMLINE_SDK_ROOT` to build `limen_dlss.hdll`; the Streamline import
library and runtime DLLs are required only for that opt-in module.

CMake locates the DXC runtime DLLs from the Vulkan SDK or HashLink's
`include/dx` distribution. Their locations can be overridden with
`LIMEN_DXCOMPILER_RUNTIME_DLL` and `LIMEN_DXIL_RUNTIME_DLL`.

Set `LIMEN_BUILD_AFTERMATH=ON` to add NVIDIA Nsight Aftermath GPU crash
diagnostics to the D3D12 backend. Set `LIMEN_AFTERMATH_SDK_ROOT` to the SDK
root, or define `NSIGHT_AFTERMATH_SDK`; CMake links the matching x64 or x86
import library and packages its runtime DLL beside `limen_d3d12.hdll`. The
include directory, library, and runtime DLL can be overridden with
`LIMEN_AFTERMATH_INCLUDE_DIR`, `LIMEN_AFTERMATH_LIBRARY`, and
`LIMEN_AFTERMATH_RUNTIME_DLL`.

Enable `LIMEN_BUILD_TESTS` for the native event-translation tests.

## HashLink integration

HashLink NMB pins LIMEN as the `libs/limen` submodule and builds it directly
with CMake. To test changes without updating that pin, configure HashLink
against this checkout:

```sh
cmake -S /path/to/hashlink-nmb -B /path/to/hashlink-nmb/build \
  -DLIMEN_SOURCE_DIR=/path/to/Limen
```

After a LIMEN revision passes CI, update HashLink's `libs/limen` submodule.
The gitlink is the single source of truth for the pinned revision. HashLink's
manual `Pin LIMEN revision` workflow updates it after the integration matrix
succeeds.
