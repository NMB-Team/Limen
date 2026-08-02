# Native Backend

This directory contains LIMEN's native implementation. It connects the Haxe
API in [`../limen`](../limen) to HashLink, SDL3, and the supported graphics
APIs. CMake compiles these sources into `limen.hdll` and the optional
`.limen` graphics modules.

## What it uses

- **HashLink native API** to expose functions consumed by Haxe
  `@:hlNative` bindings.
- **SDL3** for application initialization, windows, displays, events, input,
  cursors, clipboard, drag-and-drop, and other platform services.
- **OpenGL, Vulkan, Direct3D 11, and Direct3D 12** for graphics-specific
  contexts, surfaces, devices, resources, and commands.
- **Optional integrations** such as shaderc, NVIDIA Nsight Aftermath, and
  NVIDIA Streamline DLSS when enabled by the corresponding CMake options.

## Layout

- `include/` contains bundled or project-level native headers.
- `src/core/` provides initialization, timing, and runtime configuration.
- `src/window/` implements windows, displays, cursors, clipboard, and
  drag-and-drop.
- `src/input/` translates SDL events and implements keyboard, mouse,
  joystick, and gamepad support.
- `src/platform/` contains shared native-window code and platform-specific
  behavior.
- `src/graphics/` implements the optional graphics modules.

Native functions must keep the names and signatures expected by the matching
bindings under `../limen`. The root `CMakeLists.txt` is the source of truth for
which files and dependencies belong to each native module.
