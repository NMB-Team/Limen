add_library(limen_d3d11 SHARED native/driver.cpp)
limen_set_native_library(limen_d3d11 d3d11 .limen)
target_include_directories(limen_d3d11 PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
target_link_libraries(limen_d3d11 PRIVATE libhl limen d3d11 dxgi d3dcompiler)
