string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef _id)
set(_prefix "${CMAKE_CURRENT_BINARY_DIR}/package-${_id}")
execute_process(
	COMMAND "${CMAKE_COMMAND}" --install "${BUILD_DIR}" --config "${CONFIG}" --prefix "${_prefix}" --component Unspecified
	COMMAND_ERROR_IS_FATAL ANY
)

set(_package "${_prefix}/${DESTINATION}")
set(_expected_binaries limen.hdll)
foreach(_module IN LISTS MODULES)
	list(APPEND _expected_binaries "${_module}.limen")
endforeach()
list(SORT _expected_binaries)
list(REMOVE_DUPLICATES RUNTIMES)
list(SORT RUNTIMES)

file(GLOB _binaries RELATIVE "${_package}" "${_package}/*.hdll" "${_package}/*.limen")
file(GLOB _runtimes RELATIVE "${_package}" "${_package}/*.dll")
if(NOT _binaries STREQUAL _expected_binaries)
	message(FATAL_ERROR "Expected native binaries [${_expected_binaries}], found [${_binaries}] in ${_package}")
endif()
if(NOT "${_runtimes}" STREQUAL "${RUNTIMES}")
	message(FATAL_ERROR "Expected runtime files [${RUNTIMES}], found [${_runtimes}] in ${_package}")
endif()
if(MSVC_PACKAGE AND NOT EXISTS "${_package}/limen.lib")
	message(FATAL_ERROR "Missing limen.lib in ${_package}")
endif()

file(REMOVE_RECURSE "${_prefix}")
