add_executable(limen_event_translation_test
	event_translation.c
	../backend/src/input/events.c
)
target_include_directories(limen_event_translation_test PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src"
)
target_link_libraries(limen_event_translation_test PRIVATE libhl SDL3::SDL3)

add_executable(limen_window_flags_test window_flags.c)
target_include_directories(limen_window_flags_test PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src"
)
target_link_libraries(limen_window_flags_test PRIVATE limen libhl SDL3::Headers)

set(_LIMEN_WINDOW_FLAG_TESTS limen_window_flags)
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
	list(APPEND _LIMEN_WINDOW_FLAG_TESTS limen_window_flags_haxe)
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
set_tests_properties(${_LIMEN_WINDOW_FLAG_TESTS} PROPERTIES
	ENVIRONMENT "SDL_VIDEODRIVER=dummy"
)
if(APPLE)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{DYLD_LIBRARY_PATH}"
	)
	set_tests_properties(${_LIMEN_WINDOW_FLAG_TESTS} PROPERTIES
		ENVIRONMENT "SDL_VIDEODRIVER=dummy;DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{DYLD_LIBRARY_PATH}"
	)
elseif(NOT WIN32)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "LD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{LD_LIBRARY_PATH}"
	)
	set_tests_properties(${_LIMEN_WINDOW_FLAG_TESTS} PROPERTIES
		ENVIRONMENT "SDL_VIDEODRIVER=dummy;LD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{LD_LIBRARY_PATH}"
	)
endif()
