set(_sources native/driver.cpp)
limen_register_module(d3d11 ${_sources})
if(NOT (WIN32 AND LIMEN_BUILD_D3D11))
	return()
endif()

limen_add_module(d3d11 ${_sources})
target_include_directories(limen_d3d11 PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
target_link_libraries(limen_d3d11 PRIVATE libhl limen d3d11 dxgi d3dcompiler limen_postprocess_common)
