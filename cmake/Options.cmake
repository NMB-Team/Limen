set(LIMEN_WINDOWS_X64 OFF)
if(WIN32
	AND CMAKE_SIZEOF_VOID_P EQUAL 8
	AND NOT CMAKE_GENERATOR_PLATFORM MATCHES "^(ARM64|ARM64EC)$"
	AND NOT CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|aarch64)$"
)
	set(LIMEN_WINDOWS_X64 ON)
endif()

option(LIMEN_BUILD_OPENGL "Build opengl.limen." ON)
option(LIMEN_BUILD_VULKAN "Build vulkan.limen." ON)
option(LIMEN_BUILD_VMA "Build Vulkan Memory Allocator support." ${LIMEN_BUILD_VULKAN})
option(LIMEN_BUILD_SHADERC "Build shaderc support into vulkan.limen." ON)
option(LIMEN_BUILD_D3D11 "Build d3d11.limen." ${WIN32})
option(LIMEN_BUILD_D3D12 "Build d3d12.limen." ${LIMEN_WINDOWS_X64})
option(LIMEN_BUILD_D3D12MA "Build static AMD D3D12 Memory Allocator support." OFF)
option(LIMEN_BUILD_FSR "Build fsr.limen for enabled D3D12 and Vulkan backends." OFF)
option(LIMEN_BUILD_DLSS "Build dlss.limen for enabled Direct3D and Vulkan backends." OFF)
option(LIMEN_BUILD_AFTERMATH "Build NVIDIA Nsight Aftermath support into d3d12.limen." OFF)
option(LIMEN_BUILD_TESTS "Build Limen tests." OFF)

set(LIMEN_SDL3_SOURCE_DIR "" CACHE PATH "Optional SDL3 source tree; otherwise SDL3 is fetched by CMake.")
set(LIMEN_HASHLINK_ROOT "" CACHE PATH "Path to a HashLink source checkout.")
set(LIMEN_HASHLINK_LIBRARY "" CACHE FILEPATH "Path to the HashLink library for standalone builds.")
set(LIMEN_DXCOMPILER_LIBRARY "" CACHE FILEPATH "Path to the DirectX Shader Compiler import library.")
set(LIMEN_DXCOMPILER_RUNTIME_DLL "" CACHE FILEPATH "Path to dxcompiler.dll to package beside the Limen modules.")
set(LIMEN_DXIL_RUNTIME_DLL "" CACHE FILEPATH "Path to dxil.dll to package beside the Limen modules.")
set(LIMEN_FIDELITYFX_SOURCE_DIR "" CACHE PATH "Optional AMD FSR SDK 2.3.0 source tree; otherwise it is fetched by CMake.")
set(LIMEN_FIDELITYFX_TOOLS_DIR "" CACHE PATH "Optional directory containing FidelityFX_SC.exe, dxcompiler.dll, and dxil.dll for shader compilation.")
set(LIMEN_STREAMLINE_SDK_ROOT "" CACHE PATH "Path to the NVIDIA Streamline SDK.")
set(LIMEN_AFTERMATH_SDK_ROOT "" CACHE PATH "Path to the NVIDIA Nsight Aftermath SDK.")
set(LIMEN_AFTERMATH_LIBRARY "" CACHE FILEPATH "Path to the NVIDIA Nsight Aftermath import library.")
set(LIMEN_AFTERMATH_RUNTIME_DLL "" CACHE FILEPATH "Path to the NVIDIA Nsight Aftermath runtime DLL.")

set(LIMEN_FIDELITYFX_VULKAN_SOURCE_DIR "" CACHE PATH "Optional FidelityFX SDK 1.1.4 source tree for its Vulkan API and runtime.")

function(limen_validate_options)
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

	if(LIMEN_BUILD_VMA AND NOT LIMEN_BUILD_VULKAN)
		message(FATAL_ERROR "LIMEN_BUILD_VMA requires LIMEN_BUILD_VULKAN.")
	endif()

	if(LIMEN_BUILD_VULKAN AND NOT LIMEN_BUILD_SHADERC)
		message(FATAL_ERROR "LIMEN_BUILD_VULKAN requires LIMEN_BUILD_SHADERC because the Vulkan backend compiles shaders at runtime.")
	endif()
endfunction()
