include(FetchContent)

function(limen_resolve_vulkan)
	set(VULKAN_HEADERS_ENABLE_TESTS OFF CACHE BOOL "" FORCE)
	set(VULKAN_HEADERS_ENABLE_INSTALL OFF CACHE BOOL "" FORCE)
	set(VULKAN_HEADERS_ENABLE_MODULE OFF CACHE BOOL "" FORCE)
	FetchContent_Declare(
		VulkanHeaders
		URL https://github.com/KhronosGroup/Vulkan-Headers/archive/refs/tags/v1.4.357.tar.gz
		URL_HASH SHA256=7dc0dbcf1d49dd3d7da3761c251c6097dfbaac475321a4a8a99269d3d5abecdc
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
		URL https://github.com/KhronosGroup/glslang/archive/168d452a4f460d24b588fed08477a81c44ee27a1.tar.gz
		URL_HASH SHA256=c167b2474af06cbab93abae8249efaf88fb79a09f30488e2a24d399e4258ce7a
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_Declare(limen_spirv_headers
		URL https://github.com/KhronosGroup/SPIRV-Headers/archive/29981f65241605e08b0ede4cfeb999fe3b723c6a.tar.gz
		URL_HASH SHA256=232899f1ad4104fb5bc377b94596c7621575eee62ad9a9e8f929b63a7dd8a7ad
		SOURCE_SUBDIR _limen_populate_only
	)
	FetchContent_Declare(limen_spirv_tools
		URL https://github.com/KhronosGroup/SPIRV-Tools/archive/b707790a898e44038547df54580022fc1cf89c3d.tar.gz
		URL_HASH SHA256=05d8af89737bde57571c48dbd36714c9f520a69623e14de72c3be6b600e277d6
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
		URL https://github.com/google/shaderc/archive/2c8cae778eec0283b44acbe7ed1a386865d78799.tar.gz # v2026.3
		URL_HASH SHA256=e6d6492a363cdef271e466f67cae3ad0d48f7e748491b8e2fe51424c08e391ad
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
