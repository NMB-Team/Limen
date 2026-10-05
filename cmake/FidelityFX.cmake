include(FetchContent)

function(limen_resolve_fidelityfx)
	if(LIMEN_FIDELITYFX_SOURCE_DIR)
		set(_sdk "${LIMEN_FIDELITYFX_SOURCE_DIR}/Kits/FidelityFX")
	else()
		FetchContent_Declare(limen_fidelityfx_source
			URL https://github.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/archive/60f4ea81909200d8542eca14dccb2628b763a9a3.tar.gz
			URL_HASH SHA256=1bd5524a3f7380a674410dcc2be08cd8c38d2047b175d02f186e5d0dcc20be5c
			SOURCE_SUBDIR _limen_populate_only
		)
		FetchContent_MakeAvailable(limen_fidelityfx_source)
		set(_sdk "${limen_fidelityfx_source_SOURCE_DIR}/Kits/FidelityFX")
	endif()
	if(NOT EXISTS "${_sdk}/upscalers/fsr3/internal/ffx_fsr3upscaler.cpp")
		message(FATAL_ERROR "LIMEN_FIDELITYFX_SOURCE_DIR must contain AMD FSR SDK 2.3.0.")
	endif()

	file(GLOB_RECURSE _sdk_inputs CONFIGURE_DEPENDS "${_sdk}/api/*" "${_sdk}/backend/*" "${_sdk}/upscalers/*" "${_sdk}/framegeneration/*")
	set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS ${_sdk_inputs})
	set(_build_sdk "${CMAKE_CURRENT_BINARY_DIR}/fidelityfx-source")
	file(COPY "${_sdk}/api" "${_sdk}/backend" "${_sdk}/upscalers" "${_sdk}/framegeneration"
		DESTINATION "${_build_sdk}"
		PATTERN ffx_fsr3upscaler.cpp EXCLUDE
		PATTERN ffx_fsr3upscaler_private.h EXCLUDE
		PATTERN ffx_dx12.cpp EXCLUDE
		PATTERN ffx_internal_types.h EXCLUDE
	)
	foreach(_file upscalers/fsr3/internal/ffx_fsr3upscaler.cpp upscalers/fsr3/internal/ffx_fsr3upscaler_private.h)
		file(READ "${_sdk}/${_file}" _source)
		string(REPLACE "#ifndef _GAMING_XBOX" "#if 0 // Unpublished AMD diagnostic overlay" _source "${_source}")
		string(REPLACE "#if !defined(_GAMING_XBOX)" "#if 0 // Unpublished AMD build metadata" _source "${_source}")
		file(CONFIGURE OUTPUT "${_build_sdk}/${_file}" CONTENT "${_source}" @ONLY)
	endforeach()
	file(READ "${_sdk}/backend/dx12/ffx_dx12.cpp" _source)
	string(REPLACE "#define ENABLE_AGS 1" "" _source "${_source}")
	string(REPLACE "#define ENABLE_PIX_CAPTURES 1" "" _source "${_source}")
	file(CONFIGURE OUTPUT "${_build_sdk}/backend/dx12/ffx_dx12.cpp" CONTENT "${_source}" @ONLY)
	file(READ "${_sdk}/api/internal/ffx_internal_types.h" _source)
	string(REPLACE "info[index].entryName" "\"CS\"" _source "${_source}")
	file(CONFIGURE OUTPUT "${_build_sdk}/api/internal/ffx_internal_types.h" CONTENT "${_source}" @ONLY)
	set(_sdk "${_build_sdk}")

	if(LIMEN_FIDELITYFX_TOOLS_DIR)
		set(_tools "${LIMEN_FIDELITYFX_TOOLS_DIR}")
	else()
		set(_tools "${CMAKE_CURRENT_BINARY_DIR}/fidelityfx-tools")
		file(MAKE_DIRECTORY "${_tools}")
		set(_tool_files FidelityFX_SC.exe dxcompiler.dll dxil.dll)
		set(_tool_hashes
			75480f2245e7b2cac300b013fad1453d4b966e5bd52c69205a40537de05f02a9
			eb0e6196eae92f69f7e3a8a0bf0e35f30d7c2adad475bebbde3a41015ca0b414
			1f61b171315ecffabdf56d4216e77d56533e3113f8fe29c5ad34a45c52c91efa
		)
		foreach(_index RANGE 0 2)
			list(GET _tool_files ${_index} _file)
			list(GET _tool_hashes ${_index} _hash)
			if(NOT EXISTS "${_tools}/${_file}")
				file(DOWNLOAD
					"https://raw.githubusercontent.com/GPUOpen-LibrariesAndSDKs/FidelityFX-SDK/c6efa6bf7f2027b3ec94f28578bb5965eabb9e55/sdk/tools/binary_store/${_file}"
					"${_tools}/${_file}"
					EXPECTED_HASH "SHA256=${_hash}"
					TLS_VERIFY ON
					TIMEOUT 180
				)
			endif()
		endforeach()
	endif()
	foreach(_file FidelityFX_SC.exe dxcompiler.dll dxil.dll)
		if(NOT EXISTS "${_tools}/${_file}")
			message(FATAL_ERROR "Missing FidelityFX shader build tool: ${_tools}/${_file}")
		endif()
	endforeach()

	set(_shaders "${CMAKE_CURRENT_BINARY_DIR}/fidelityfx-shaders")
	file(MAKE_DIRECTORY "${_shaders}")
	file(GLOB _shader_inputs CONFIGURE_DEPENDS
		"${_sdk}/api/internal/gpu/*.h"
		"${_sdk}/upscalers/fsr3/include/gpu/*/*.h"
		"${_sdk}/upscalers/fsr3/internal/shaders/ffx_fsr3upscaler_*.hlsl"
	)
	set(_shader_headers)
	foreach(_pass autogen_reactive accumulate luma_pyramid prepare_reactivity prepare_inputs shading_change rcas shading_change_pyramid luma_instability debug_view)
		set(_name "ffx_fsr3upscaler_${_pass}_pass")
		foreach(_variant "default" wave64 16bit wave64_16bit)
			set(_variant_args)
			set(_suffix "")
			if(NOT _variant STREQUAL "default")
				set(_suffix "_${_variant}")
			endif()
			if(_variant MATCHES "wave64")
				list(APPEND _variant_args "-DFFX_PREFER_WAVE64=[WaveSize(64)]" -DFFX_HLSL_SM=66 -T cs_6_6)
			else()
				list(APPEND _variant_args -DFFX_HLSL_SM=62 -T cs_6_2)
			endif()
			if(_variant MATCHES "16bit")
				list(APPEND _variant_args -DFFX_HALF=1 -enable-16bit-types)
			else()
				list(APPEND _variant_args -DFFX_HALF=0)
			endif()
			set(_header "${_shaders}/${_name}${_suffix}_permutations.h")
			add_custom_command(OUTPUT "${_header}"
				COMMAND "${_tools}/FidelityFX_SC.exe"
					-Zs -reflection -embed-arguments -E CS -Wno-for-redefinition -Wno-ambig-lit-shift
					-DFFX_HLSL=1 -DFFX_GPU=1 -DFFX_IMPLICIT_SHADER_REGISTER_BINDING_HLSL=0
					-DFFX_FSR3UPSCALER_EMBED_ROOTSIG=0
					-DFFX_FSR3UPSCALER_OPTION_UPSAMPLE_SAMPLERS_USE_DATA_HALF=0
					-DFFX_FSR3UPSCALER_OPTION_ACCUMULATE_SAMPLERS_USE_DATA_HALF=0
					-DFFX_FSR3UPSCALER_OPTION_REPROJECT_SAMPLERS_USE_DATA_HALF=1
					-DFFX_FSR3UPSCALER_OPTION_POSTPROCESSLOCKSTATUS_SAMPLERS_USE_DATA_HALF=0
					-DFFX_FSR3UPSCALER_OPTION_UPSAMPLE_USE_LANCZOS_TYPE=2
					"-DFFX_FSR3UPSCALER_OPTION_REPROJECT_USE_LANCZOS_TYPE={0,1}"
					"-DFFX_FSR3UPSCALER_OPTION_HDR_COLOR_INPUT={0,1}"
					"-DFFX_FSR3UPSCALER_OPTION_LOW_RESOLUTION_MOTION_VECTORS={0,1}"
					"-DFFX_FSR3UPSCALER_OPTION_JITTERED_MOTION_VECTORS={0,1}"
					"-DFFX_FSR3UPSCALER_OPTION_INVERTED_DEPTH={0,1}"
					"-DFFX_FSR3UPSCALER_OPTION_APPLY_SHARPENING={0,1}"
					${_variant_args}
					-I "${_sdk}/api/internal/gpu" -I "${_sdk}/upscalers/fsr3/include/gpu"
					"-name=${_name}${_suffix}" "-output=${_shaders}"
					"${_sdk}/upscalers/fsr3/internal/shaders/${_name}.hlsl"
				DEPENDS ${_shader_inputs} "${_tools}/FidelityFX_SC.exe" "${_tools}/dxcompiler.dll" "${_tools}/dxil.dll"
				COMMENT "Compiling FSR shader ${_name}${_suffix}"
				VERBATIM
			)
			list(APPEND _shader_headers "${_header}")
		endforeach()
	endforeach()

	add_library(limen_fidelityfx STATIC
		"${_sdk}/api/internal/ffx_assert.cpp"
		"${_sdk}/api/internal/ffx_message.cpp"
		"${_sdk}/api/internal/ffx_object_management.cpp"
		"${_sdk}/backend/dx12/ffx_dx12.cpp"
		"${_sdk}/backend/dx12/ffx_backends_dx12.cpp"
		"${_sdk}/upscalers/fsr3/internal/ffx_provider_fsr3upscale.cpp"
		"${_sdk}/upscalers/fsr3/internal/ffx_fsr3upscaler.cpp"
		"${_sdk}/upscalers/fsr3/internal/ffx_fsr3upscaler_shaderblobs.cpp"
		${_shader_headers}
	)
	target_include_directories(limen_fidelityfx PUBLIC
		"${_sdk}/api/include"
		"${_sdk}/api/internal"
		"${_sdk}/upscalers/include"
		"${_sdk}/upscalers/fsr3/include"
	)
	target_include_directories(limen_fidelityfx PRIVATE "${_shaders}")
	target_compile_definitions(limen_fidelityfx PRIVATE FFX_UPSCALER NOMINMAX WIN32_LEAN_AND_MEAN)
	target_link_libraries(limen_fidelityfx PRIVATE d3d12 dxgi)
	install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/limen/graphics/postprocess/fsr/LICENSE_FIDELITYFX" DESTINATION "${LIMEN_HDLL_DESTINATION}")
endfunction()
