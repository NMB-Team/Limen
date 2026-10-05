# NVIDIA DLSS

`limen.graphics.postprocess.dlss.DLSS` integrates NVIDIA Streamline with Limen's
D3D12 device, factory, resources, resource states, and command list types.
The bundled Streamline headers are version 2.14.1.

Feature and result types live in the DLSS package. Upscaling settings are in
`dlss.upscaling`; frame tokens, matrices, vectors, and constants are in
`dlss.frame`; tagged resources are in `dlss.resource`. Frame generation,
Reflex, and latency markers have their own `framegen`, `reflex`, and `pcl` packages.

## Build

Enable `LIMEN_BUILD_DLSS=ON` in a Windows x64 build with D3D12 enabled.
Set `LIMEN_STREAMLINE_SDK_ROOT` to a compatible NVIDIA Streamline SDK directory.
CMake builds `dlss.limen` and copies these runtime files from the SDK's `bin/x64`
or `x64` directory beside the module:

- `sl.interposer.dll`
- `sl.common.dll`
- `sl.pcl.dll`
- `sl.reflex.dll`
- `sl.dlss.dll`
- `sl.dlss_g.dll`
- `nvngx_dlss.dll`
- `nvngx_dlssg.dll`

These DLLs are required by the current packaging configuration. Keep them beside
the application executable, where `DLSS.init()` loads `sl.interposer.dll`.
The Streamline integration loads its entry points dynamically and does not link
against a Streamline import library. Feature availability also depends on the
GPU, driver, and operating system.

## Usage

1. Select the D3D12 graphics driver and check `DLSS.isAvailable()`. This checks
   module availability; check hardware support separately after initialization.
2. Call `DLSS.init(showConsole, features, true)` before creating graphics
   interfaces, using a `hl.NativeArray<Int>` of the requested `DLSSFeature`
   values. Keep signature verification enabled for NVIDIA's signed runtime.
3. Register the native D3D12 device with `DLSS.setDevice()`. Use
   `DLSS.upgradeFactory()` and `DLSS.upgradeDevice()` for interfaces that require
   Streamline interception before creating the swapchain. Check each requested
   feature with `DLSS.isFeatureSupported(adapter, feature)`.
4. Fill `DLSSOptions`, query `DLSS.getOptimalSettings()` for the render resolution,
   and apply the settings with `DLSS.setOptions()`.
5. For each frame, obtain a token with `DLSS.getNewFrameToken()`, submit camera
   and motion-vector data with `DLSS.setConstants()`, and tag depth, motion
   vectors, input color, and output color with `DLSS.setTagForFrame()`. Supply
   a `hl.CArray<DLSSResource>` with the actual extents, D3D12 states, and lifetimes.
6. Call `DLSS.evaluateFeature(token, commandList, DLSSFeature.DLSS)` on the current
   command list. Rebind application descriptor heaps and compute state afterward.
7. Wait for outstanding GPU work, free feature resources with
   `DLSS.freeResources()`, and call `DLSS.shutdown()` before destroying the device.

Check integer results against `DLSSResult.Ok` (`0`). Initialization can also
return `-1` when the interposer cannot be found, loaded, or signature-verified.
The bindings use viewport `0` for options, constants, resource tags, evaluation,
and resource cleanup.

Use camera matrices, jitter offsets, motion-vector scaling, and depth conventions
matching the rendered inputs. Reset temporal history on the first frame and
following camera cuts. Keep tagged resources valid for their declared lifetimes.

## Frame generation and latency

Load `DLSSFeature.FRAMEGEN`, `DLSSFeature.REFLEX`, and `DLSSFeature.PCL` when using
frame generation. Configure Reflex with `DLSS.reflexSetOptions()`, submit PCL
markers around simulation, render submission, and presentation, and call
`DLSS.reflexSleep()` with the frame token as part of the frame pacing loop.
`DLSS.pclInitStats()` and `DLSS.pclPollPing()` support latency measurement.

Configure frame generation through `DLSS.dlssgSetOptions()` and inspect
`DLSS.dlssgGetState()` for status, minimum dimensions, and generation limits.
Tag the depth, motion vectors, and color/UI buffers required by the selected
frame-generation mode, keeping presentation inputs valid until present.
The swapchain must use Streamline interception, and frame generation requires
Reflex to be enabled. Disabling upscaling and disabling frame generation are
separate operations.

## License

[LICENSE_STREAMLINE](LICENSE_STREAMLINE) reproduces the upstream
[Streamline 2.14.1 license](https://github.com/NVIDIAGameWorks/Streamline/blob/v2.14.1/license.txt)
and is installed beside `dlss.limen`. The bundled source headers retain their
original NVIDIA copyright notices.

The Streamline source license does not replace the terms supplied with NVIDIA's
DLSS runtime binaries. Retain the runtime licenses and notices from the SDK
package when distributing those DLLs.
