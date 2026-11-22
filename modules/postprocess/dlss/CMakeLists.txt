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

add_library(limen_dlss SHARED native/dlss.cpp)
limen_set_native_library(limen_dlss dlss .limen)
target_include_directories(limen_dlss PRIVATE
	"${CMAKE_CURRENT_SOURCE_DIR}/native/streamline"
)
target_link_libraries(limen_dlss PRIVATE
	libhl
	dxgi
	user32
)
if(LIMEN_BUILD_VULKAN)
	target_compile_definitions(limen_dlss PRIVATE LIMEN_POSTPROCESS_VULKAN)
	target_include_directories(limen_dlss PRIVATE "${LIMEN_SOURCE_DIR}/modules/graphics/vulkan/native")
	target_link_libraries(limen_dlss PRIVATE Vulkan::Headers)
endif()
add_custom_command(TARGET limen_dlss POST_BUILD
	COMMAND "${CMAKE_COMMAND}" -E copy_if_different
		${_LIMEN_STREAMLINE_RUNTIME_FILES} "$<TARGET_FILE_DIR:limen_dlss>"
)
install(FILES ${_LIMEN_STREAMLINE_RUNTIME_FILES} DESTINATION "${LIMEN_HDLL_DESTINATION}")
install(
	FILES "${LIMEN_SOURCE_DIR}/limen/graphics/postprocess/dlss/LICENSE_STREAMLINE"
	DESTINATION "${LIMEN_HDLL_DESTINATION}"
)
