if(NOT LIMEN_BUILD_METAL)
	return()
endif()

enable_language(OBJC)
limen_register_module(metal native/metal_exports.m)
limen_add_module(metal native/metal.m)
target_compile_options(limen_metal PRIVATE -fobjc-arc)
target_include_directories(limen_metal PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
target_link_libraries(limen_metal PRIVATE libhl limen
	"-framework Foundation" "-framework Metal" "-framework QuartzCore")
