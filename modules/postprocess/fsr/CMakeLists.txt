set(_sources native/fsr.cpp)
set(_d3d12_source native/d3d12.cpp)
limen_register_module(fsr ${_sources} "${_d3d12_source}")
if(NOT LIMEN_BUILD_FSR)
	return()
endif()

limen_add_module(fsr ${_sources})
target_link_libraries(limen_fsr PRIVATE libhl limen limen_postprocess_common)

if(LIMEN_BUILD_D3D12)
	include(FidelityFX)
	limen_resolve_fidelityfx()
	target_sources(limen_fsr PRIVATE "${_d3d12_source}")
	target_compile_definitions(limen_fsr PRIVATE LIMEN_POSTPROCESS_D3D12)
	target_include_directories(limen_fsr PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
	target_link_libraries(limen_fsr PRIVATE limen_fidelityfx d3d12 dxgi)
endif()

if(LIMEN_BUILD_VULKAN)
	include(FidelityFXVulkan)
	limen_resolve_fidelityfx_vulkan(_sdk)

	# isolate the older Vulkan API headers from the current D3D12 SDK
	add_library(limen_fsr_vulkan OBJECT native/vulkan.cpp)
	target_include_directories(limen_fsr_vulkan PRIVATE "${_sdk}/ffx-api/include")
	target_compile_definitions(limen_fsr_vulkan PRIVATE LIMEN_POSTPROCESS_VULKAN)
	target_link_libraries(limen_fsr_vulkan PRIVATE libhl Vulkan::Headers limen_postprocess_common)

	target_sources(limen_fsr PRIVATE $<TARGET_OBJECTS:limen_fsr_vulkan>)
	target_compile_definitions(limen_fsr PRIVATE LIMEN_POSTPROCESS_VULKAN)
	limen_stage_runtime(limen_fsr "${_sdk}/PrebuiltSignedDLL/amd_fidelityfx_vk.dll")
	install(FILES "${_sdk}/LICENSE.txt" DESTINATION "${LIMEN_HDLL_DESTINATION}" RENAME LICENSE_FIDELITYFX_VULKAN)
endif()
