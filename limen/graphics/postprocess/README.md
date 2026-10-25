# GPU postprocessing

DLSS and FSR share `PostProcessDevice`, `TextureResource`, and `CommandBuffer`.
Their SDK-specific settings, camera constants, and result codes remain separate.
Native integrations live under `backend/src/graphics/postprocess`, independently
of the renderer implementations.

| Provider | D3D11 upscaling | D3D12 upscaling | Vulkan upscaling | Frame generation |
| --- | --- | --- | --- | --- |
| DLSS | Streamline | Streamline | Streamline | Existing D3D12 integration |
| FSR | Unsupported | Static SDK 2.3.0 | SDK 1.1.4 Vulkan runtime | Existing D3D12 integration |
| XeSS | Unavailable | Unavailable | Unavailable | Unavailable |

These integrations currently build on Windows x64. FSR requires MSVC.
`Upscaler.supportsBackend()` describes implemented API combinations;
`DLSS.isAvailable()` and `FSR.isAvailable()` additionally check the selected
backend against the installed native module. Query SDK feature support before use.

## Devices and commands

For D3D12, construct `new PostProcessDevice(D3D12, nativeDevice)`. Vulkan contexts
provide `context.getPostProcessDevice()`. D3D11 exposes
`D3D11Bindings.getPostProcessDevice()` and `getPostProcessCommands()`.
D3D12 command lists and Vulkan command buffers convert to `CommandBuffer` without
allocating wrappers. The device descriptor borrows native handles; it does not
retain or destroy the renderer's device.

## Textures

Use `TextureResource` for `DLSSResource.res` and the texture fields in
`FSRDispatchParams`. `state` contains the actual D3D12 resource state or Vulkan
image layout; D3D11 ignores it. FSR no longer takes separate `colorState`,
`depthState`, or other state fields for upscaling.

Vulkan textures must describe their image, dimensions, native format, mip count,
array layers, usage, and creation flags. DLSS also needs the image view and any
associated memory. Keep all native resources alive through GPU completion.
FSR accepts shader-read-only, general, and transfer layouts. Transition depth
inputs to `VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL` before dispatch. Its output
must have storage usage and be in `VK_IMAGE_LAYOUT_GENERAL`. Track the actual layouts around SDK calls, synchronize subsequent GPU commands,
and restore application pipeline state as required by the SDK.

## Vulkan DLSS initialization

1. Initialize Streamline with `DLSS.init(console, features, verifySignature, Vulkan)`.
2. Call `DLSS.getVulkanRequirements(features, requirements)` with a new
   `VulkanRequirements`, and check the result.
3. Pass those requirements to both `Vulkan.createSurface(window, validation,
   requirements)` and `Vulkan.createContext(surface, queueFamily,
   requiredCapabilities, requirements)`.
4. Register `context.getPostProcessDevice()` with `DLSS.setDevice()`, check each
   feature with `DLSS.isFeatureSupported(device, feature)`, and use the shared
   texture and command types for tagging and evaluation.

Device selection checks requested extensions, Vulkan 1.2/1.3 features, and queue
capacity. The renderer enables those features and reserves the requested extra
graphics/compute queues for Streamline. Supported FP16, storage-buffer, and
subgroup features used by the FSR Vulkan runtime are also enabled. Requirements that need optical-flow
queues are rejected: Vulkan frame-generation presentation hooks are not implemented.
Initialize before creating surfaces so required instance extensions can be enabled.

## XeSS integration boundary

`Upscaler.XeSS` reserves provider selection without advertising an implementation.
A XeSS adapter can consume the same device, command, and texture descriptors.
It still needs its own SDK context lifecycle, capability checks, settings, and
dispatch translation. No XeSS runtime or fake successful native entry points are
installed by this change.
