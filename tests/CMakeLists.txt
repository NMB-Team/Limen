find_program(LIMEN_HAXE_EXECUTABLE NAMES haxe)
find_program(LIMEN_HASHLINK_EXECUTABLE NAMES hl
	HINTS
		"${LIMEN_HASHLINK_ROOT}"
		"${LIMEN_HASHLINK_ROOT}/build"
		"${LIMEN_HASHLINK_ROOT}/build/bin"
)

add_subdirectory("${LIMEN_SOURCE_DIR}/modules/platform/tests" platform)

add_executable(limen_jobs_test jobs.cpp "${LIMEN_SOURCE_DIR}/modules/core/native/jobs.cpp")
target_include_directories(limen_jobs_test PRIVATE "${LIMEN_SOURCE_DIR}/modules/core/native")
target_link_libraries(limen_jobs_test PRIVATE Threads::Threads)
add_test(NAME limen_jobs COMMAND limen_jobs_test)
set_tests_properties(limen_jobs PROPERTIES LABELS core TIMEOUT 30)

add_executable(limen_world_culling_test world_culling.cpp "${LIMEN_SOURCE_DIR}/modules/core/native/jobs.cpp")
target_include_directories(limen_world_culling_test PRIVATE "${LIMEN_SOURCE_DIR}/modules/core/native")
target_link_libraries(limen_world_culling_test PRIVATE limen_world_culling Threads::Threads)
add_test(NAME limen_world_culling COMMAND limen_world_culling_test)
set_tests_properties(limen_world_culling PROPERTIES LABELS core TIMEOUT 30)

if(LIMEN_BUILD_VULKAN OR LIMEN_BUILD_D3D12)
	add_executable(limen_indexed_commands_test indexed_commands.c)
	target_link_libraries(limen_indexed_commands_test PRIVATE libhl)
	add_test(NAME limen_indexed_commands COMMAND limen_indexed_commands_test)
	set_tests_properties(limen_indexed_commands PROPERTIES LABELS graphics)
endif()

if(LIMEN_BUILD_OPENGL)
	add_subdirectory("${LIMEN_SOURCE_DIR}/modules/graphics/opengl/tests" opengl)
endif()
if(LIMEN_BUILD_VMA)
	add_subdirectory("${LIMEN_SOURCE_DIR}/modules/graphics/vulkan/tests" vulkan)
endif()
if(LIMEN_BUILD_D3D12MA)
	add_subdirectory("${LIMEN_SOURCE_DIR}/modules/graphics/d3d12/tests" d3d12)
endif()

if(LIMEN_BUILD_OPENGL)
	find_program(LIMEN_HAXELIB_EXECUTABLE NAMES haxelib)
	if(LIMEN_HAXE_EXECUTABLE AND LIMEN_HAXELIB_EXECUTABLE)
		execute_process(COMMAND "${LIMEN_HAXELIB_EXECUTABLE}" path heaps
			RESULT_VARIABLE _LIMEN_HEAPS_RESULT OUTPUT_QUIET ERROR_QUIET
		)
		if(_LIMEN_HEAPS_RESULT EQUAL 0)
			add_test(NAME limen_opengl_readback_lifecycle
				COMMAND "${LIMEN_HAXE_EXECUTABLE}" --cwd "${LIMEN_SOURCE_DIR}" workspace.hxml
					-lib heaps -cp "${CMAKE_CURRENT_SOURCE_DIR}"
					--run OpenGLReadbackTest
			)
			set_tests_properties(limen_opengl_readback_lifecycle PROPERTIES
				LABELS "opengl;integration"
				WORKING_DIRECTORY "${LIMEN_SOURCE_DIR}" TIMEOUT 45
			)
		endif()
	endif()
endif()

cmake_path(ABSOLUTE_PATH LIMEN_HDLL_DESTINATION BASE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}" NORMALIZE OUTPUT_VARIABLE _destination)
cmake_path(IS_PREFIX CMAKE_CURRENT_BINARY_DIR "${_destination}" NORMALIZE _relative_destination)
if(NOT IS_ABSOLUTE "${LIMEN_HDLL_DESTINATION}" AND _relative_destination)
	get_property(_modules DIRECTORY "${LIMEN_SOURCE_DIR}" PROPERTY LIMEN_NATIVE_MODULES)
	set(_enabled_modules)
	foreach(_module IN LISTS _modules)
		if(TARGET limen_${_module})
			list(APPEND _enabled_modules "${_module}")
		endif()
	endforeach()
	get_property(_runtimes DIRECTORY "${LIMEN_SOURCE_DIR}" PROPERTY LIMEN_RUNTIME_FILES)

	add_test(NAME limen_native_package
		COMMAND "${CMAKE_COMMAND}"
			"-DBUILD_DIR=${LIMEN_BINARY_DIR}"
			"-DCONFIG=$<CONFIG>"
			"-DDESTINATION=${LIMEN_HDLL_DESTINATION}"
			"-DMODULES=${_enabled_modules}"
			"-DRUNTIMES=${_runtimes}"
			"-DMSVC_PACKAGE=${MSVC}"
			-P "${CMAKE_CURRENT_SOURCE_DIR}/verify_native_package.cmake"
	)
	set_tests_properties(limen_native_package PROPERTIES LABELS "integration;platform;${_enabled_modules}")
endif()
