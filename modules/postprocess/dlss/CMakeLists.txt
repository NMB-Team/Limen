set(_sources native/dlss.cpp)
limen_register_module(dlss ${_sources})
if(NOT LIMEN_BUILD_DLSS)
	return()
endif()

set(_LIMEN_STREAMLINE_ROOT_HINTS
	"${CMAKE_CURRENT_SOURCE_DIR}/native/streamline"
)
if(LIMEN_STREAMLINE_SDK_ROOT)
	list(APPEND _LIMEN_STREAMLINE_ROOT_HINTS "${LIMEN_STREAMLINE_SDK_ROOT}")
endif()
if(DEFINED ENV{STREAMLINE_SDK})
	list(APPEND _LIMEN_STREAMLINE_ROOT_HINTS "$ENV{STREAMLINE_SDK}")
endif()
set(_LIMEN_STREAMLINE_RUNTIME_FILES)
foreach(_runtime_name
	sl.interposer.dll
	sl.common.dll
	sl.pcl.dll
	sl.reflex.dll
	sl.dlss.dll
	sl.dlss_g.dll
	nvngx_dlss.dll
	nvngx_dlssg.dll
)
	string(MAKE_C_IDENTIFIER "${_runtime_name}" _runtime_id)
	find_file(_LIMEN_STREAMLINE_RUNTIME_${_runtime_id}
		NAMES "${_runtime_name}"
		HINTS ${_LIMEN_STREAMLINE_ROOT_HINTS}
		PATH_SUFFIXES bin/x64 x64
		REQUIRED
	)
	list(APPEND _LIMEN_STREAMLINE_RUNTIME_FILES
		"${_LIMEN_STREAMLINE_RUNTIME_${_runtime_id}}"
	)
endforeach()

limen_add_module(dlss ${_sources})
target_include_directories(limen_dlss PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/native/streamline"
)
target_link_libraries(limen_dlss PRIVATE
	libhl
	dxgi
	user32
	limen_postprocess_common
)
if(LIMEN_BUILD_VULKAN)
	target_compile_definitions(limen_dlss PRIVATE LIMEN_POSTPROCESS_VULKAN)
	target_include_directories(limen_dlss PRIVATE "${LIMEN_SOURCE_DIR}/modules/graphics/vulkan/native")
	target_link_libraries(limen_dlss PRIVATE Vulkan::Headers)
endif()
limen_stage_runtime(limen_dlss ${_LIMEN_STREAMLINE_RUNTIME_FILES})
install(
	FILES "${LIMEN_SOURCE_DIR}/modules/postprocess/dlss/haxe/limen/graphics/postprocess/dlss/LICENSE_STREAMLINE"
	DESTINATION "${LIMEN_HDLL_DESTINATION}"
)
