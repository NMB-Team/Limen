include(FetchContent)

function(limen_resolve_sdl3)
	if(TARGET SDL3::SDL3-static)
		return()
	endif()

	set(SDL_TEST OFF CACHE BOOL "" FORCE)
	set(SDL_TESTS OFF CACHE BOOL "" FORCE)
	set(SDL_SHARED OFF CACHE BOOL "" FORCE)
	set(SDL_STATIC ON CACHE BOOL "" FORCE)
	set(SDL_STATIC_PIC ON CACHE BOOL "" FORCE)
	set(CMAKE_POSITION_INDEPENDENT_CODE ON)

	if(LIMEN_SDL3_SOURCE_DIR)
		if(NOT EXISTS "${LIMEN_SDL3_SOURCE_DIR}/CMakeLists.txt")
			message(FATAL_ERROR "LIMEN_SDL3_SOURCE_DIR is not an SDL3 source tree: ${LIMEN_SDL3_SOURCE_DIR}")
		endif()
		add_subdirectory("${LIMEN_SDL3_SOURCE_DIR}" "${CMAKE_CURRENT_BINARY_DIR}/_deps/sdl3-build" EXCLUDE_FROM_ALL)
	else()
		FetchContent_Declare(
			SDL3
			URL https://github.com/libsdl-org/SDL/releases/download/release-3.4.12/SDL3-3.4.12.tar.gz
			URL_HASH SHA256=f07b958a9ac5020fb7a44cadb957f658b2149c3c8abb4f63145fac9303249db7
			EXCLUDE_FROM_ALL
		)
		FetchContent_MakeAvailable(SDL3)
	endif()

	if(NOT TARGET SDL3::SDL3-static)
		message(FATAL_ERROR "SDL3 static target was not created.")
	endif()
endfunction()
