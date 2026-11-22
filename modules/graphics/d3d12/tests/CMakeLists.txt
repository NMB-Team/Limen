add_executable(limen_d3d12ma_test
	d3d12ma.cpp
	../native/memory_allocator.cpp
)
target_link_libraries(limen_d3d12ma_test PRIVATE libhl limen_d3d12ma)
add_test(NAME limen_d3d12ma COMMAND limen_d3d12ma_test)
set_tests_properties(limen_d3d12ma PROPERTIES
	LABELS d3d12
	ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:$<TARGET_FILE_DIR:libhl>"
)
