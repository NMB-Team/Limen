include(FetchContent)

function(limen_enable_fsr_vulkan target)
	if(LIMEN_FIDELITYFX_VULKAN_SOURCE_DIR)
		set(_sdk "${LIMEN_FIDELITYFX_VULKAN_SOURCE_DIR}")
	else()
		FetchContent_Declare(limen_fidelityfx_vulkan
			URL https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/archive/c6efa6bf7f2027b3ec94f28578bb5965eabb9e55.tar.gz
			SOURCE_SUBDIR _limen_populate_only
		)
		FetchContent_MakeAvailable(limen_fidelityfx_vulkan)
		set(_sdk "${limen_fidelityfx_vulkan_SOURCE_DIR}")
	endif()
	set(_runtime "${_sdk}/PrebuiltSignedDLL/amd_fidelityfx_vk.dll")
	if(NOT EXISTS "${_sdk}/ffx-api/include/ffx_api/vk/ffx_api_vk.h" OR NOT EXISTS "${_runtime}")
		message(FATAL_ERROR "LIMEN_FIDELITYFX_VULKAN_SOURCE_DIR must contain FidelityFX SDK 1.1.4 with its Vulkan runtime.")
	endif()
	# Isolate the older Vulkan API headers from the current D3D12 SDK.
	add_library(limen_fsr_vulkan OBJECT "${CMAKE_CURRENT_SOURCE_DIR}/backend/src/graphics/postprocess/fsr/vulkan.cpp")
	target_include_directories(limen_fsr_vulkan PRIVATE "${_sdk}/ffx-api/include")
	target_compile_definitions(limen_fsr_vulkan PRIVATE LIMEN_POSTPROCESS_VULKAN)
	target_link_libraries(limen_fsr_vulkan PRIVATE libhl Vulkan::Headers)
	target_sources(${target} PRIVATE $<TARGET_OBJECTS:limen_fsr_vulkan>)
	target_compile_definitions(${target} PRIVATE LIMEN_POSTPROCESS_VULKAN)
	add_custom_command(TARGET ${target} POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_runtime}" "$<TARGET_FILE_DIR:${target}>"
	)
	install(FILES "${_runtime}" DESTINATION "${LIMEN_HDLL_DESTINATION}")
	install(FILES "${_sdk}/LICENSE.txt" DESTINATION "${LIMEN_HDLL_DESTINATION}" RENAME LICENSE_FIDELITYFX_VULKAN)
endfunction()
