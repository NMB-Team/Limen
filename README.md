# LIMEN

LIMEN is the SDL3 platform and graphics integration for HashLink NMB.

SDL owns windows, displays, fullscreen state, input, cursors, clipboard,
drag-and-drop, and native event delivery. OpenGL, Vulkan, Direct3D 11, and
Direct3D 12 own GPU rendering only.

This repository is the canonical implementation. HashLink embeds it through
its `LIMEN_SOURCE_DIR` CMake option.

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
limen.hdll
limen_opengl.hdll
limen_vulkan.hdll
limen_d3d11.hdll
limen_d3d12.hdll
```

Windows build and install directories also contain the dynamically linked
runtime DLLs beside the modules:

```text
vulkan-1.dll
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

CMake locates the Vulkan and DXC runtime DLLs from the Vulkan SDK, Windows,
or HashLink's `include/dx` distribution. Their locations can be overridden
with `LIMEN_VULKAN_RUNTIME_DLL`, `LIMEN_DXCOMPILER_RUNTIME_DLL`, and
`LIMEN_DXIL_RUNTIME_DLL`.

Enable `LIMEN_BUILD_TESTS` for the native event-translation tests.

## Embedded build

HashLink builds this directory directly by default. For local development
against a separate checkout, configure HashLink with:

```sh
cmake -S . -B build -DLIMEN_SOURCE_DIR=/path/to/limen
```

## Repository synchronization

After CI passes on `master`, `sync-hashlink.yml` dispatches the exact source
commit to `hashlink-nmb`. The source repository requires a
`HASHLINK_SYNC_TOKEN` secret with dispatch access. The HashLink repository
requires `LIMEN_SYNC_TOKEN` to read this repository and verify or update its
vendored snapshot.
