# Haxe API

This directory contains LIMEN's public Haxe API. Applications import these
modules to create windows, process input and platform events, use system
services, and access the supported graphics APIs. The implementation calls
the native modules built from [`../backend`](../backend) through HashLink
`@:hlNative` bindings.

## What it uses

- **HashLink** as the target runtime and native foreign-function interface.
- **`limen.hdll`** for platform, window, display, input, cursor, clipboard,
  timing, and event functionality backed by SDL3.
- **Graphics modules** such as `opengl.limen`, `vulkan.limen`, `d3d11.limen`,
  and `d3d12.limen` for API-specific functionality.

## Layout

- `platform/` is the cross-platform application layer. It includes platform
  lifecycle, windows, surfaces, events, input, displays, cursors, and system
  utilities.
- `graphics/opengl/` provides OpenGL context creation and GL types.
- `graphics/vulkan/` provides Vulkan runtime, surface, device, resource,
  pipeline, and command types.
- `graphics/d3d11/` and `graphics/d3d12/` provide the Windows Direct3D APIs.
- `internal/` packages contain native declarations and are implementation
  details rather than application-facing APIs.

Use `limen.platform.Platform` to initialize and stop the platform layer, and
`limen.platform.Window` to create application windows. Choose a graphics
package only when the application needs that rendering backend. See the
repository root README for a usage example and build instructions.
