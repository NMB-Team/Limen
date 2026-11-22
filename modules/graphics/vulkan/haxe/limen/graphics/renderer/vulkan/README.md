# Limen Vulkan layer

This package is the Haxe/native Vulkan boundary owned by Limen. Vulkan 1.3 is preferred; Vulkan 1.2 devices require synchronization2, dynamic
rendering, copy commands2, and extended dynamic state 1/2 extensions. Shader
compilation targets Vulkan 1.2/SPIR-V 1.5 on fallback devices and Vulkan
1.3/SPIR-V 1.6 otherwise.

It exposes
instance, device, WSI, resource, descriptor, pipeline, query, command, and
synchronization primitives. Heaps rendering semantics, caches, resource-state
tracking, and deferred destruction remain in `heaps-nmb`.

Runtime code depends on the Vulkan loader and the shader compiler libraries
packaged with Limen. Validation layers and Vulkan SDK environment variables are
development dependencies only. Device-wide idle is reserved for deterministic
final shutdown; normal rendering and resource operations use fences,
semaphores, and Synchronization2 barriers.
