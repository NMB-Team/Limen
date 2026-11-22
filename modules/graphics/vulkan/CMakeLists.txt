add_library(limen_vulkan SHARED
	native/surface.c
	native/vulkan.c
	native/shaderc.c
	native/spirv.c
)
limen_set_native_library(limen_vulkan vulkan .limen)
if(LIMEN_BUILD_VMA)
	limen_resolve_vma()
	target_sources(limen_vulkan PRIVATE native/memory_allocator.cpp)
	target_compile_definitions(limen_vulkan PRIVATE LIMEN_VMA)
endif()
limen_enable_c23_nullptr(limen_vulkan)
target_include_directories(limen_vulkan PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
target_link_libraries(limen_vulkan PRIVATE
	libhl
	limen
	Vulkan::Headers
	Vulkan::Vulkan
	shaderc
	SPIRV-Tools-static
	limen_spirv_reflect
)
if(MINGW)
	target_link_options(limen_vulkan PRIVATE -static-libgcc -static-libstdc++)
endif()
target_compile_definitions(limen_vulkan PRIVATE HL_VULKAN_HAS_SHADERC HL_VULKAN_HAS_SPIRV_REFLECT HL_VULKAN_HAS_SPIRV_TOOLS)
