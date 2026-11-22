include(FetchContent)

function(limen_resolve_fidelityfx_vulkan sdk)
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
	set(${sdk} "${_sdk}" PARENT_SCOPE)
endfunction()
