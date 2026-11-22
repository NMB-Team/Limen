# Native Modules

CMake builds these modules into `limen.hdll` and the optional `.limen` binaries.
Haxe sources live in each module's `haxe/` classpath. The public package
names are documented in the [Haxe API guide](../docs/HAXE_API.md).

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

The Haxe runtime entry point, `limen.platform.Platform`, lives in `core`.
The rest of the `limen.platform` package lives in `platform`.

Each module keeps its native implementation in `native/` and any native tests
in `tests/`. Configure and build from the repository root using the existing
[build commands](../README.md#quick-build). The root CMake project resolves shared
dependencies and configures the modules. Each backend CMake file registers its
primitive sources with `limen_register_module()` even when its build option
is disabled so applications can still load the core HashLink proxies. Enabled
backends use `limen_add_module()` and declare their own build dependencies.

When adding a module's first Haxe source, add its `haxe/` directory to
[`workspace.hxml`](../workspace.hxml). The workspace and Haxelib development
mode share this list, and the packager checks it against the source tree.
