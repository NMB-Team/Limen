add_executable(limen_event_translation_test
	event_translation.c
	../backend/src/input/events.c
)
limen_enable_c23_nullptr(limen_event_translation_test)
target_include_directories(limen_event_translation_test PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src"
)
target_link_libraries(limen_event_translation_test PRIVATE libhl SDL3::SDL3)

add_executable(limen_window_flags_test window_flags.c)
limen_enable_c23_nullptr(limen_window_flags_test)
target_include_directories(limen_window_flags_test PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src"
)
target_link_libraries(limen_window_flags_test PRIVATE limen libhl SDL3::Headers)

set(_LIMEN_PLATFORM_TESTS limen_window_flags)
find_program(LIMEN_HAXE_EXECUTABLE NAMES haxe)
find_program(LIMEN_HASHLINK_EXECUTABLE NAMES hl
	HINTS
		"${LIMEN_HASHLINK_ROOT}"
		"${LIMEN_HASHLINK_ROOT}/build"
		"${LIMEN_HASHLINK_ROOT}/build/bin"
)
if(LIMEN_HAXE_EXECUTABLE AND LIMEN_HASHLINK_EXECUTABLE)
	set(_LIMEN_WINDOW_FLAGS_HL "${CMAKE_CURRENT_BINARY_DIR}/window_flags.hl")
	add_custom_command(
		OUTPUT "${_LIMEN_WINDOW_FLAGS_HL}"
		COMMAND "${LIMEN_HAXE_EXECUTABLE}"
			-cp "${CMAKE_CURRENT_SOURCE_DIR}/.."
			-cp "${CMAKE_CURRENT_SOURCE_DIR}"
			-main WindowFlagsTest
			-hl "${_LIMEN_WINDOW_FLAGS_HL}"
		DEPENDS
			WindowFlagsTest.hx
			../limen/platform/window/Window.hx
			../limen/platform/window/WindowFlags.hx
			../limen/platform/window/WindowOptions.hx
		VERBATIM
	)
	add_custom_target(limen_window_flags_haxe_test ALL
		DEPENDS "${_LIMEN_WINDOW_FLAGS_HL}"
	)
	add_dependencies(limen_window_flags_haxe_test limen)
	if(WIN32)
		set(_LIMEN_HASHLINK_TEST_COMMAND "$<TARGET_FILE_DIR:limen>/hl.exe")
	else()
		set(_LIMEN_HASHLINK_TEST_COMMAND "${LIMEN_HASHLINK_EXECUTABLE}")
	endif()
	add_test(NAME limen_window_flags_haxe
		COMMAND "${_LIMEN_HASHLINK_TEST_COMMAND}" "${_LIMEN_WINDOW_FLAGS_HL}"
	)
	set_tests_properties(limen_window_flags_haxe PROPERTIES
		WORKING_DIRECTORY "$<TARGET_FILE_DIR:limen>"
	)
	list(APPEND _LIMEN_PLATFORM_TESTS limen_window_flags_haxe)

	set(_LIMEN_INPUT_EVENTS_HL "${CMAKE_CURRENT_BINARY_DIR}/input_events.hl")
	add_custom_command(
		OUTPUT "${_LIMEN_INPUT_EVENTS_HL}"
		COMMAND "${LIMEN_HAXE_EXECUTABLE}"
			-cp "${CMAKE_CURRENT_SOURCE_DIR}/.."
			-cp "${CMAKE_CURRENT_SOURCE_DIR}"
			-main InputEventsTest
			-hl "${_LIMEN_INPUT_EVENTS_HL}"
		DEPENDS
			InputEventsTest.hx
			../limen/platform/event/Event.hx
			../limen/platform/event/EventType.hx
			../limen/platform/internal/SdlBindings.hx
			../limen/platform/input/touch/Touch.hx
			../limen/platform/input/touch/TouchDeviceType.hx
			../limen/platform/input/pen/Pen.hx
			../limen/platform/input/pen/PenDeviceType.hx
			../limen/platform/input/pen/PenAxis.hx
			../limen/platform/input/pen/PenInputFlags.hx
		VERBATIM
	)
	add_custom_target(limen_input_events_haxe_test ALL DEPENDS "${_LIMEN_INPUT_EVENTS_HL}")
	add_dependencies(limen_input_events_haxe_test limen_window_flags_haxe_test)
	add_test(NAME limen_input_events_haxe COMMAND "${_LIMEN_HASHLINK_TEST_COMMAND}" "${_LIMEN_INPUT_EVENTS_HL}")
	set_tests_properties(limen_input_events_haxe PROPERTIES
		WORKING_DIRECTORY "$<TARGET_FILE_DIR:limen>"
	)
	list(APPEND _LIMEN_PLATFORM_TESTS limen_input_events_haxe)
endif()

if(WIN32)
	get_target_property(_LIMEN_LIBHL_IMPORTED libhl IMPORTED)
	if(_LIMEN_LIBHL_IMPORTED)
		get_target_property(_LIMEN_LIBHL_LINK_LIBRARY libhl IMPORTED_LOCATION)
		get_filename_component(_LIMEN_LIBHL_DIRECTORY "${_LIMEN_LIBHL_LINK_LIBRARY}" DIRECTORY)
		unset(_LIMEN_LIBHL_RUNTIME CACHE)
		find_file(_LIMEN_LIBHL_RUNTIME
			NAMES libhl.dll hl.dll
			HINTS "${_LIMEN_LIBHL_DIRECTORY}"
			NO_DEFAULT_PATH
			REQUIRED
		)
	else()
		set(_LIMEN_LIBHL_RUNTIME "$<TARGET_FILE:libhl>")
	endif()
	add_custom_command(TARGET limen_event_translation_test POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${_LIMEN_LIBHL_RUNTIME}"
			"$<TARGET_FILE_DIR:limen_event_translation_test>"
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"$<TARGET_FILE:SDL3::SDL3>"
			"$<TARGET_FILE_DIR:limen_event_translation_test>"
	)
	add_custom_command(TARGET limen_window_flags_test POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"${_LIMEN_LIBHL_RUNTIME}"
			"$<TARGET_FILE_DIR:limen_window_flags_test>"
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different
			"$<TARGET_FILE:limen>"
			"$<TARGET_FILE_DIR:limen_window_flags_test>"
	)
	if(TARGET limen_window_flags_haxe_test)
		add_custom_command(TARGET limen_window_flags_haxe_test POST_BUILD
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				"${_LIMEN_LIBHL_RUNTIME}"
				"$<TARGET_FILE_DIR:limen>"
			COMMAND "${CMAKE_COMMAND}" -E copy_if_different
				"${LIMEN_HASHLINK_EXECUTABLE}"
				"$<TARGET_FILE_DIR:limen>/hl.exe"
		)
	endif()
endif()

add_test(NAME limen_event_translation COMMAND limen_event_translation_test)
add_test(NAME limen_window_flags COMMAND limen_window_flags_test)
set_tests_properties(${_LIMEN_PLATFORM_TESTS} PROPERTIES
	ENVIRONMENT "SDL_VIDEODRIVER=dummy"
)
if(APPLE)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{DYLD_LIBRARY_PATH}"
	)
	set_tests_properties(${_LIMEN_PLATFORM_TESTS} PROPERTIES
		ENVIRONMENT "SDL_VIDEODRIVER=dummy;DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{DYLD_LIBRARY_PATH}"
	)
elseif(NOT WIN32)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "LD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{LD_LIBRARY_PATH}"
	)
	set_tests_properties(${_LIMEN_PLATFORM_TESTS} PROPERTIES
		ENVIRONMENT "SDL_VIDEODRIVER=dummy;LD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{LD_LIBRARY_PATH}"
	)
endif()

if(LIMEN_BUILD_D3D12MA)
	add_executable(limen_d3d12ma_test d3d12ma.cpp ../backend/src/graphics/d3d12/memory_allocator.cpp)
	target_link_libraries(limen_d3d12ma_test PRIVATE libhl limen_d3d12ma)
	add_test(NAME limen_d3d12ma COMMAND limen_d3d12ma_test)
	set_tests_properties(limen_d3d12ma PROPERTIES
		ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:libhl>"
	)
endif()

if(LIMEN_BUILD_VMA)
	add_executable(limen_vma_memory_test vma_memory.cpp)
	get_target_property(_LIMEN_VMA_INCLUDES limen_vulkan INCLUDE_DIRECTORIES)
	target_include_directories(limen_vma_memory_test PRIVATE ${_LIMEN_VMA_INCLUDES})
	target_link_libraries(limen_vma_memory_test PRIVATE libhl Vulkan::Headers Vulkan::Vulkan)
	add_test(NAME limen_vma_memory COMMAND limen_vma_memory_test)
	if(WIN32)
		set_tests_properties(limen_vma_memory PROPERTIES
			SKIP_RETURN_CODE 77
		)
	endif()
endif()

if(LIMEN_BUILD_OPENGL AND WIN32 AND NOT MINGW)
	add_executable(limen_opengl_capabilities_test opengl_capabilities.c)
	limen_enable_c23_nullptr(limen_opengl_capabilities_test)
	target_include_directories(limen_opengl_capabilities_test PRIVATE
		"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src/platform"
		"${CMAKE_CURRENT_SOURCE_DIR}/../backend/include/gl"
	)
	target_link_libraries(limen_opengl_capabilities_test PRIVATE libhl opengl32)
	add_test(NAME limen_opengl_capabilities COMMAND limen_opengl_capabilities_test)
	set_tests_properties(limen_opengl_capabilities PROPERTIES
		ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:limen>"
	)
endif()

if(LIMEN_BUILD_OPENGL)
	find_program(LIMEN_HAXELIB_EXECUTABLE NAMES haxelib)
	if(LIMEN_HAXE_EXECUTABLE AND LIMEN_HAXELIB_EXECUTABLE)
		execute_process(COMMAND "${LIMEN_HAXELIB_EXECUTABLE}" path heaps
			RESULT_VARIABLE _LIMEN_HEAPS_RESULT OUTPUT_QUIET ERROR_QUIET
		)
		if(_LIMEN_HEAPS_RESULT EQUAL 0)
			add_test(NAME limen_opengl_readback_lifecycle
				COMMAND "${LIMEN_HAXE_EXECUTABLE}" -lib heaps
					-cp "${CMAKE_CURRENT_SOURCE_DIR}/.." -cp "${CMAKE_CURRENT_SOURCE_DIR}"
					--run OpenGLReadbackTest
			)
			set_tests_properties(limen_opengl_readback_lifecycle PROPERTIES
				WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/.." TIMEOUT 45
			)
		endif()
	endif()

	find_program(LIMEN_GLSLANG_VALIDATOR NAMES glslangValidator HINTS "$ENV{VULKAN_SDK}/Bin")
	if(LIMEN_HAXE_EXECUTABLE AND LIMEN_GLSLANG_VALIDATOR)
		add_test(NAME limen_opengl_validation_shaders
			COMMAND "${LIMEN_HAXE_EXECUTABLE}" -cp "${CMAKE_CURRENT_SOURCE_DIR}"
				--run OpenGLValidationTest
				"${CMAKE_CURRENT_SOURCE_DIR}/../limen/graphics/renderer/opengl/OpenGL.hx"
				"${LIMEN_GLSLANG_VALIDATOR}"
				"${CMAKE_CURRENT_BINARY_DIR}/opengl-validation"
		)
	endif()

	add_executable(limen_opengl_sdl_failures_test opengl_sdl_failures.c)
	limen_enable_c23_nullptr(limen_opengl_sdl_failures_test)
	target_include_directories(limen_opengl_sdl_failures_test PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/../backend/src/platform")
	target_link_libraries(limen_opengl_sdl_failures_test PRIVATE SDL3::SDL3-static)
	add_test(NAME limen_opengl_sdl_failures COMMAND limen_opengl_sdl_failures_test)
endif()
