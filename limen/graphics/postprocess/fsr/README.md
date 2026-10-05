# AMD FSR

It uses Limen's D3D12 device, resources, resource states, and command list types.

Context, result, and debug types live in the FSR package. Quality and creation
flags are in `fsr.upscaling`; dispatch parameters and flags are in `fsr.frame`.

## Build

Enable `LIMEN_BUILD_FSR=ON` in a Windows x64 MSVC build with D3D12 enabled.
CMake fetches the pinned AMD FSR SDK 2.3.0 source and shader build tools, compiles
all shader permutations, and statically links the FSR 3.1.5 temporal upscaler and
DX12 backend into `fsr.limen`. No AMD FidelityFX runtime DLLs are required.
The newer ML providers are distributed by AMD as DLLs and are not included.

For an offline build, set `LIMEN_FIDELITYFX_SOURCE_DIR` to an SDK 2.3.0 checkout
and `LIMEN_FIDELITYFX_TOOLS_DIR` to the SDK 1.1.4 `sdk/tools/binary_store` directory
containing `FidelityFX_SC.exe`, `dxcompiler.dll`, and `dxil.dll`.
These tools are used during the build only. The private build copy disables AMD's
unpublished diagnostic overlay and optional AGS/PIX DLL tracing.

## Usage

1. Select the D3D12 graphics driver and check `FSR.isAvailable()`.
2. Call `FSR.init(device, FSRDebugLevel.ERRORS)` and check the result.
3. Call `FSR.getRenderResolution()` for the chosen `FSRQuality`, then create a
   context with the maximum render and output sizes. Check the returned result.
4. Fill `FSRDispatchParams` and call `FSR.dispatch()` on the current command list.
   Color, depth, motion vectors, and output are required; exposure, reactive, and
   transparency/composition masks are optional. Resource states must match the
   actual D3D12 states. The output must support unordered access.
5. Wait for outstanding GPU work before destroying a context or its resources.
   Destroy every context before `FSR.shutdown()`, which rejects live contexts.

Use pixel jitter offsets, the motion-vector scale matching the input encoding,
frame time in milliseconds, vertical field of view in radians, and camera planes
matching the depth convention. Set `preExposure` and `viewSpaceToMetersFactor`
to `1` when no other scaling applies. Reset temporal history on the first frame
and after camera cuts. Rebind application descriptor heaps and compute state
after dispatch; the SDK records its own state into the command list.

`FSR.getVersion(context)` returns the statically linked provider version.
The result and flag values match the upstream API. FSR 3 does not implement the
ML-specific nonlinear color and debug-visualization creation flags or the sRGB/PQ
dispatch flags; AMD's FSR 3 provider ignores these. Use linear input color.
