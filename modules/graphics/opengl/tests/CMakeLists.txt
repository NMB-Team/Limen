if(WIN32 AND NOT MINGW)
	add_executable(limen_opengl_capabilities_test opengl_capabilities.c)
	limen_enable_c23_nullptr(limen_opengl_capabilities_test)
	target_include_directories(limen_opengl_capabilities_test PRIVATE
		"${LIMEN_SOURCE_DIR}/modules/platform/native"
		"${LIMEN_SOURCE_DIR}/modules/graphics/opengl/native/include"
	)
	target_link_libraries(limen_opengl_capabilities_test PRIVATE libhl opengl32)
	add_test(NAME limen_opengl_capabilities COMMAND limen_opengl_capabilities_test)
	set_tests_properties(limen_opengl_capabilities PROPERTIES
		LABELS opengl
		ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:limen>"
	)
endif()

find_program(LIMEN_GLSLANG_VALIDATOR NAMES glslangValidator HINTS "$ENV{VULKAN_SDK}/Bin")
if(LIMEN_HAXE_EXECUTABLE AND LIMEN_GLSLANG_VALIDATOR)
	add_test(NAME limen_opengl_validation_shaders
		COMMAND "${LIMEN_HAXE_EXECUTABLE}" -cp "${CMAKE_CURRENT_SOURCE_DIR}"
			--run OpenGLValidationTest
			"${LIMEN_SOURCE_DIR}/modules/graphics/opengl/src/limen/opengl/OpenGL.hx"
			"${LIMEN_GLSLANG_VALIDATOR}"
			"${CMAKE_CURRENT_BINARY_DIR}/opengl-validation"
	)
	set_tests_properties(limen_opengl_validation_shaders PROPERTIES LABELS opengl)
endif()

add_executable(limen_opengl_sdl_failures_test opengl_sdl_failures.c)
limen_enable_c23_nullptr(limen_opengl_sdl_failures_test)
target_include_directories(limen_opengl_sdl_failures_test PRIVATE "${LIMEN_SOURCE_DIR}/modules/platform/native")
target_link_libraries(limen_opengl_sdl_failures_test PRIVATE SDL3::SDL3-static)
add_test(NAME limen_opengl_sdl_failures COMMAND limen_opengl_sdl_failures_test)
set_tests_properties(limen_opengl_sdl_failures PROPERTIES LABELS opengl)
