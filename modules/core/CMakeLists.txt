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

add_library(limen_world_culling OBJECT
	native/world_culling_scalar.cpp
	native/world_culling_dispatch.cpp
)
set_target_properties(limen_world_culling PROPERTIES
	POSITION_INDEPENDENT_CODE ON
	INTERPROCEDURAL_OPTIMIZATION OFF
	INTERPROCEDURAL_OPTIMIZATION_RELEASE OFF
)
if(MSVC)
	target_compile_options(limen_world_culling PRIVATE /fp:precise)
	if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
		target_compile_options(limen_world_culling PRIVATE /clang:-ffp-contract=off)
	endif()
else()
	target_compile_options(limen_world_culling PRIVATE -ffp-contract=off)
endif()
if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(AMD64|amd64|x86_64|i.86|x86)$")
	target_compile_definitions(limen_world_culling PRIVATE LIMEN_CULL_X86)
	target_sources(limen_world_culling PRIVATE
		native/world_culling_sse2.cpp
		native/world_culling_avx2.cpp
		native/world_culling_avx512.cpp
	)
	if(MSVC)
		set_source_files_properties(native/world_culling_avx2.cpp PROPERTIES COMPILE_OPTIONS "/arch:AVX2")
		set_source_files_properties(native/world_culling_avx512.cpp PROPERTIES COMPILE_OPTIONS "/arch:AVX512")
		if(CMAKE_SIZEOF_VOID_P EQUAL 4)
			set_source_files_properties(native/world_culling_sse2.cpp PROPERTIES COMPILE_OPTIONS "/arch:SSE2")
		endif()
	else()
		set_source_files_properties(native/world_culling_sse2.cpp PROPERTIES COMPILE_OPTIONS "-msse2")
		set_source_files_properties(native/world_culling_avx2.cpp PROPERTIES COMPILE_OPTIONS "-mavx2")
		set_source_files_properties(native/world_culling_avx512.cpp PROPERTIES COMPILE_OPTIONS "-mavx512f")
	endif()
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(ARM64|arm64|aarch64)$")
	target_compile_definitions(limen_world_culling PRIVATE LIMEN_CULL_NEON)
	target_sources(limen_world_culling PRIVATE native/world_culling_neon.cpp)
endif()

add_library(limen SHARED native/module_loader.c)
limen_set_native_library(limen limen .hdll)
if(MSVC)
	set_target_properties(limen PROPERTIES ARCHIVE_OUTPUT_NAME limen_core)
endif()
limen_enable_c23_nullptr(limen)
target_include_directories(limen PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native")
target_link_libraries(limen PRIVATE libhl limen_jobs limen_world_culling Threads::Threads)
