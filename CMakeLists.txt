cmake_minimum_required(VERSION 3.24)

if(TARGET libhl)
	set(LIMEN_EMBEDDED ON)
else()
	project(limen LANGUAGES C CXX)
	set(LIMEN_EMBEDDED OFF)
endif()

set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(Options)
include(HashLink)
include(SDL3)
include(Hdll)
include(Platform)

limen_resolve_hashlink()
limen_resolve_sdl3()

set(_LIMEN_MODULE_PROXY_SOURCE "${CMAKE_CURRENT_BINARY_DIR}/limen_module_proxies.c")
set(_LIMEN_MODULE_PROXY_CONTENT "#include \"module_loader.h\"\n")
set(_LIMEN_MODULE_PROXY_INPUTS
	opengl
		backend/src/graphics/opengl/context.c
		backend/src/graphics/opengl/gl.c
	vulkan
		backend/src/graphics/vulkan/surface.c
		backend/src/graphics/vulkan/vulkan.c
		backend/src/graphics/vulkan/shaderc.c
	d3d11
		backend/src/graphics/d3d11/driver.cpp
	d3d12
		backend/src/graphics/d3d12/driver.cpp
		backend/src/graphics/d3d12/debug.cpp
	dlss
		backend/src/graphics/d3d12/dlss.cpp
)
set(_LIMEN_MODULE_PROXY_MODULE "")
foreach(_input IN LISTS _LIMEN_MODULE_PROXY_INPUTS)
	if(NOT _input MATCHES "\\.(c|cpp)$")
		set(_LIMEN_MODULE_PROXY_MODULE "${_input}")
		continue()
	endif()
	set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/${_input}")
	file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/${_input}" _primitive_lines REGEX "^[ \t]*DEFINE_PRIM\\(")
	foreach(_primitive_line IN LISTS _primitive_lines)
		string(REGEX REPLACE "^[ \t]*DEFINE_PRIM\\([^,]+,[ \t]*([A-Za-z0-9_]+).*$" "\\1" _primitive_name "${_primitive_line}")
		string(APPEND _LIMEN_MODULE_PROXY_CONTENT "LIMEN_MODULE_PROXY(${_LIMEN_MODULE_PROXY_MODULE}, ${_primitive_name})\n")
	endforeach()
endforeach()
file(WRITE "${_LIMEN_MODULE_PROXY_SOURCE}" "${_LIMEN_MODULE_PROXY_CONTENT}")

add_library(limen SHARED
	backend/src/core/hints.c
	backend/src/core/init.c
	backend/src/core/graphics_driver.c
	backend/src/core/module_loader.c
	backend/src/core/time.c
	backend/src/input/events.c
	backend/src/input/gamepad.c
	backend/src/input/joystick.c
	backend/src/input/keyboard.c
	backend/src/input/mouse.c
	backend/src/window/clipboard.c
	backend/src/window/cursor.c
	backend/src/window/display.c
	backend/src/window/dragdrop.c
	backend/src/window/window.c
	backend/src/platform/graphics.c
	${LIMEN_PLATFORM_SOURCES}
	"${_LIMEN_MODULE_PROXY_SOURCE}"
)
limen_set_native_library(limen limen .hdll)
target_compile_definitions(limen PRIVATE LIMEN_PLATFORM_BUILD)
target_include_directories(limen
	PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/backend/include"
	PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/core"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/platform"
)
target_link_libraries(limen PRIVATE libhl SDL3::SDL3-static ${LIMEN_PLATFORM_LIBRARIES})

if(LIMEN_BUILD_D3D12 AND NOT LIMEN_WINDOWS_X64)
	message(FATAL_ERROR "LIMEN_BUILD_D3D12 is supported only on Windows x64.")
endif()

if(LIMEN_BUILD_DLSS AND (NOT LIMEN_WINDOWS_X64 OR NOT LIMEN_BUILD_D3D12))
	message(FATAL_ERROR "LIMEN_BUILD_DLSS requires the Windows x64 D3D12 backend.")
endif()

if(LIMEN_BUILD_VULKAN)
	find_package(Vulkan REQUIRED)
	target_compile_definitions(limen PRIVATE LIMEN_HAS_VULKAN)
	target_include_directories(limen PRIVATE ${Vulkan_INCLUDE_DIRS})
endif()

if(LIMEN_BUILD_OPENGL)
	add_library(limen_opengl SHARED
		backend/src/graphics/opengl/context.c
		backend/src/graphics/opengl/gl.c
	)
	limen_set_native_library(limen_opengl opengl .limen)
	target_include_directories(limen_opengl PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/platform"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/graphics/opengl"
	)
	if(WIN32 AND NOT MINGW)
		target_include_directories(limen_opengl PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/backend/include/gl")
	endif()
	target_link_libraries(limen_opengl PRIVATE libhl limen)
	if(APPLE)
		find_package(OpenGL REQUIRED)
		target_compile_definitions(limen_opengl PRIVATE GL_SILENCE_DEPRECATION)
		target_link_libraries(limen_opengl PRIVATE OpenGL::GL)
	elseif(WIN32)
		target_link_libraries(limen_opengl PRIVATE opengl32)
	elseif(ANDROID)
		target_link_libraries(limen_opengl PRIVATE GLESv3)
	else()
		find_package(OpenGL REQUIRED)
		target_link_libraries(limen_opengl PRIVATE OpenGL::GL)
	endif()
endif()

if(LIMEN_BUILD_VULKAN)
	add_library(limen_vulkan SHARED
		backend/src/graphics/vulkan/surface.c
		backend/src/graphics/vulkan/vulkan.c
		backend/src/graphics/vulkan/shaderc.c
	)
	limen_set_native_library(limen_vulkan vulkan .limen)
	target_include_directories(limen_vulkan PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/platform"
		${Vulkan_INCLUDE_DIRS}
	)
	target_link_libraries(limen_vulkan PRIVATE libhl limen Vulkan::Vulkan)

	if(LIMEN_BUILD_SHADERC)
		if(UNIX AND NOT APPLE)
			find_library(LIMEN_SHADERC_LIBRARY
				NAMES shaderc_shared shaderc
				REQUIRED
			)
			target_link_libraries(limen_vulkan PRIVATE "${LIMEN_SHADERC_LIBRARY}")
			get_filename_component(_LIMEN_SHADERC_RUNTIME "${LIMEN_SHADERC_LIBRARY}" REALPATH)
			install(FILES "${_LIMEN_SHADERC_RUNTIME}" DESTINATION "${LIMEN_HDLL_DESTINATION}")
		elseif(TARGET Vulkan::shaderc_combined)
			target_link_libraries(limen_vulkan PRIVATE Vulkan::shaderc_combined)
		else()
			if(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64)$")
				set(_LIMEN_VULKAN_LIB_SUFFIX Lib-ARM64)
			elseif(MSVC AND CMAKE_SIZEOF_VOID_P EQUAL 4)
				set(_LIMEN_VULKAN_LIB_SUFFIX Lib32)
			else()
				set(_LIMEN_VULKAN_LIB_SUFFIX Lib)
			endif()
			find_library(LIMEN_SHADERC_LIBRARY
				NAMES shaderc_combined
				HINTS "$ENV{VULKAN_SDK}"
				PATH_SUFFIXES ${_LIMEN_VULKAN_LIB_SUFFIX} lib
				REQUIRED
			)
			target_link_libraries(limen_vulkan PRIVATE "${LIMEN_SHADERC_LIBRARY}")
		endif()
		target_compile_definitions(limen_vulkan PRIVATE HL_VULKAN_HAS_SHADERC)
	endif()
endif()

if(WIN32 AND LIMEN_BUILD_D3D11)
	add_library(limen_d3d11 SHARED backend/src/graphics/d3d11/driver.cpp)
	limen_set_native_library(limen_d3d11 d3d11 .limen)
	target_include_directories(limen_d3d11 PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/platform"
	)
	target_link_libraries(limen_d3d11 PRIVATE libhl limen d3d11 dxgi d3dcompiler)
endif()

if(LIMEN_WINDOWS_X64 AND LIMEN_BUILD_D3D12)
	if(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64" OR CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64)$")
		set(_LIMEN_DXC_ARCH arm64)
	elseif(CMAKE_SIZEOF_VOID_P EQUAL 8)
		set(_LIMEN_DXC_ARCH x64)
	else()
		set(_LIMEN_DXC_ARCH x86)
	endif()
	set(_LIMEN_DXC_RUNTIME_HINTS
		"${CMAKE_SOURCE_DIR}/include/dx/bin/${_LIMEN_DXC_ARCH}"
		"${LIMEN_HASHLINK_ROOT}/include/dx/bin/${_LIMEN_DXC_ARCH}"
	)
	set(_LIMEN_DXC_LIBRARY_HINTS
		"${CMAKE_SOURCE_DIR}/include/dx/lib/${_LIMEN_DXC_ARCH}"
		"${LIMEN_HASHLINK_ROOT}/include/dx/lib/${_LIMEN_DXC_ARCH}"
	)
	if(_LIMEN_DXC_ARCH STREQUAL "arm64")
		list(APPEND _LIMEN_DXC_RUNTIME_HINTS "$ENV{VULKAN_SDK}/Bin-ARM64")
		list(APPEND _LIMEN_DXC_LIBRARY_HINTS "$ENV{VULKAN_SDK}/Lib-ARM64")
	else()
		list(APPEND _LIMEN_DXC_RUNTIME_HINTS "$ENV{VULKAN_SDK}/Bin")
		list(APPEND _LIMEN_DXC_LIBRARY_HINTS "$ENV{VULKAN_SDK}/Lib")
	endif()
	if(NOT LIMEN_DXCOMPILER_LIBRARY)
		unset(LIMEN_DXCOMPILER_LIBRARY CACHE)
		find_library(LIMEN_DXCOMPILER_LIBRARY
			NAMES dxcompiler
			HINTS ${_LIMEN_DXC_LIBRARY_HINTS}
			REQUIRED
		)
	endif()
	if(NOT LIMEN_DXCOMPILER_RUNTIME_DLL)
		unset(LIMEN_DXCOMPILER_RUNTIME_DLL CACHE)
		find_file(LIMEN_DXCOMPILER_RUNTIME_DLL
			NAMES dxcompiler.dll
			HINTS ${_LIMEN_DXC_RUNTIME_HINTS}
			REQUIRED
		)
	endif()
	if(NOT LIMEN_DXIL_RUNTIME_DLL)
		unset(LIMEN_DXIL_RUNTIME_DLL CACHE)
		find_file(LIMEN_DXIL_RUNTIME_DLL
			NAMES dxil.dll
			HINTS ${_LIMEN_DXC_RUNTIME_HINTS}
			REQUIRED
		)
	endif()

	if(LIMEN_BUILD_AFTERMATH)
		if(_LIMEN_DXC_ARCH STREQUAL "arm64")
			message(FATAL_ERROR "NVIDIA Nsight Aftermath is not supported by the Windows ARM64 build.")
		endif()
		set(_LIMEN_AFTERMATH_ROOT_HINTS
			"${CMAKE_CURRENT_SOURCE_DIR}/backend/include/aftermath"
			"${CMAKE_SOURCE_DIR}/include/aftermath"
		)
		if(LIMEN_HASHLINK_ROOT)
			list(APPEND _LIMEN_AFTERMATH_ROOT_HINTS "${LIMEN_HASHLINK_ROOT}/include/aftermath")
		endif()
		set(_LIMEN_AFTERMATH_INCLUDE_HINTS ${_LIMEN_AFTERMATH_ROOT_HINTS})
		if(LIMEN_AFTERMATH_SDK_ROOT)
			list(APPEND _LIMEN_AFTERMATH_ROOT_HINTS "${LIMEN_AFTERMATH_SDK_ROOT}")
			list(APPEND _LIMEN_AFTERMATH_INCLUDE_HINTS "${LIMEN_AFTERMATH_SDK_ROOT}/include")
		endif()
		if(DEFINED ENV{NSIGHT_AFTERMATH_SDK})
			list(APPEND _LIMEN_AFTERMATH_ROOT_HINTS "$ENV{NSIGHT_AFTERMATH_SDK}")
			list(APPEND _LIMEN_AFTERMATH_INCLUDE_HINTS "$ENV{NSIGHT_AFTERMATH_SDK}/include")
		endif()
		find_path(LIMEN_AFTERMATH_INCLUDE_DIR
			NAMES GFSDK_Aftermath.h
			HINTS ${_LIMEN_AFTERMATH_INCLUDE_HINTS}
			REQUIRED
		)
		if(_LIMEN_DXC_ARCH STREQUAL "x64")
			set(_LIMEN_AFTERMATH_LIBRARY_NAME GFSDK_Aftermath_Lib.x64)
		else()
			set(_LIMEN_AFTERMATH_LIBRARY_NAME GFSDK_Aftermath_Lib.x86)
		endif()
		if(NOT LIMEN_AFTERMATH_LIBRARY)
			unset(LIMEN_AFTERMATH_LIBRARY CACHE)
			find_library(LIMEN_AFTERMATH_LIBRARY
				NAMES ${_LIMEN_AFTERMATH_LIBRARY_NAME}
				HINTS ${_LIMEN_AFTERMATH_ROOT_HINTS}
				PATH_SUFFIXES "lib/${_LIMEN_DXC_ARCH}" ${_LIMEN_DXC_ARCH}
				REQUIRED
			)
		endif()
		if(NOT LIMEN_AFTERMATH_RUNTIME_DLL)
			unset(LIMEN_AFTERMATH_RUNTIME_DLL CACHE)
			find_file(LIMEN_AFTERMATH_RUNTIME_DLL
				NAMES "${_LIMEN_AFTERMATH_LIBRARY_NAME}.dll"
				HINTS ${_LIMEN_AFTERMATH_ROOT_HINTS}
				PATH_SUFFIXES "bin/${_LIMEN_DXC_ARCH}" "lib/${_LIMEN_DXC_ARCH}" ${_LIMEN_DXC_ARCH}
				REQUIRED
			)
		endif()
	endif()

	add_library(limen_d3d12 SHARED
		backend/src/graphics/d3d12/driver.cpp
		backend/src/graphics/d3d12/debug.cpp
	)
	limen_set_native_library(limen_d3d12 d3d12 .limen)
	target_include_directories(limen_d3d12 PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/platform"
	)
	target_link_libraries(limen_d3d12 PRIVATE libhl limen d3d12 dxgi "${LIMEN_DXCOMPILER_LIBRARY}")
	if(LIMEN_BUILD_AFTERMATH)
		target_compile_definitions(limen_d3d12 PRIVATE LIMEN_AFTERMATH)
		target_include_directories(limen_d3d12 PRIVATE "${LIMEN_AFTERMATH_INCLUDE_DIR}")
		target_link_libraries(limen_d3d12 PRIVATE "${LIMEN_AFTERMATH_LIBRARY}")
	endif()
	add_custom_command(TARGET limen_d3d12 POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${LIMEN_DXCOMPILER_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_d3d12>"
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${LIMEN_DXIL_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_d3d12>"
	)
	if(LIMEN_BUILD_AFTERMATH)
		add_custom_command(TARGET limen_d3d12 POST_BUILD
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				"${LIMEN_AFTERMATH_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_d3d12>"
		)
	endif()
	install(
		FILES "${LIMEN_DXCOMPILER_RUNTIME_DLL}" "${LIMEN_DXIL_RUNTIME_DLL}"
		DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
	if(LIMEN_BUILD_AFTERMATH)
		install(FILES "${LIMEN_AFTERMATH_RUNTIME_DLL}" DESTINATION "${LIMEN_HDLL_DESTINATION}")
	endif()

	if(LIMEN_BUILD_DLSS)
		if(NOT _LIMEN_DXC_ARCH STREQUAL "x64")
			message(FATAL_ERROR "NVIDIA Streamline DLSS is only supported by the Windows x64 build.")
		endif()
		set(_LIMEN_STREAMLINE_ROOT_HINTS
			"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/graphics/d3d12/streamline"
		)
		if(LIMEN_STREAMLINE_SDK_ROOT)
			list(APPEND _LIMEN_STREAMLINE_ROOT_HINTS "${LIMEN_STREAMLINE_SDK_ROOT}")
		endif()
		if(DEFINED ENV{STREAMLINE_SDK})
			list(APPEND _LIMEN_STREAMLINE_ROOT_HINTS "$ENV{STREAMLINE_SDK}")
		endif()
		if(NOT LIMEN_STREAMLINE_INTERPOSER_LIBRARY)
			unset(LIMEN_STREAMLINE_INTERPOSER_LIBRARY CACHE)
			find_library(LIMEN_STREAMLINE_INTERPOSER_LIBRARY
				NAMES sl.interposer
				HINTS ${_LIMEN_STREAMLINE_ROOT_HINTS}
				PATH_SUFFIXES lib/x64 x64
				REQUIRED
			)
		endif()
		get_filename_component(_LIMEN_STREAMLINE_LIBRARY_DIR
			"${LIMEN_STREAMLINE_INTERPOSER_LIBRARY}" DIRECTORY
		)
		get_filename_component(_LIMEN_STREAMLINE_LIBRARY_ROOT
			"${_LIMEN_STREAMLINE_LIBRARY_DIR}/../.." ABSOLUTE
		)
		list(APPEND _LIMEN_STREAMLINE_ROOT_HINTS "${_LIMEN_STREAMLINE_LIBRARY_ROOT}")
		set(_LIMEN_STREAMLINE_RUNTIME_FILES)
		foreach(_runtime_name
			sl.interposer.dll
			sl.common.dll
			sl.pcl.dll
			sl.dlss.dll
			nvngx_dlss.dll
		)
			string(MAKE_C_IDENTIFIER "${_runtime_name}" _runtime_id)
			find_file(_LIMEN_STREAMLINE_RUNTIME_${_runtime_id}
				NAMES "${_runtime_name}"
				HINTS ${_LIMEN_STREAMLINE_ROOT_HINTS}
				PATH_SUFFIXES bin/x64 x64
				REQUIRED
			)
			list(APPEND _LIMEN_STREAMLINE_RUNTIME_FILES
				"${_LIMEN_STREAMLINE_RUNTIME_${_runtime_id}}"
			)
		endforeach()

		add_library(limen_dlss SHARED backend/src/graphics/d3d12/dlss.cpp)
		limen_set_native_library(limen_dlss dlss .limen)
		target_compile_features(limen_dlss PRIVATE cxx_std_23)
		target_include_directories(limen_dlss PRIVATE
			"${CMAKE_CURRENT_SOURCE_DIR}/backend/src/graphics/d3d12/streamline"
		)
		target_link_libraries(limen_dlss PRIVATE
			libhl
			d3d12
			dxgi
			"${LIMEN_STREAMLINE_INTERPOSER_LIBRARY}"
		)
		add_dependencies(limen_dlss limen_d3d12)
		add_custom_command(TARGET limen_dlss POST_BUILD
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				${_LIMEN_STREAMLINE_RUNTIME_FILES} "$<TARGET_FILE_DIR:limen_dlss>"
		)
		install(FILES ${_LIMEN_STREAMLINE_RUNTIME_FILES} DESTINATION "${LIMEN_HDLL_DESTINATION}")
	endif()
endif()

set(_LIMEN_INSTALL_TARGETS limen)
foreach(_target limen_opengl limen_vulkan limen_d3d11 limen_d3d12 limen_dlss)
	if(TARGET ${_target})
		list(APPEND _LIMEN_INSTALL_TARGETS ${_target})
	endif()
endforeach()

install(
	TARGETS ${_LIMEN_INSTALL_TARGETS}
	RUNTIME DESTINATION "${LIMEN_HDLL_DESTINATION}"
	LIBRARY DESTINATION "${LIMEN_HDLL_DESTINATION}"
	ARCHIVE DESTINATION "${LIMEN_HDLL_DESTINATION}"
)

if(LIMEN_BUILD_TESTS)
	target_compile_definitions(limen PRIVATE LIMEN_BUILD_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
