set(CMAKE_C_STANDARD 23)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
	set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
	set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)
	add_compile_options(
		$<$<CONFIG:Release>:/Oi>
		$<$<CONFIG:Release>:/Gy>
		$<$<CONFIG:Release>:/Ot>
		$<$<CONFIG:Release>:/Oy>
		$<$<CONFIG:Release>:/GT>
		$<$<CONFIG:Release>:/GS->
		$<$<CONFIG:Release>:/Zc:inline>
	)
	add_link_options(
		$<$<CONFIG:Release>:/OPT:REF>
		$<$<CONFIG:Release>:/OPT:ICF>
	)
endif()

function(limen_enable_c23_nullptr target)
	if(MSVC)
		target_compile_definitions("${target}" PRIVATE nullptr=0)
	endif()
endfunction()
