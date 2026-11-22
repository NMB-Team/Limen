target_sources(limen PRIVATE
	native/hints.c
	native/system.c
	native/time.c
	native/input/events.c
	native/input/gamepad.c
	native/input/joystick.c
	native/input/keyboard.c
	native/input/mouse.c
	native/input/touch.c
	native/input/pen.c
	native/window/clipboard.c
	native/window/cursor.c
	native/window/display.c
	native/window/dragdrop.c
	native/window/file_dialog.c
	native/window/tray.c
	native/window/window.c
	native/graphics.c
	native/native_window.c
)
target_include_directories(limen PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native")
target_link_libraries(limen PRIVATE SDL3::SDL3-static)

if(WIN32)
	target_sources(limen PRIVATE
		native/windows/borderless.c
		native/windows/icon.c
		native/windows/theme.c
	)
	target_link_libraries(limen PRIVATE winmm dwmapi advapi32)
endif()

if(LIMEN_BUILD_VULKAN)
	target_compile_definitions(limen PRIVATE LIMEN_HAS_VULKAN)
	target_link_libraries(limen PRIVATE Vulkan::Headers)
endif()
