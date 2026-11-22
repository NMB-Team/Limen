set(_sources native/driver.cpp)
if(LIMEN_BUILD_D3D12MA)
	list(APPEND _sources native/memory_allocator.cpp)
endif()
list(APPEND _sources native/debug.cpp)
limen_register_module(d3d12 ${_sources})
if(NOT (LIMEN_WINDOWS_X64 AND LIMEN_BUILD_D3D12))
	return()
endif()

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
	)
endif()
if(NOT LIMEN_DXCOMPILER_RUNTIME_DLL)
	unset(LIMEN_DXCOMPILER_RUNTIME_DLL CACHE)
	find_file(LIMEN_DXCOMPILER_RUNTIME_DLL
		NAMES dxcompiler.dll
		HINTS ${_LIMEN_DXC_RUNTIME_HINTS}
	)
endif()
if(NOT LIMEN_DXIL_RUNTIME_DLL)
	unset(LIMEN_DXIL_RUNTIME_DLL CACHE)
	find_file(LIMEN_DXIL_RUNTIME_DLL
		NAMES dxil.dll
		HINTS ${_LIMEN_DXC_RUNTIME_HINTS}
	)
endif()

if(NOT LIMEN_DXCOMPILER_LIBRARY OR NOT LIMEN_DXCOMPILER_RUNTIME_DLL OR NOT LIMEN_DXIL_RUNTIME_DLL)
	FetchContent_Declare(limen_dxc
		URL https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.8.2505.1/dxc_2025_07_14.zip
		URL_HASH SHA256=9ad895a6b039e3a8f8c22a1009f866800b840a74b50db9218d13319e215ea8a4
		SOURCE_SUBDIR limen-unused
	)
	FetchContent_MakeAvailable(limen_dxc)
	set(LIMEN_DXC_PACKAGE_DIR "${limen_dxc_SOURCE_DIR}" CACHE INTERNAL "Fetched DXC package directory")

	if(NOT LIMEN_DXCOMPILER_LIBRARY)
		set(LIMEN_DXCOMPILER_LIBRARY "${limen_dxc_SOURCE_DIR}/lib/${_LIMEN_DXC_ARCH}/dxcompiler.lib" CACHE FILEPATH "DXC import library" FORCE)
	endif()
	if(NOT LIMEN_DXCOMPILER_RUNTIME_DLL)
		set(LIMEN_DXCOMPILER_RUNTIME_DLL "${limen_dxc_SOURCE_DIR}/bin/${_LIMEN_DXC_ARCH}/dxcompiler.dll" CACHE FILEPATH "DXC runtime" FORCE)
	endif()
	if(NOT LIMEN_DXIL_RUNTIME_DLL)
		set(LIMEN_DXIL_RUNTIME_DLL "${limen_dxc_SOURCE_DIR}/bin/${_LIMEN_DXC_ARCH}/dxil.dll" CACHE FILEPATH "DXIL runtime" FORCE)
	endif()
endif()

if(LIMEN_BUILD_AFTERMATH)
	if(_LIMEN_DXC_ARCH STREQUAL "arm64")
		message(FATAL_ERROR "NVIDIA Nsight Aftermath is not supported by the Windows ARM64 build.")
	endif()
	set(_LIMEN_AFTERMATH_ROOT_HINTS
		"${CMAKE_CURRENT_SOURCE_DIR}/native/include/aftermath"
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

limen_add_module(d3d12 ${_sources})
if(LIMEN_BUILD_D3D12MA)
	include(D3D12MA)
	limen_resolve_d3d12ma()
	target_compile_definitions(limen_d3d12 PRIVATE LIMEN_D3D12MA)
	target_link_libraries(limen_d3d12 PRIVATE limen_d3d12ma)
endif()
target_include_directories(limen_d3d12 PRIVATE
	"${LIMEN_SOURCE_DIR}/modules/platform/native"
)
if(LIMEN_DXC_PACKAGE_DIR)
	target_include_directories(limen_d3d12 PRIVATE "${LIMEN_DXC_PACKAGE_DIR}/inc")
	foreach(_license LLVM MIT MS)
		install(FILES "${LIMEN_DXC_PACKAGE_DIR}/LICENSE-${_license}.txt"
			DESTINATION "${LIMEN_HDLL_DESTINATION}" RENAME "LICENSE_DXC_${_license}.txt")
	endforeach()
endif()

target_link_libraries(limen_d3d12 PRIVATE libhl limen d3d12 dxgi "${LIMEN_DXCOMPILER_LIBRARY}")
if(LIMEN_BUILD_AFTERMATH)
	target_compile_definitions(limen_d3d12 PRIVATE LIMEN_AFTERMATH)
	target_include_directories(limen_d3d12 PRIVATE "${LIMEN_AFTERMATH_INCLUDE_DIR}")
	target_link_libraries(limen_d3d12 PRIVATE "${LIMEN_AFTERMATH_LIBRARY}")
endif()
set(_runtimes "${LIMEN_DXCOMPILER_RUNTIME_DLL}" "${LIMEN_DXIL_RUNTIME_DLL}")
if(LIMEN_BUILD_AFTERMATH)
	list(APPEND _runtimes "${LIMEN_AFTERMATH_RUNTIME_DLL}")
endif()
limen_stage_runtime(limen_d3d12 ${_runtimes})
