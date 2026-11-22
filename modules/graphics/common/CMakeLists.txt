target_sources(limen PRIVATE native/graphics_driver.c)

add_library(limen_graphics_common INTERFACE)
target_include_directories(limen_graphics_common INTERFACE "${CMAKE_CURRENT_SOURCE_DIR}/native")
