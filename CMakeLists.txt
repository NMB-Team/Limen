cmake_minimum_required(VERSION 3.24)

if(TARGET libhl)
	set(LIMEN_EMBEDDED ON)
else()
	project(limen LANGUAGES C CXX)
	set(LIMEN_EMBEDDED OFF)
endif()

set(LIMEN_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(LIMEN_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LIMEN_SOURCE_DIR}/cmake")

include(Compiler)
include(Options)
include(HashLink)
include(SDL3)
include(Hdll)
include(NativeModules)

limen_validate_options()
limen_resolve_hashlink()
limen_resolve_sdl3()
if(LIMEN_BUILD_VULKAN)
	include(Vulkan)
	limen_resolve_vulkan()
endif()

add_subdirectory(modules/core)
add_subdirectory(modules/platform)
add_subdirectory(modules/graphics/common)
add_subdirectory(modules/postprocess/common)

# configure disabled backends too so their HashLink proxies remain available
add_subdirectory(modules/graphics/opengl)
add_subdirectory(modules/graphics/vulkan)
add_subdirectory(modules/graphics/d3d11)
add_subdirectory(modules/graphics/d3d12)
add_subdirectory(modules/graphics/metal)
add_subdirectory(modules/postprocess/dlss)
add_subdirectory(modules/postprocess/fsr)

limen_finalize_native_modules()

if(LIMEN_BUILD_TESTS)
	enable_testing()
	add_subdirectory(tests)
endif()
