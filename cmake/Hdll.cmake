include(GNUInstallDirs)

if(DEFINED HDLL_DESTINATION)
	set(LIMEN_HDLL_DESTINATION "${HDLL_DESTINATION}")
else()
	set(LIMEN_HDLL_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
endif()

function(limen_set_native_library target output_name suffix)
	foreach(_kind RUNTIME LIBRARY ARCHIVE)
		if(NOT DEFINED CMAKE_${_kind}_OUTPUT_DIRECTORY)
			set_target_properties(${target} PROPERTIES ${_kind}_OUTPUT_DIRECTORY "${LIMEN_BINARY_DIR}")
		endif()
	endforeach()

	set_target_properties(${target} PROPERTIES
		PREFIX ""
		OUTPUT_NAME "${output_name}"
		ARCHIVE_OUTPUT_NAME "${target}"
		SUFFIX "${suffix}"
	)

	if(NOT MSVC AND NOT APPLE)
		target_link_options(${target} PRIVATE "-Wl,--no-undefined")
	endif()

	if(APPLE)
		set_target_properties(${target} PROPERTIES
			BUILD_RPATH "@loader_path"
			INSTALL_RPATH "@loader_path"
		)
	elseif(UNIX)
		set_target_properties(${target} PROPERTIES
			BUILD_RPATH "$ORIGIN"
			INSTALL_RPATH "$ORIGIN"
		)
	endif()
endfunction()

function(limen_install_native_targets)
	set(_destinations
		RUNTIME DESTINATION "${LIMEN_HDLL_DESTINATION}"
		LIBRARY DESTINATION "${LIMEN_HDLL_DESTINATION}"
	)
	if(NOT MSVC)
		list(APPEND _destinations ARCHIVE DESTINATION "${LIMEN_HDLL_DESTINATION}")
	endif()
	install(TARGETS ${ARGN} ${_destinations})
endfunction()

function(limen_stage_runtime target)
	foreach(_file IN LISTS ARGN)
		get_filename_component(_name "${_file}" NAME)
		set_property(DIRECTORY "${LIMEN_SOURCE_DIR}" APPEND PROPERTY LIMEN_RUNTIME_FILES "${_name}")
	endforeach()

	add_custom_command(TARGET ${target} POST_BUILD
		COMMAND "${CMAKE_COMMAND}" -E copy_if_different ${ARGN} "$<TARGET_FILE_DIR:${target}>"
		VERBATIM
	)
	install(FILES ${ARGN} DESTINATION "${LIMEN_HDLL_DESTINATION}")
endfunction()
