set(LIMEN_HASHLINK_ROOT "" CACHE PATH "Path to a HashLink source checkout.")
set(LIMEN_HASHLINK_LIBRARY "" CACHE FILEPATH "Path to the HashLink library for standalone builds.")

function(limen_resolve_hashlink)
	if(TARGET libhl)
		return()
	endif()

	if(NOT LIMEN_HASHLINK_ROOT)
		message(FATAL_ERROR "LIMEN_HASHLINK_ROOT is required for a standalone build.")
	endif()

	find_path(LIMEN_HASHLINK_INCLUDE_DIR
		NAMES hl.h
		HINTS "${LIMEN_HASHLINK_ROOT}/src"
		NO_DEFAULT_PATH
	)
	if(NOT LIMEN_HASHLINK_INCLUDE_DIR)
		message(FATAL_ERROR "HashLink headers were not found. Set LIMEN_HASHLINK_ROOT to a HashLink checkout containing src/hl.h.")
	endif()

	if(NOT LIMEN_HASHLINK_LIBRARY)
		unset(LIMEN_HASHLINK_LIBRARY CACHE)
		find_library(LIMEN_HASHLINK_LIBRARY
			NAMES libhl hl
			HINTS
				"${LIMEN_HASHLINK_ROOT}/build"
				"${LIMEN_HASHLINK_ROOT}/build/bin"
				"${LIMEN_HASHLINK_ROOT}/x64/Release"
		)
	endif()
	if(NOT EXISTS "${LIMEN_HASHLINK_LIBRARY}")
		message(FATAL_ERROR "The HashLink library was not found. Build HashLink and set LIMEN_HASHLINK_LIBRARY to the built library or import library.")
	endif()

	add_library(libhl UNKNOWN IMPORTED GLOBAL)
	set_target_properties(libhl PROPERTIES
		IMPORTED_LOCATION "${LIMEN_HASHLINK_LIBRARY}"
		INTERFACE_INCLUDE_DIRECTORIES "${LIMEN_HASHLINK_INCLUDE_DIR}"
	)
endfunction()
