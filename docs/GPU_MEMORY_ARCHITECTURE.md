# GPU memory

Vulkan uses VMA 3.5.0. D3D12MA 3.2.1 remains optional; D3D12 keeps its legacy default.
Dependencies are pinned in CMake. Aliasing is separately controlled; defragmentation
is not implemented. Resources must remain immovable because the renderer has no
relocation transaction for copies, descriptors, mappings and queue lifetimes.

## Build

- Vulkan: `LIMEN_BUILD_VMA` defaults to `LIMEN_BUILD_VULKAN`. Current heaps-nmb
  requires VMA. Existing caches set to OFF must be updated explicitly.
- D3D12: `LIMEN_BUILD_D3D12MA=ON` plus Heaps `gfx_d3d12ma`; Windows x64 only.
- OpenGL/D3D11 have no allocator dependency. FSR/DLSS remain independently optional.
- Deploy matching `limen.hdll` and backend modules. The core contains generated
  proxy exports; rebuilding a backend alone cannot add missing core exports.

## Ownership

Heaps owns GPU synchronization and deferred retirement. GC does not free GPU memory.
VMA owns memory; Heaps owns buffers/images and destroys them before their allocations.
D3D12MA allocations own resources; `resource()` returns a borrowed COM pointer.
Release allocation handles only after GPU completion. Destroy allocations before
allocators, and allocators before devices. Recreate handles after device replacement.
Swapchain/external resources and provider-internal FSR/DLSS allocations remain external.

Reserved block bytes, occupied allocation bytes and OS budget usage are different
metrics. Deferred releases remain live. Aliases share backing, so summing owner
sizes double-counts it. Statistics queries traverse allocator state; use diagnostically.

## Validation

Windows x64 / RTX 4070 Ti: native allocation tests passed. Vulkan full-buffer
upload/readback and shutdown passed three 2,048-frame runs with Khronos and
synchronization validation, without errors. The controlled Vulkan/D3D12 aliasing
samples passed readback checks. See Heaps `samples/GpuAllocatorComparison.md`
for measured allocator comparisons and limitations; no overall speedup is established.

Still unverified: forced OOM/device loss, hours-long streaming, non-coherent hardware
and the complete allocator/FSR/DLSS combination matrix. D3D12 small-buffer block
counts require investigation before changing its default.
