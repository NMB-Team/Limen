package limen.metal;

typedef MetalHandle = hl.Abstract<"limen_metal_handle">;

@:hlNative("limen", "metal_")
class MetalNative {
	// Context management
	public static function init():Void {}
	public static function setup_window(win:limen.internal.WinPtr):Bool { return false; }
	public static function shutdown():Void {}

	// Device and command queue
	public static function is_initialized():Bool { return false; }
	public static function set_vsync(enabled:Bool):Void {}
	public static function profile_sequence():Int return 0;
	public static function profile_window_state(win:limen.internal.WinPtr):Int return 0;
	public static function profile_sampling():Bool return false;
	public static function profile_target(name:String):Void {}
	public static function profile_shader(id:Int):Void {}
	public static function render_layout_id():Int { return 0; }
	public static function device_name():hl.Bytes { return null; }
	public static function create_command_buffer():MetalHandle { return null; }
	public static function commit_command_buffer(cmdBuffer:MetalHandle):Bool { return false; }
	public static function commit_offscreen(cmdBuffer:MetalHandle, keepDrawable:Bool):Void {}

	// Buffer management
	public static function create_buffer(size:Int, usage:Int):MetalHandle { return null; }
	public static function upload_buffer_data(buffer:MetalHandle, data:hl.Bytes, size:Int, offset:Int):Bool { return false; }
	public static function update_buffer(buffer:MetalHandle, data:hl.Bytes, size:Int, offset:Int):MetalHandle { return null; }
	public static function dispose_buffer(buffer:MetalHandle):Void {}

	// Texture management
	public static function create_texture(width:Int, height:Int, format:Int, usage:Int, mipmapped:Bool, isCube:Bool, arrayLength:Int):MetalHandle { return null; }
	public static function upload_texture_data(texture:MetalHandle, data:hl.Bytes, width:Int, height:Int, level:Int, slice:Int):Bool { return false; }
	public static function capture_texture_pixels(texture:MetalHandle, data:hl.Bytes, x:Int, y:Int, width:Int, height:Int, level:Int, slice:Int):Bool { return false; }
	public static function generate_mipmaps(texture:MetalHandle):Void {}
	public static function dispose_texture(texture:MetalHandle):Void {}

	// Sampler state management
	public static function create_sampler_state(minFilter:Int, magFilter:Int, mipFilter:Int, wrapS:Int, wrapT:Int):MetalHandle { return null; }
	public static function dispose_sampler(sampler:MetalHandle):Void {}
	public static function set_fragment_samplers(encoder:MetalHandle, samplers:hl.NativeArray<MetalHandle>):Void {}
	public static function set_fragment_sampler(encoder:MetalHandle, sampler:MetalHandle, index:Int):Void {}

	// Shader compilation
	public static function compile_shader(source:String, shaderType:Int):MetalHandle { return null; }
	public static function create_compute_pipeline_from_function(func:MetalHandle):MetalHandle { return null; }
	public static function create_render_pipeline(vertexShader:MetalHandle, fragmentShader:MetalHandle, vertexDesc:String, blendSrc:Int, blendDst:Int, blendAlphaSrc:Int, blendAlphaDst:Int, blendOp:Int, blendAlphaOp:Int, colorMask:Int):MetalHandle { return null; }
	public static function dispose_pipeline(pipeline:MetalHandle):Void {}

	// Render command encoder
	public static function begin_render_pass(cmdBuffer:MetalHandle, clearColor:Bool, r:Float, g:Float, b:Float, a:Float, clearDepth:Float, stencil:Int):MetalHandle { return null; }
	public static function begin_mrt_render_pass(cmdBuffer:MetalHandle, textures:hl.NativeArray<MetalHandle>, r:Int, g:Int, b:Int, a:Int, clearMask:Int, depthTexture:MetalHandle, depthAction:Int, clearDepth:Float, stencil:Int):MetalHandle { return null; }
	public static function begin_texture_render_pass(cmdBuffer:MetalHandle, texture:MetalHandle, r:Int, g:Int, b:Int, a:Int, depthTexture:MetalHandle, layer:Int, mipLevel:Int, depthAction:Int, clearDepth:Float, stencil:Int):MetalHandle { return null; }
	public static function begin_depth_render_pass(cmdBuffer:MetalHandle, depthTexture:MetalHandle, layer:Int, clear:Bool, clearDepth:Float, stencil:Int):MetalHandle { return null; }
	public static function set_render_pipeline_state(encoder:MetalHandle, pipeline:MetalHandle):Void {}
	public static function set_depth_state(encoder:MetalHandle, depthTest:Bool, depthWrite:Bool):Void {}
	public static function set_stencil_state(encoder:MetalHandle, depthCompareFunc:Int, depthWrite:Bool, frontFunc:Int, frontSTfail:Int, frontDPfail:Int, frontPass:Int, backFunc:Int, backSTfail:Int, backDPfail:Int, backPass:Int, reference:Int, readMask:Int, writeMask:Int):Void {}
	public static function set_right_handed_winding(encoder:MetalHandle, rightHanded:Bool):Void {}
	public static function set_cull_mode(encoder:MetalHandle, cullMode:Int):Void {}
	public static function set_triangle_fill_mode(encoder:MetalHandle, wireframe:Bool):Void {}
	public static function set_vertex_buffer(encoder:MetalHandle, buffer:MetalHandle, offset:Int, index:Int):Void {}
	public static function set_vertex_bytes(encoder:MetalHandle, data:hl.Bytes, length:Int, index:Int):Void {}
	public static function set_fragment_bytes(encoder:MetalHandle, data:hl.Bytes, length:Int, index:Int):Void {}
	public static function set_fragment_texture(encoder:MetalHandle, texture:MetalHandle, index:Int):Void {}
	public static function set_fragment_buffer(encoder:MetalHandle, buffer:MetalHandle, offset:Int, index:Int):Void {}
	public static function draw_primitives(encoder:MetalHandle, primitiveType:Int, vertexStart:Int, vertexCount:Int):Void {}
	public static function draw_indexed_primitives(encoder:MetalHandle, primitiveType:Int, indexCount:Int, indexBuffer:MetalHandle, indexOffset:Int, is32bit:Int):Void {}
	public static function draw_indexed_ranges(encoder:MetalHandle, indexBuffer:MetalHandle, ranges:hl.NativeArray<Int>, count:Int, indexLimit:Int, stride:Int):Bool return false;
	public static function draw_indexed_primitives_instanced(encoder:MetalHandle, primitiveType:Int, indexCount:Int, indexBuffer:MetalHandle, indexOffset:Int, instanceCount:Int, is32bit:Int):Void {}
	public static function end_encoding(encoder:MetalHandle, discardBackbufferDepth:Bool):Void {}

	// Viewport and render state
	public static function set_viewport(encoder:MetalHandle, x:Float, y:Float, width:Float, height:Float):Void {}
	public static function set_scissor_rect(encoder:MetalHandle, x:Int, y:Int, width:Int, height:Int):Void {}

	// Debug/logging control (0=errors, 1=warnings, 2=info, 3=verbose)
	public static function set_debug_level(level:Int):Void {}

	// Compute shader support
	public static function create_compute_pipeline(source:hl.Bytes, functionName:hl.Bytes):MetalHandle { return null; }
	public static function set_compute_pipeline(pipeline:MetalHandle):Void {}
	public static function set_compute_texture(texture:MetalHandle, index:Int):Void {}
	public static function begin_compute(command:MetalHandle, pipeline:MetalHandle, x:Int, y:Int, z:Int):MetalHandle return null;
	public static function set_compute_bytes(encoder:MetalHandle, data:hl.Bytes, size:Int, index:Int):Bool return false;
	public static function bind_compute_buffer(encoder:MetalHandle, command:MetalHandle, buffer:MetalHandle, index:Int):Void {}
	public static function bind_compute_texture(encoder:MetalHandle, texture:MetalHandle, index:Int):Void {}
	public static function end_compute(encoder:MetalHandle, x:Int, y:Int, z:Int, tx:Int, ty:Int, tz:Int):Void {}
	public static function set_compute_buffer(buffer:MetalHandle, index:Int):Void {}
	public static function dispatch_compute(cmdBuffer:MetalHandle, x:Int, y:Int, z:Int):Bool { return false; }
	public static function memory_barrier(cmdBuffer:MetalHandle):Void {}
}
