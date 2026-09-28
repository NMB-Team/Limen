# Limen Vulkan layer

This package is the Haxe/native Vulkan 1.3 boundary owned by Limen. It exposes
instance, device, WSI, resource, descriptor, pipeline, query, command, and
synchronization primitives. Heaps rendering semantics, caches, resource-state
tracking, and deferred destruction remain in `heaps-nmb`.

Runtime code depends on the Vulkan loader and the shader compiler libraries
packaged with Limen. Validation layers and Vulkan SDK environment variables are
development dependencies only. Device-wide idle is reserved for deterministic
final shutdown; normal rendering and resource operations use fences,
semaphores, and Synchronization2 barriers.
