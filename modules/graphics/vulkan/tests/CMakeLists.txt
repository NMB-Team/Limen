add_executable(limen_vma_memory_test vma_memory.cpp)
get_target_property(_LIMEN_VMA_INCLUDES limen_vulkan INCLUDE_DIRECTORIES)
target_include_directories(limen_vma_memory_test PRIVATE ${_LIMEN_VMA_INCLUDES})
target_link_libraries(limen_vma_memory_test PRIVATE libhl Vulkan::Headers Vulkan::Vulkan)
add_test(NAME limen_vma_memory COMMAND limen_vma_memory_test)
if(WIN32)
	set_tests_properties(limen_vma_memory PROPERTIES
		SKIP_RETURN_CODE 77
		TIMEOUT 60
		ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:libhl>"
	)
endif()
set_tests_properties(limen_vma_memory PROPERTIES LABELS vulkan)
