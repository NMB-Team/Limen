add_library(limen_jobs OBJECT
	native/jobs.cpp
	native/jobs_bridge.cpp
	native/sprite_geometry.cpp
	native/dxt_jobs.cpp
	native/frustum_jobs.cpp
)
set_target_properties(limen_jobs PROPERTIES POSITION_INDEPENDENT_CODE ON)
target_link_libraries(limen_jobs PRIVATE libhl SDL3::SDL3-static Threads::Threads)
target_compile_options(limen_jobs PRIVATE
	$<$<CXX_COMPILER_ID:MSVC>:/fp:precise>
	$<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-ffp-contract=off>
)

add_library(limen SHARED native/module_loader.c)
limen_set_native_library(limen limen .hdll)
if(MSVC)
	set_target_properties(limen PROPERTIES ARCHIVE_OUTPUT_NAME limen_core)
endif()
limen_enable_c23_nullptr(limen)
target_include_directories(limen PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native")
target_link_libraries(limen PRIVATE libhl limen_jobs Threads::Threads)
