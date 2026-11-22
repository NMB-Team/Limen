# Haxe API

Each [module](../modules/README.md) owns its Haxe bindings in `src/limen/`.
To use the checkout in another project, run `haxelib dev limen /path/to/limen`
and compile with `-lib limen`. This loads the module classpaths listed in
[`workspace.hxml`](../workspace.hxml).

## What it uses

- **HashLink** as the target runtime and native foreign-function interface.
- **`limen.hdll`** for platform, window, display, input, cursor, clipboard,
  timing, and event functionality backed by SDL3.
- **Graphics modules** such as `opengl.limen`, `vulkan.limen`, `d3d11.limen`,
  and `d3d12.limen` for API-specific functionality.

## Layout

- `limen.Platform` initializes and shuts down the platform layer using a
  `limen.GraphicsDriver`. Use `limen.Window` to create windows and `limen.Event`
  with `limen.EventType` to handle events.
- `limen.window`, `limen.input`, `limen.display`, `limen.cursor`, and
  `limen.system` expose related types and functions.
- `limen.opengl` provides OpenGL context creation and GL types.
- `limen.vulkan` provides Vulkan runtime and surface setup, a public
  `limen.vulkan.Context`, and types grouped by Vulkan subsystem.
- `limen.d3d11` and `limen.d3d12` provide the Windows Direct3D APIs.
- `limen.fsr` and `limen.dlss` expose the optional
  upscalers and share descriptors under `limen.postprocess`.
- `internal` packages contain low-level native declarations.

See the [repository README](../README.md) for usage examples and build instructions.

## Window icons

`Window.setIcon(surface)` accepts surfaces with alternate images. Use
`Surface.addAlternateImage(image)` to attach a copied image; the caller can free
the source image afterward.

`Surface.fromICO(bytes)` decodes ICO bitmap and PNG frames using `format` and
returns an owned surface containing every resolution. Free it after calling
`Window.setIcon(surface)`. `Window.setIconICO(bytes)` and `Window.setIconFile(path)`
load ICO data and release the temporary surfaces. The file method expects ICO.

With Heaps on HashLink/Limen, `hxd.Window` exposes `setIconICO(bytes)` and
`setIconFile(path)`. `-D windowIcon=path/to/icon.ico` embeds the ICO at compile
time and applies it when the default window is created.
