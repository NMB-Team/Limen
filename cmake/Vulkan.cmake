include(FetchContent)

function(limen_resolve_vulkan)
	set(VULKAN_HEADERS_ENABLE_TESTS OFF CACHE BOOL "" FORCE)
	set(VULKAN_HEADERS_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
	set(VULKAN_HEADERS_ENABLE_MODULE OFF CACHE BOOL "" FORCE)
	FetchContent_Declare(
		VulkanHeaders
		URL https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.4.367.tar.gz
		URL_HASH SHA256=0df7d58b5df617e0a6a17dec521af459206719f9c7cb12d05d09275597c16f70
		EXCLUDE_FROM_ALL
	)
	FetchContent_MakeAvailable(VulkanHeaders)

	find_package(Vulkan REQUIRED)

	set(SHADERC_SKIP_TESTS ON CACHE BOOL "" FORCE)
	set(SHADERC_SKIP_EXAMPLES ON CACHE BOOL "" FORCE)
	set(SHADERC_SKIP_EXECUTABLES ON CACHE BOOL "" FORCE)
	set(SHADERC_SKIP_INSTALL ON CACHE BOOL "" FORCE)
	set(SHADERC_SKIP_COPYRIGHT_CHECK ON CACHE BOOL "" FORCE)
	set(SHADERC_ENABLE_WGSL_OUTPUT OFF CACHE BOOL "" FORCE)
	set(SHADERC_ENABLE_WERROR_COMPILE OFF CACHE BOOL "" FORCE)
	set(SHADERC_ENABLE_SHARED_CRT ON CACHE BOOL "" FORCE)
	set(SPIRV_SKIP_TESTS ON CACHE BOOL "" FORCE)
	set(SPIRV_SKIP_EXECUTABLES ON CACHE BOOL "" FORCE)
	set(SKIP_SPIRV_TOOLS_INSTALL ON CACHE BOOL "" FORCE)
	set(ENABLE_GLSLANG_BINARIES OFF CACHE BOOL "" FORCE)
	set(ENABLE_SPVREMAPPER OFF CACHE BOOL "" FORCE)
	set(GLSLANG_TESTS OFF CACHE BOOL "" FORCE)
	set(GLSLANG_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)

	FetchContent_Declare(limen_glslang
		URL https://github.com/KhronosGroup/glslang/archive/refs/tags/16.6.0.tar.gz
		URL_HASH SHA256=9c09b901149c729df745057dafa815278aaa101b84d2b6e14f16a42de52f97f2
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_Declare(limen_spirv_headers
		URL https://github.com/KhronosGroup/SPIRV-Headers/archive/refs/tags/v1.202609.0.tar.gz
		URL_HASH SHA256=0bac674ba1fd0a0d969b9c539a58322d37cb890a8af13b71177a64534c03b473
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_Declare(limen_spirv_tools
		URL https://github.com/KhronosGroup/SPIRV-Tools/archive/refs/tags/v2026.4.tar.gz
		URL_HASH SHA256=92df4c377603f086c3d2a1eb2bd9b8f883a73ca890fb939d78a0cecdcc01686c
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_MakeAvailable(limen_glslang limen_spirv_headers limen_spirv_tools)

	set(SPIRV-Headers_SOURCE_DIR "${limen_spirv_headers_SOURCE_DIR}")
	set(spirv-tools_SOURCE_DIR "${limen_spirv_tools_SOURCE_DIR}")
	set(glslang_SOURCE_DIR "${limen_glslang_SOURCE_DIR}")
	add_subdirectory("${limen_spirv_tools_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/_deps/limen_spirv_tools-build" EXCLUDE_FROM_ALL)
	add_subdirectory("${limen_glslang_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/_deps/limen_glslang-build" EXCLUDE_FROM_ALL)

	set(SHADERC_GLSLANG_DIR "${limen_glslang_SOURCE_DIR}" CACHE PATH "" FORCE)
	set(SHADERC_SPIRV_HEADERS_DIR "${limen_spirv_headers_SOURCE_DIR}" CACHE PATH "" FORCE)
	set(SHADERC_SPIRV_TOOLS_DIR "${limen_spirv_tools_SOURCE_DIR}" CACHE PATH "" FORCE)
	FetchContent_Declare(limen_shaderc
		URL https://github.com/google/shaderc/archive/refs/tags/v2026.4.tar.gz
		URL_HASH SHA256=f06ce5bcca94e5df7f34e115743597d0ad2e13c5fe9213c67dc8c76031241947
		EXCLUDE_FROM_ALL
	)
	FetchContent_MakeAvailable(limen_shaderc)

	set_target_properties(shaderc_shared shaderc_combined PROPERTIES EXCLUDE_FROM_ALL TRUE)

	FetchContent_Declare(limen_spirv_reflect_source
		URL https://github.com/KhronosGroup/SPIRV-Reflect/archive/f3e261fda74ca81b44d1941931c6b7b5fe236d0e.tar.gz
		URL_HASH SHA256=86162ff30baa482389f601e1c378fbc085b2a890e6f64f2ff58dc028b4250fca
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_MakeAvailable(limen_spirv_reflect_source)
	add_library(limen_spirv_reflect STATIC
		"${limen_spirv_reflect_source_SOURCE_DIR}/spirv_reflect.c"
	)
	target_include_directories(limen_spirv_reflect PUBLIC
		"${limen_spirv_reflect_source_SOURCE_DIR}"
	)
	set_target_properties(limen_spirv_reflect PROPERTIES POSITION_INDEPENDENT_CODE ON)
endfunction()

function(limen_resolve_vma)
	FetchContent_Declare(limen_vma
		URL https://github.com/GPUOpen-LibrariesAndSDKs/VulkanMemoryAllocator/archive/refs/tags/v3.3.0.tar.gz
		URL_HASH SHA256=c4f6bbe6b5a45c2eb610ca9d231158e313086d5b1a40c9922cb42b597419b14e
		SOURCE_SUBDIR limen-unused
	)
	FetchContent_MakeAvailable(limen_vma)
	target_include_directories(limen_vulkan PRIVATE "${limen_vma_SOURCE_DIR}/include")
	install(FILES "${limen_vma_SOURCE_DIR}/LICENSE.txt"
		DESTINATION "${LIMEN_HDLL_DESTINATION}" RENAME LICENSE_VMA.txt)
endfunction()
