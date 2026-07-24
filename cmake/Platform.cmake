set(LIMEN_NATIVE_WINDOW_SOURCE backend/platform/native_window.c)
set(LIMEN_PLATFORM_SOURCES ${LIMEN_NATIVE_WINDOW_SOURCE})
set(LIMEN_PLATFORM_LIBRARIES)

if(WIN32)
	list(APPEND LIMEN_PLATFORM_SOURCES
		backend/platform/windows/borderless.c
		backend/platform/windows/theme.c
	)
	list(APPEND LIMEN_PLATFORM_LIBRARIES winmm dwmapi)
endif()
