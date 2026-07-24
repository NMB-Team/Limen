cmake_minimum_required(VERSION 3.24)

if(TARGET libhl)
	set(LIMEN_EMBEDDED ON)
else()
	project(limen LANGUAGES C CXX)
	set(LIMEN_EMBEDDED OFF)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

include(Options)
include(HashLink)
include(SDL3)
include(Hdll)
include(Platform)

limen_resolve_hashlink()
limen_resolve_sdl3()

add_library(limen SHARED
	backend/core/hints.c
	backend/core/init.c
	backend/core/time.c
	backend/input/events.c
	backend/input/gamepad.c
	backend/input/joystick.c
	backend/input/keyboard.c
	backend/input/mouse.c
	backend/window/clipboard.c
	backend/window/cursor.c
	backend/window/display.c
	backend/window/dragdrop.c
	backend/window/window.c
	backend/platform/graphics.c
	${LIMEN_PLATFORM_SOURCES}
)
limen_set_hdll(limen limen)
target_compile_definitions(limen PRIVATE LIMEN_PLATFORM_BUILD)
target_include_directories(limen
	PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/include"
	PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/backend/platform"
)
target_link_libraries(limen PRIVATE libhl SDL3::SDL3-static ${LIMEN_PLATFORM_LIBRARIES})

if(LIMEN_BUILD_VULKAN)
	find_package(Vulkan REQUIRED)
	target_compile_definitions(limen PRIVATE LIMEN_HAS_VULKAN)
	target_include_directories(limen PRIVATE ${Vulkan_INCLUDE_DIRS})
	if(WIN32 AND NOT LIMEN_VULKAN_RUNTIME_DLL)
		unset(LIMEN_VULKAN_RUNTIME_DLL CACHE)
		find_file(LIMEN_VULKAN_RUNTIME_DLL
			NAMES vulkan-1.dll
			HINTS "$ENV{VULKAN_SDK}/Bin-ARM64" "$ENV{VULKAN_SDK}/Bin" "$ENV{WINDIR}/System32"
			REQUIRED
		)
	endif()
endif()

if(LIMEN_BUILD_OPENGL)
	add_library(limen_opengl SHARED
		backend/graphics/opengl/context.c
		backend/graphics/opengl/gl.c
	)
	limen_set_hdll(limen_opengl limen_opengl)
	target_include_directories(limen_opengl PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/platform"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/graphics/opengl"
	)
	if(WIN32 AND NOT MINGW)
		target_include_directories(limen_opengl PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/include/gl")
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
		backend/graphics/vulkan/surface.c
		backend/graphics/vulkan/vulkan.c
		backend/graphics/vulkan/shaderc.c
	)
	limen_set_hdll(limen_vulkan limen_vulkan)
	target_include_directories(limen_vulkan PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/platform"
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
	if(WIN32)
		add_custom_command(TARGET limen_vulkan POST_BUILD
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				"${LIMEN_VULKAN_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_vulkan>"
		)
		install(FILES "${LIMEN_VULKAN_RUNTIME_DLL}" DESTINATION "${LIMEN_HDLL_DESTINATION}")
	endif()
endif()

if(WIN32 AND LIMEN_BUILD_D3D11)
	add_library(limen_d3d11 SHARED backend/graphics/d3d11/driver.cpp)
	limen_set_hdll(limen_d3d11 limen_d3d11)
	target_include_directories(limen_d3d11 PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/platform"
	)
	target_link_libraries(limen_d3d11 PRIVATE libhl limen d3d11 dxgi d3dcompiler)
endif()

if(WIN32 AND LIMEN_BUILD_D3D12)
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
		"$ENV{VULKAN_SDK}/Bin-ARM64"
		"$ENV{VULKAN_SDK}/Bin"
	)
	set(_LIMEN_DXC_LIBRARY_HINTS
		"${CMAKE_SOURCE_DIR}/include/dx/lib/${_LIMEN_DXC_ARCH}"
		"${LIMEN_HASHLINK_ROOT}/include/dx/lib/${_LIMEN_DXC_ARCH}"
		"$ENV{VULKAN_SDK}/Lib-ARM64"
		"$ENV{VULKAN_SDK}/Lib"
	)
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

	add_library(limen_d3d12 SHARED
		backend/graphics/d3d12/driver.cpp
		backend/graphics/d3d12/debug.cpp
	)
	limen_set_hdll(limen_d3d12 limen_d3d12)
	target_include_directories(limen_d3d12 PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/include"
		"${CMAKE_CURRENT_SOURCE_DIR}/backend/platform"
	)
	target_link_libraries(limen_d3d12 PRIVATE libhl limen d3d12 dxgi "${LIMEN_DXCOMPILER_LIBRARY}")
	add_custom_command(TARGET limen_d3d12 POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${LIMEN_DXCOMPILER_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_d3d12>"
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${LIMEN_DXIL_RUNTIME_DLL}" "$<TARGET_FILE_DIR:limen_d3d12>"
	)
	install(
		FILES "${LIMEN_DXCOMPILER_RUNTIME_DLL}" "${LIMEN_DXIL_RUNTIME_DLL}"
		DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
endif()

set(_LIMEN_INSTALL_TARGETS limen)
foreach(_target limen_opengl limen_vulkan limen_d3d11 limen_d3d12)
	if(TARGET ${_target})
		list(APPEND _LIMEN_INSTALL_TARGETS ${_target})
	endif()
endforeach()

install(
	TARGETS ${_LIMEN_INSTALL_TARGETS}
	RUNTIME DESTINATION "${LIMEN_HDLL_DESTINATION}"
	LIBRARY DESTINATION "${LIMEN_HDLL_DESTINATION}"
)

if(LIMEN_BUILD_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
