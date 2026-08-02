include(GNUInstallDirs)

if(DEFINED HDLL_DESTINATION)
	set(LIMEN_HDLL_DESTINATION "${HDLL_DESTINATION}")
else()
	set(LIMEN_HDLL_DESTINATION "${CMAKE_INSTALL_LIBDIR}")
endif()

function(limen_set_native_library target output_name suffix)
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
