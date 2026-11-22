cmake_minimum_required(VERSION 3.24)

if(TARGET libhl)
	set(LIMEN_EMBEDDED ON)
else()
	project(limen LANGUAGES C CXX)
	set(LIMEN_EMBEDDED OFF)
endif()

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
	add_compile_options(
		$<$<CONFIG:Release>:/Oi>
		$<$<CONFIG:Release>:/Gy>
		$<$<CONFIG:Release>:/Ot>
		$<$<CONFIG:Release>:/Oy>
		$<$<CONFIG:Release>:/GT>
		$<$<CONFIG:Release>:/GS->
		$<$<CONFIG:Release>:/Zc:inline>
	)
	add_link_options(
		$<$<CONFIG:Release>:/OPT:REF>
		$<$<CONFIG:Release>:/OPT:ICF>
	)
endif()

set(LIMEN_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(LIMEN_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LIMEN_SOURCE_DIR}/cmake")

include(Options)
include(HashLink)
include(SDL3)
include(Hdll)
include(Vulkan)

limen_resolve_hashlink()
limen_resolve_sdl3()

function(limen_enable_c23_nullptr target)
	if(MSVC)
		target_compile_definitions("${target}" PRIVATE nullptr=0)
	endif()
endfunction()

set(_LIMEN_MODULE_PROXY_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/limen_module_proxies.c")
set(_LIMEN_MODULE_PROXY_CONTENT "#include \"module_loader.h\"\n")
set(_LIMEN_MODULE_PROXY_INPUTS
	opengl
		modules/graphics/opengl/native/context.c
		modules/graphics/opengl/native/gl.c
	vulkan
		modules/graphics/vulkan/native/surface.c
		modules/graphics/vulkan/native/vulkan.c
		modules/graphics/vulkan/native/shaderc.c
		modules/graphics/vulkan/native/spirv.c
	d3d11
		modules/graphics/d3d11/native/driver.cpp
	d3d12
		modules/graphics/d3d12/native/driver.cpp
		modules/graphics/d3d12/native/debug.cpp
	dlss
		modules/postprocess/dlss/native/dlss.cpp
	fsr
		modules/postprocess/fsr/native/fsr.cpp
		modules/postprocess/fsr/native/d3d12.cpp
)
if(LIMEN_BUILD_VMA)
	if(NOT LIMEN_BUILD_VULKAN)
		message(FATAL_ERROR "LIMEN_BUILD_VMA requires LIMEN_BUILD_VULKAN.")
	endif()
	list(FIND _LIMEN_MODULE_PROXY_INPUTS modules/graphics/vulkan/native/vulkan.c _LIMEN_VMA_PROXY_INDEX)
	list(INSERT _LIMEN_MODULE_PROXY_INPUTS ${_LIMEN_VMA_PROXY_INDEX} modules/graphics/vulkan/native/memory_allocator.cpp)
endif()
if(LIMEN_BUILD_D3D12MA)
	list(FIND _LIMEN_MODULE_PROXY_INPUTS modules/graphics/d3d12/native/debug.cpp _LIMEN_D3D12_PROXY_INDEX)
	list(INSERT _LIMEN_MODULE_PROXY_INPUTS ${_LIMEN_D3D12_PROXY_INDEX} modules/graphics/d3d12/native/memory_allocator.cpp)
endif()
set(_LIMEN_MODULE_PROXY_MODULE "")
foreach(_input IN LISTS _LIMEN_MODULE_PROXY_INPUTS)
	if(NOT _input MATCHES "\\.(c|cpp)$")
		set(_LIMEN_MODULE_PROXY_MODULE "${_input}")
		if(MSVC)
			set(_LIMEN_HLC_DEF_CONTENT_${_input} "LIBRARY ${_input}.limen\nEXPORTS\n")
		endif()
		continue()
	endif()
	set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${_input}")
	file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/${_input}" _primitive_lines REGEX "^[ \t]*DEFINE_PRIM\\(")
	foreach(_primitive_line IN LISTS _primitive_lines)
		string(REGEX REPLACE "^[ \t]*DEFINE_PRIM\\([^,]+,[ \t]*([A-Za-z0-9_]+).*$" "\\1" _primitive_name "${_primitive_line}")
		string(APPEND _LIMEN_MODULE_PROXY_CONTENT "LIMEN_MODULE_PROXY(${_LIMEN_MODULE_PROXY_MODULE}, ${_primitive_name})\n")
		if(MSVC)
			string(APPEND _LIMEN_HLC_DEF_CONTENT_${_LIMEN_MODULE_PROXY_MODULE}
				"\tlimen_${_LIMEN_MODULE_PROXY_MODULE}_${_primitive_name}\n"
			)
		endif()
	endforeach()
endforeach()
file(CONFIGURE OUTPUT "${_LIMEN_MODULE_PROXY_SOURCE}" CONTENT "${_LIMEN_MODULE_PROXY_CONTENT}" @ONLY)

if(MSVC)
	foreach(_module opengl vulkan d3d11 d3d12 dlss fsr)
		set(_LIMEN_HLC_DEF_${_module} "${CMAKE_CURRENT_BINARY_DIR}/limen_${_module}_hlc.def")
		file(CONFIGURE OUTPUT "${_LIMEN_HLC_DEF_${_module}}" CONTENT "${_LIMEN_HLC_DEF_CONTENT_${_module}}" @ONLY)
	endforeach()
endif()

add_subdirectory(modules/core)
add_subdirectory(modules/platform)
add_subdirectory(modules/graphics/common)
add_subdirectory(modules/graphics/metal)

if(LIMEN_BUILD_D3D12 AND NOT LIMEN_WINDOWS_X64)
	message(FATAL_ERROR "LIMEN_BUILD_D3D12 is supported only on Windows x64.")
endif()

if(LIMEN_BUILD_D3D12MA AND NOT (LIMEN_WINDOWS_X64 AND LIMEN_BUILD_D3D12))
	message(FATAL_ERROR "LIMEN_BUILD_D3D12MA requires Windows x64 and D3D12.")
endif()

if(LIMEN_BUILD_DLSS AND (NOT LIMEN_WINDOWS_X64 OR NOT (LIMEN_BUILD_D3D12 OR LIMEN_BUILD_D3D11 OR LIMEN_BUILD_VULKAN)))
	message(FATAL_ERROR "LIMEN_BUILD_DLSS requires Windows x64 and a D3D11, D3D12, or Vulkan backend.")
endif()

if(LIMEN_BUILD_FSR AND (NOT LIMEN_WINDOWS_X64 OR NOT (LIMEN_BUILD_D3D12 OR LIMEN_BUILD_VULKAN) OR NOT MSVC))
	message(FATAL_ERROR "LIMEN_BUILD_FSR requires Windows x64, MSVC, and a D3D12 or Vulkan backend.")
endif()

if(LIMEN_BUILD_VULKAN)
	if(NOT LIMEN_BUILD_SHADERC)
		message(FATAL_ERROR "LIMEN_BUILD_VULKAN requires LIMEN_BUILD_SHADERC because the Vulkan backend compiles shaders at runtime.")
	endif()
	limen_resolve_vulkan()
	target_compile_definitions(limen PRIVATE LIMEN_HAS_VULKAN)
	target_link_libraries(limen PRIVATE Vulkan::Headers)
endif()

if(LIMEN_BUILD_OPENGL)
	add_subdirectory(modules/graphics/opengl)
endif()

if(LIMEN_BUILD_VULKAN)
	add_subdirectory(modules/graphics/vulkan)
endif()

if(WIN32 AND LIMEN_BUILD_D3D11)
	add_subdirectory(modules/graphics/d3d11)
endif()

if(LIMEN_WINDOWS_X64 AND LIMEN_BUILD_D3D12)
	add_subdirectory(modules/graphics/d3d12)
endif()

if(LIMEN_BUILD_FSR)
	add_subdirectory(modules/postprocess/fsr)
endif()

if(LIMEN_BUILD_DLSS)
	add_subdirectory(modules/postprocess/dlss)
endif()

add_subdirectory(modules/postprocess/common)

set(_LIMEN_INSTALL_TARGETS limen)
foreach(_target limen_opengl limen_vulkan limen_d3d11 limen_d3d12 limen_dlss limen_fsr)
	if(TARGET ${_target})
		list(APPEND _LIMEN_INSTALL_TARGETS ${_target})
	endif()
endforeach()

if(MSVC)
	string(TOUPPER "${CMAKE_C_COMPILER_ARCHITECTURE_ID}" _LIMEN_MSVC_MACHINE)
	if(_LIMEN_MSVC_MACHINE STREQUAL "WIN32")
		set(_LIMEN_MSVC_MACHINE X86)
	elseif(NOT _LIMEN_MSVC_MACHINE)
		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			set(_LIMEN_MSVC_MACHINE X64)
		else()
			set(_LIMEN_MSVC_MACHINE X86)
		endif()
	endif()

	set(_LIMEN_IMPORT_LIBRARY_TARGETS limen)
	set(_LIMEN_IMPORT_LIBRARIES "$<TARGET_LINKER_FILE:limen>")
	foreach(_module opengl vulkan d3d11 d3d12 dlss fsr)
		set(_target limen_${_module})
		if(TARGET ${_target})
			set(_hlc_target ${_target}_hlc_import_library)
			set(_hlc_library "$<TARGET_LINKER_FILE_DIR:limen>/${_target}_hlc.lib")
			add_custom_target(${_hlc_target}
				COMMAND "${CMAKE_AR}" /NOLOGO
					"/DEF:${_LIMEN_HLC_DEF_${_module}}"
					"/OUT:${_hlc_library}"
					"/MACHINE:${_LIMEN_MSVC_MACHINE}"
				DEPENDS ${_target} "${_LIMEN_HLC_DEF_${_module}}"
				VERBATIM
			)
			list(APPEND _LIMEN_IMPORT_LIBRARY_TARGETS ${_hlc_target})
			list(APPEND _LIMEN_IMPORT_LIBRARIES "${_hlc_library}")
		endif()
	endforeach()

	add_custom_target(limen_import_library ALL
		COMMAND "${CMAKE_AR}" /NOLOGO /IGNORE:4006
			"/OUT:$<TARGET_LINKER_FILE_DIR:limen>/limen.lib"
			${_LIMEN_IMPORT_LIBRARIES}
		DEPENDS ${_LIMEN_IMPORT_LIBRARY_TARGETS}
		COMMAND_EXPAND_LISTS
		VERBATIM
	)
	install(
		FILES "$<TARGET_LINKER_FILE_DIR:limen>/limen.lib"
		DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
endif()

if(MSVC)
	install(
		TARGETS ${_LIMEN_INSTALL_TARGETS}
		RUNTIME DESTINATION "${LIMEN_HDLL_DESTINATION}"
		LIBRARY DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
else()
	install(
		TARGETS ${_LIMEN_INSTALL_TARGETS}
		RUNTIME DESTINATION "${LIMEN_HDLL_DESTINATION}"
		LIBRARY DESTINATION "${LIMEN_HDLL_DESTINATION}"
		ARCHIVE DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
endif()

if(LIMEN_BUILD_TESTS)
	target_compile_definitions(limen PRIVATE LIMEN_BUILD_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
