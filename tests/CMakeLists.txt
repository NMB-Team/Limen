add_executable(limen_event_translation_test
	event_translation.c
	../backend/src/input/events.c
)
target_include_directories(limen_event_translation_test PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/../backend/src"
)
target_link_libraries(limen_event_translation_test PRIVATE libhl SDL3::SDL3)

if(WIN32)
	get_target_property(_LIMEN_LIBHL_IMPORTED libhl IMPORTED)
	if(_LIMEN_LIBHL_IMPORTED)
		get_target_property(_LIMEN_LIBHL_LINK_LIBRARY libhl IMPORTED_LOCATION)
		get_filename_component(_LIMEN_LIBHL_DIRECTORY "${_LIMEN_LIBHL_LINK_LIBRARY}" DIRECTORY)
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
endif()

add_test(NAME limen_event_translation COMMAND limen_event_translation_test)
if(APPLE)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "DYLD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{DYLD_LIBRARY_PATH}"
	)
elseif(NOT WIN32)
	set_tests_properties(limen_event_translation PROPERTIES
		ENVIRONMENT "LD_LIBRARY_PATH=$<TARGET_FILE_DIR:libhl>:$ENV{LD_LIBRARY_PATH}"
	)
endif()
