function(limen_add_hlc_import_library)
	string(TOUPPER "${CMAKE_C_COMPILER_ARCHITECTURE_ID}" _machine)
	if(_machine STREQUAL "WIN32")
		set(_machine X86)
	elseif(NOT _machine)
		if(CMAKE_SIZEOF_VOID_P EQUAL 8)
			set(_machine X64)
		else()
			set(_machine X86)
		endif()
	endif()

	set(_dependencies limen)
	set(_libraries "$<TARGET_LINKER_FILE:limen>")
	foreach(_target IN LISTS ARGN)
		if(_target STREQUAL "limen")
			continue()
		endif()

		set(_def "${LIMEN_BINARY_DIR}/${_target}_hlc.def")
		set(_hlc_target "${_target}_hlc_import_library")
		set(_library "$<TARGET_LINKER_FILE_DIR:limen>/${_target}_hlc.lib")
		add_custom_target(${_hlc_target}
			COMMAND "${CMAKE_AR}" /NOLOGO "/DEF:${_def}" "/OUT:${_library}" "/MACHINE:${_machine}"
			DEPENDS ${_target} "${_def}"
			VERBATIM
		)
		list(APPEND _dependencies ${_hlc_target})
		list(APPEND _libraries "${_library}")
	endforeach()

	set(_combined "$<TARGET_LINKER_FILE_DIR:limen>/limen.lib")
	add_custom_target(limen_import_library ALL
		COMMAND "${CMAKE_AR}" /NOLOGO /IGNORE:4006 "/OUT:${_combined}" ${_libraries}
		DEPENDS ${_dependencies}
		COMMAND_EXPAND_LISTS
		VERBATIM
	)
	install(FILES "${_combined}" DESTINATION "${LIMEN_HDLL_DESTINATION}")
endfunction()
