set(_sources
	native/context.c
	native/gl.c
)
limen_register_module(opengl ${_sources})
if(NOT LIMEN_BUILD_OPENGL)
	return()
endif()

limen_add_module(opengl ${_sources})
limen_enable_c23_nullptr(limen_opengl)
target_include_directories(limen_opengl PRIVATE
	"${LIMEN_SOURCE_DIR}/modules/platform/native"
	"${CMAKE_CURRENT_SOURCE_DIR}/native"
)
if(WIN32 AND NOT MINGW)
	target_include_directories(limen_opengl PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/native/include")
endif()
target_link_libraries(limen_opengl PRIVATE libhl limen)
find_package(Threads REQUIRED)
target_link_libraries(limen_opengl PRIVATE Threads::Threads)
if(APPLE)
	find_package(OpenGL REQUIRED)
	target_compile_definitions(limen_opengl PRIVATE GL_SILENCE_DEPRECATION)
	target_link_libraries(limen_opengl PRIVATE OpenGL::GL)
elseif(WIN32)
	target_link_libraries(limen_opengl PRIVATE opengl32)
elseif(ANDROID)
	target_link_libraries(limen_opengl PRIVATE GLESv3)
else()
	find_package(OpenGL REQUIRED)
	target_link_libraries(limen_opengl PRIVATE OpenGL::GL)
endif()
