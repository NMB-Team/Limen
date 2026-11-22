add_library(limen SHARED
	native/init.c
	native/module_loader.c
	"${_LIMEN_MODULE_PROXY_SOURCE}"
)
limen_set_native_library(limen limen .hdll)
if(MSVC)
	set_target_properties(limen PROPERTIES ARCHIVE_OUTPUT_NAME limen_core)
endif()
target_compile_definitions(limen PRIVATE LIMEN_PLATFORM_BUILD)
limen_enable_c23_nullptr(limen)
target_include_directories(limen PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native")
target_link_libraries(limen PRIVATE libhl)
