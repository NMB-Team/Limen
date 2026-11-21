include(FetchContent)
include("${CMAKE_CURRENT_LIST_DIR}/SDLEGL.cmake")

function(limen_resolve_sdl3)
	if(TARGET SDL3::SDL3-static)
		limen_patch_sdl_egl()
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
			URL https://github.com/libsdl-org/SDL/releases/download/release-3.4.20/SDL3-3.4.20.tar.gz
			URL_HASH SHA256=f3bb06f55bed9557227a700af2ea62e49497ebdf58037732a731a5fb3ef8581f
			EXCLUDE_FROM_ALL
		)
		FetchContent_MakeAvailable(SDL3)
	endif()

	if(NOT TARGET SDL3::SDL3-static)
		message(FATAL_ERROR "SDL3 static target was not created.")
	endif()
	limen_patch_sdl_egl()
endfunction()
