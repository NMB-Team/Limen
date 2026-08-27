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
option(LIMEN_BUILD_SHADERC "Build shaderc support into vulkan.limen." ON)
option(LIMEN_BUILD_D3D11 "Build d3d11.limen." ${WIN32})
option(LIMEN_BUILD_D3D12 "Build d3d12.limen." ${LIMEN_WINDOWS_X64})
option(LIMEN_BUILD_DLSS "Build dlss.limen for the D3D12 backend." OFF)
option(LIMEN_BUILD_AFTERMATH "Build NVIDIA Nsight Aftermath support into d3d12.limen." OFF)
option(LIMEN_BUILD_TESTS "Build Limen tests." OFF)

set(LIMEN_SDL3_SOURCE_DIR "" CACHE PATH "Optional SDL3 source tree; otherwise SDL3 is fetched by CMake.")
set(LIMEN_HASHLINK_ROOT "" CACHE PATH "Path to a HashLink source checkout.")
set(LIMEN_HASHLINK_LIBRARY "" CACHE FILEPATH "Path to the HashLink library for standalone builds.")
set(LIMEN_DXCOMPILER_LIBRARY "" CACHE FILEPATH "Path to the DirectX Shader Compiler import library.")
set(LIMEN_DXCOMPILER_RUNTIME_DLL "" CACHE FILEPATH "Path to dxcompiler.dll to package beside the Limen modules.")
set(LIMEN_DXIL_RUNTIME_DLL "" CACHE FILEPATH "Path to dxil.dll to package beside the Limen modules.")
set(LIMEN_STREAMLINE_SDK_ROOT "" CACHE PATH "Path to the NVIDIA Streamline SDK.")
set(LIMEN_AFTERMATH_SDK_ROOT "" CACHE PATH "Path to the NVIDIA Nsight Aftermath SDK.")
set(LIMEN_AFTERMATH_LIBRARY "" CACHE FILEPATH "Path to the NVIDIA Nsight Aftermath import library.")
set(LIMEN_AFTERMATH_RUNTIME_DLL "" CACHE FILEPATH "Path to the NVIDIA Nsight Aftermath runtime DLL.")
