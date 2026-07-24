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
		REQUIRED
	)

	if(NOT LIMEN_HASHLINK_LIBRARY)
		find_library(LIMEN_HASHLINK_LIBRARY
			NAMES hl libhl
			HINTS
				"${LIMEN_HASHLINK_ROOT}/build"
				"${LIMEN_HASHLINK_ROOT}/build/bin"
				"${LIMEN_HASHLINK_ROOT}/x64/Release"
			REQUIRED
		)
	endif()

	add_library(libhl UNKNOWN IMPORTED GLOBAL)
	set_target_properties(libhl PROPERTIES
		IMPORTED_LOCATION "${LIMEN_HASHLINK_LIBRARY}"
		INTERFACE_INCLUDE_DIRECTORIES "${LIMEN_HASHLINK_INCLUDE_DIR}"
	)
endfunction()
