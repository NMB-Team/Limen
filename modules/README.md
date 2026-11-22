# Native Modules

CMake builds these modules into `limen.hdll` and the optional `.limen` binaries.
The matching Haxe bindings live in [`limen/`](../limen).

| Module | Native responsibilities | Binary |
| --- | --- | --- |
| `core` | HashLink integration, runtime initialization, and module loading | `limen.hdll` |
| `platform` | SDL3, windows, input, events, displays, and system utilities | `limen.hdll` |
| `graphics/common` | Graphics driver selection and availability | `limen.hdll` |
| `graphics/opengl` | OpenGL contexts and rendering | `opengl.limen` |
| `graphics/vulkan` | Vulkan surfaces, rendering, shader compilation, and optional VMA | `vulkan.limen` |
| `graphics/d3d11` | Direct3D 11 rendering | `d3d11.limen` |
| `graphics/d3d12` | Direct3D 12 rendering, diagnostics, and optional D3D12MA | `d3d12.limen` |
| `graphics/metal` | Reserved for Metal | |
| `postprocess/common` | Shared post-processing types | |
| `postprocess/fsr` | AMD FidelityFX Super Resolution | `fsr.limen` |
| `postprocess/dlss` | NVIDIA Streamline DLSS | `dlss.limen` |

Each module keeps its native implementation in `native/` and any native tests
in `tests/`. Configure and build from the repository root using the existing
[build commands](../README.md#quick-build). The root CMake project selects modules,
generates HashLink proxies, and packages the binaries.
