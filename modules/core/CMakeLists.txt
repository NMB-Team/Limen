add_library(limen SHARED
	native/module_loader.c
)
limen_set_native_library(limen limen .hdll)
if(MSVC)
	set_target_properties(limen PROPERTIES ARCHIVE_OUTPUT_NAME limen_core)
endif()
limen_enable_c23_nullptr(limen)
target_include_directories(limen PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native")
target_link_libraries(limen PRIVATE libhl)
