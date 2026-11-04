# D3D12MA binding

Enable `LIMEN_BUILD_D3D12MA=ON` on Windows x64 with D3D12 enabled; default OFF.
D3D12MA 3.1.0 is archive-hash pinned and statically linked. Its MIT license is
installed beside the modules. Calls and device lifecycle operations are serialized
on the rendering thread.

`D3D12MemoryAllocator` creates opaque allocator/allocation handles. Creation writes
HRESULT and returns null on failure. Allocators belong to one device/adapter pair;
never reuse them after device recreation. Sizes use Int64. Statistics report block
counts/bytes and occupied allocations; querying traverses allocator data.

Allocation owns the resource COM reference (CreateResource uses IID_NULL/null).
`resource()` returns a borrowed pointer: never Release it or retain it beyond the
allocation. Release handles explicitly after GPU completion; GC does not release
GPU memory. Destroying an allocator or device with live handles fails. Closed
handles reject operations except idempotent release/destroy.

Transient aliases are limited to identical single-sample/mip/layer 2D color targets
on DEFAULT heaps. Each alias owns its resource reference and retains shared backing.
The caller supplies aliasing/transition barriers and fences. No defragmentation is exposed.

With LIMEN_BUILD_TESTS, run `limen_d3d12ma_test`: WARP allocation/mapping/statistics,
alias clear/readback, original-owner-first release and final COM reference checks.
The alias test requires the D3D12 debug layer.

[Pinned ownership contract](https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator/blob/v3.1.0/include/D3D12MemAlloc.h).
