include(FetchContent)

function(limen_resolve_d3d12ma)
	FetchContent_Declare(d3d12ma
		URL https://github.com/GPUOpen-LibrariesAndSDKs/D3D12MemoryAllocator/archive/refs/tags/v3.1.0.tar.gz
		URL_HASH SHA256=629aa00919f2f0f8cdfcdc485db5077f456e939e418cee148e17458efa055f63
		SOURCE_SUBDIR limen-unused
	)
	FetchContent_MakeAvailable(d3d12ma)
	add_library(limen_d3d12ma STATIC "${d3d12ma_SOURCE_DIR}/src/D3D12MemAlloc.cpp")
	target_include_directories(limen_d3d12ma PUBLIC "${d3d12ma_SOURCE_DIR}/include")
	target_link_libraries(limen_d3d12ma PUBLIC d3d12 dxgi)
	install(FILES "${d3d12ma_SOURCE_DIR}/LICENSE.txt"
		DESTINATION "${LIMEN_HDLL_DESTINATION}" RENAME LICENSE_D3D12MA.txt)
endfunction()
