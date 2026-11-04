# VMA binding

VMA 3.3.0 is archive-hash pinned; its MIT license installs as LICENSE_VMA.txt.
`LIMEN_BUILD_VMA` defaults to the Vulkan build option. Explicit OFF supports raw
API consumers, but current heaps-nmb requires ON. Cached OFF settings persist.

```powershell
cmake -S . -B build/windows-x64 -DLIMEN_BUILD_VMA=ON
cmake --build build/windows-x64 --config Release --target limen limen_vulkan
```

Deploy matching core/backend modules: proxies are exported by limen.hdll and
implemented by vulkan.limen. Missing vulkan_memory_* functions indicate a stale
or allocator-disabled module. Vulkan functions load against Limen's existing
instance/device and negotiated API version; budget support follows enabled extensions.

`VmaMemoryAllocator` exposes explicit allocation, binding, mapping, cache operations,
statistics and release through opaque handles. Failed binding leaves allocation
ownership with the caller. Sizes/offsets use Int64. Mapped pointers and cache ranges
are allocation-relative; each successful map requires an unmap. Synchronize GPU
access before CPU reads or release. Destroy VkBuffer/VkImage before unmapping and
releasing allocation memory. Never pass VMA memory to vkFreeMemory. Destroy all
allocations before allocator/context teardown; GC does not perform GPU cleanup.

Transient image backing uses CAN_ALIAS and isolated memory. The caller must create
alias-compatible images and provide barriers/lifetimes. Binding validates memory
type, size, alignment and required-dedicated restrictions. No relocation is exposed.

Build `limen_vma_memory_test` with LIMEN_BUILD_TESTS, then run:
`ctest --test-dir <build> -C Release -R limen_vma_memory --output-on-failure`.
The test uses Khronos validation when available; it does not submit rendering work.

[Pinned API](https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/blob/v3.3.0/include/vk_mem_alloc.h).
