#include "metal.h"

// ============================================================================
// Hashlink exports: DEFINE_PRIM registrations, thin wrappers, and
// command-buffer management (kept inline because it touches ctx->currentDrawable)
// ============================================================================

// ============================================================================
// Context lifecycle wrappers
// ============================================================================

HL_PRIM void HL_NAME(init)(void) {
    metal_init_context();
}

HL_PRIM bool HL_NAME(setup_window)(void *win) {
    return metal_setup_window_context(win);
}

HL_PRIM void HL_NAME(shutdown)(void) {
    metal_shutdown_context();
}

// ============================================================================
// Command-buffer management — full implementations kept here
// ============================================================================

HL_PRIM bool HL_NAME(is_available)(void) {
    @autoreleasepool {
        return MTLCreateSystemDefaultDevice() != nil;
    }
}

HL_PRIM bool HL_NAME(is_initialized)(void) {
    return ctx != NULL;
}

HL_PRIM vbyte* HL_NAME(device_name)(void) {
    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
        const char *name = device.name.UTF8String;
        return hl_copy_bytes((const vbyte*)name, (int)strlen(name) + 1);
    }
}

HL_PRIM int HL_NAME(profile_sequence)(void) {
    return ctx == NULL ? 0 : (int)ctx->profileSequence;
}

// SDL visibility diagnostics also work before Metal context initialization,
// allowing the OpenGL comparison to record the same window-state bits.
HL_PRIM int HL_NAME(profile_window_state)(void *window) {
    return limen_metal_window_state(window);
}

HL_PRIM bool HL_NAME(profile_sampling)(void) {
    return ctx != NULL && ctx->profilePassFrame != NULL;
}

HL_PRIM void HL_NAME(profile_target)(vstring *name) {
    LimenMetalPassFrame *frame = (__bridge LimenMetalPassFrame *)ctx->profilePassFrame;
    if (frame == nil || frame->count == 0 || frame->count > METAL_PROFILE_PASS_LIMIT || name == NULL) return;
    char *label = frame->passes[frame->count - 1].name;
    snprintf(label, 128, "%s", hl_to_utf8(name->bytes));
    for (char *p = label; *p; p++) if (*p == ',' || *p == '\n' || *p == '\r') *p = '_';
}

HL_PRIM void HL_NAME(profile_shader)(int id) {
    LimenMetalPassFrame *frame = (__bridge LimenMetalPassFrame *)ctx->profilePassFrame;
    if (frame != nil && frame->count != 0 && frame->count <= METAL_PROFILE_PASS_LIMIT) frame->passes[frame->count - 1].shader = id;
}

HL_PRIM int HL_NAME(render_layout_id)(void) {
    int formats[10];
    for (int i = 0; i < 8; i++) formats[i] = (int)ctx->colorFormats[i];
    formats[8] = (int)ctx->depthFormat;
    formats[9] = (int)ctx->stencilFormat;

    for (metal_render_layout *layout = ctx->layouts; layout != NULL; layout = layout->next)
        if (memcmp(formats, layout->formats, sizeof(formats)) == 0)
            return layout->id;

    metal_render_layout *layout = malloc(sizeof(*layout));
    if (layout == NULL) hl_error("Failed to allocate Metal render layout");
    memcpy(layout->formats, formats, sizeof(formats));
    layout->id = ++ctx->layoutCount;
    layout->next = ctx->layouts;
    ctx->layouts = layout;
    return layout->id;
}

HL_PRIM void HL_NAME(set_vsync)(bool enabled) {
    if (ctx != NULL && ctx->layer != NULL) {
        CAMetalLayer *layer = (__bridge CAMetalLayer *)ctx->layer;
#if TARGET_OS_OSX
        layer.displaySyncEnabled = enabled;
        if (ctx->profileEnabled)
            fprintf(stderr, "metal-vsync,%d,%d,%lu\n", enabled, layer.displaySyncEnabled,
                    (unsigned long)layer.maximumDrawableCount);
#endif
    }
}

static void metal_commit(id<MTLCommandBuffer> command, bool presents) {
    metal_last_submitted_command = command;
    if (!ctx->profileEnabled) {
        [command commit];
        return;
    }

    metal_profile_sample sample = ctx->profile;
    LimenMetalPassFrame *detail = (__bridge_transfer LimenMetalPassFrame *)ctx->profilePassFrame;
    ctx->profilePassFrame = NULL;
    CFTimeInterval submission = CACurrentMediaTime();
    if (sample.drawableAcquired > 0) {
        // CPU time before acquisition excludes the blocking nextDrawable call.
        // The second duration ends at submission, not GPU completion or display.
        fprintf(stderr, "metal-drawable,%u,%.6f,%.6f,%u,%u,%u,%u\n", sample.id,
            (sample.drawableAcquired - sample.start - sample.drawable) * 1000,
            (submission - sample.drawableAcquired) * 1000,
            sample.passesBeforeDrawable, sample.drawsBeforeDrawable,
            sample.passes - sample.passesBeforeDrawable, sample.draws - sample.drawsBeforeDrawable);
    }
    [command addCompletedHandler:^(id<MTLCommandBuffer> done) {
        double gpu = done.GPUEndTime - done.GPUStartTime;
        fprintf(stderr, "metal-window,%u,%d\n", sample.id, sample.windowState);
        fprintf(stderr, "metal-command,%u,%d,%lu,%.6f,%.6f,%.6f,%.6f,%u,%u,%u,%u,%u,%u,%u,%zu,%zu,%zu,%u,%u,%u,%u,%u\n",
                sample.id, presents, (unsigned long)done.status, (submission - sample.start) * 1000,
                sample.drawable * 1000, gpu * 1000, sample.compile * 1000, sample.passes, sample.draws,
                sample.buffers, sample.textures, sample.pipelines, sample.libraries, sample.renames,
                sample.uploadBytes, sample.copyBytes, sample.constantBytes, sample.bufferReuses, sample.viewportSets, sample.scissorSets, sample.textureReuses, sample.passDescriptors);
        // Basic profiling also needs absolute GPU boundaries for multi-command
        // frame spans. No GPU counter buffers or synchronous waits are added.
        fprintf(stderr, "metal-timeline,%u,%.9f,%.9f,%.9f,%.9f\n", sample.id, submission, done.GPUStartTime, done.GPUEndTime, CACurrentMediaTime());
        if (detail != nil) metal_profile_resolve(detail, sample.id);
    }];
    CFTimeInterval commitStart = CACurrentMediaTime();
    [command commit];
    if (ctx->profileDetailed)
        fprintf(stderr, "metal-cpu,%u,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n", sample.id,
            sample.commandCreate * 1000, sample.encoderCreate * 1000, sample.encoderEnd * 1000,
            sample.bufferAlloc * 1000, sample.textureAlloc * 1000, sample.upload * 1000,
            sample.presentRegister * 1000, (CACurrentMediaTime() - commitStart) * 1000, sample.sizeQuery * 1000, sample.texturePoolLookup * 1000);
}

HL_PRIM metal_handle* HL_NAME(create_command_buffer)() {
    if (ctx == NULL || ctx->commandQueue == NULL) {
        metal_debug_log("ERROR: create_command_buffer() - ctx or commandQueue is NULL");
        return NULL;
    }

    @autoreleasepool {
        id<MTLCommandQueue> commandQueue = (__bridge id<MTLCommandQueue>)ctx->commandQueue;
        CFTimeInterval createStart = ctx->profileEnabled ? CACurrentMediaTime() : 0;
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        if (commandBuffer == NULL) {
            metal_debug_log("ERROR: create_command_buffer() - failed to create command buffer");
            return NULL;
        }

        if (ctx->profileEnabled) {
            ctx->profile = (metal_profile_sample){.id = ++ctx->profileSequence, .start = createStart,
                .commandCreate = CACurrentMediaTime() - createStart};
            metal_profile_begin_command();
        }
        metal_debug_log("create_command_buffer() - SUCCESS");
        return (metal_handle*)(__bridge_retained void*)commandBuffer;
    }
}

HL_PRIM bool HL_NAME(commit_command_buffer)(metal_handle *cmdBuffer) {
    if (cmdBuffer == NULL) {
        metal_debug_log("ERROR: commit_command_buffer() - cmdBuffer is NULL");
        return false;
    }

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge_transfer id<MTLCommandBuffer>)cmdBuffer;

        bool presents = ctx->currentDrawable != NULL;
        if (presents) {
            id<CAMetalDrawable> drawable = (__bridge id<CAMetalDrawable>)ctx->currentDrawable;
            if (ctx->profileEnabled) {
                unsigned sequence = ctx->profile.id;
                [drawable addPresentedHandler:^(id<MTLDrawable> shown) {
                    fprintf(stderr, "metal-present,%u,%.6f\n", sequence, shown.presentedTime);
                }];
            }
            CFTimeInterval presentStart = ctx->profileDetailed ? CACurrentMediaTime() : 0;
            [commandBuffer presentDrawable:drawable];
            if (ctx->profileDetailed) ctx->profile.presentRegister += CACurrentMediaTime() - presentStart;

            // Release the drawable after presenting
            id<CAMetalDrawable> drawableToRelease = (__bridge_transfer id<CAMetalDrawable>)ctx->currentDrawable;
            (void)drawableToRelease; // ARC will handle release
            ctx->currentDrawable = NULL;
            metal_debug_log("commit_command_buffer() - SUCCESS with drawable");
        } else {
            metal_debug_log("WARNING: commit_command_buffer() - no drawable to present");
        }

        ctx->currentCommandBuffer = NULL;
        metal_commit(commandBuffer, presents);

        return true;
    }
}

HL_PRIM void HL_NAME(commit_offscreen)(metal_handle *cmdBuffer, bool keepDrawable) {
    @autoreleasepool {
        id<MTLCommandBuffer> command = (__bridge_transfer id<MTLCommandBuffer>)cmdBuffer;
        if (!keepDrawable && ctx->currentDrawable != NULL) {
            CFRelease(ctx->currentDrawable);
            ctx->currentDrawable = NULL;
        }
        ctx->currentCommandBuffer = NULL;
        metal_commit(command, false);
    }
}

// ============================================================================
// Logging control
// ============================================================================

HL_PRIM void HL_NAME(set_debug_level)(int level) {
    metal_set_log_level(level);
}

// ============================================================================
// Thin wrappers — Resources (metal_resources.m)
// ============================================================================

HL_PRIM metal_handle* HL_NAME(create_buffer)(int size, int usage) {
    return metal_create_buffer_impl(size, usage);
}

HL_PRIM metal_handle *HL_NAME(update_buffer)(metal_handle *buffer, vbyte *data, int size, int offset) {
    return metal_update_buffer_impl(buffer, data, size, offset);
}

HL_PRIM bool HL_NAME(upload_buffer_data)(metal_handle *buffer, vbyte *data, int size, int offset) {
    return metal_upload_buffer_data_impl(buffer, data, size, offset);
}

HL_PRIM metal_handle* HL_NAME(create_texture)(int width, int height, int format, int usage, bool mipmapped, bool isCube, int arrayLength) {
    return metal_create_texture_impl(width, height, format, usage, mipmapped, isCube, arrayLength);
}

HL_PRIM bool HL_NAME(upload_texture_data)(metal_handle *texture, vbyte *data, int width, int height, int level, int slice) {
    return metal_upload_texture_data_impl(texture, data, width, height, level, slice);
}

HL_PRIM bool HL_NAME(capture_texture_pixels)(metal_handle *texture, vbyte *data, int x, int y, int width, int height, int level, int slice) {
    return metal_capture_texture_pixels_impl(texture, data, x, y, width, height, level, slice);
}

HL_PRIM void HL_NAME(generate_mipmaps)(metal_handle *texture) {
    metal_generate_mipmaps_impl(texture);
}

HL_PRIM void HL_NAME(dispose_texture)(metal_handle *texture) {
    metal_dispose_texture_impl(texture);
}

HL_PRIM metal_handle* HL_NAME(create_sampler_state)(int minFilter, int magFilter, int mipFilter, int wrapS, int wrapT) {
    return metal_create_sampler_state_impl(minFilter, magFilter, mipFilter, wrapS, wrapT);
}

HL_PRIM void HL_NAME(dispose_buffer)(metal_handle *buffer) {
    metal_dispose_buffer_impl(buffer);
}

HL_PRIM void HL_NAME(dispose_sampler)(metal_handle *sampler) {
    metal_dispose_sampler_impl(sampler);
}

HL_PRIM void HL_NAME(set_fragment_samplers)(metal_handle *encoder, varray *samplers) {
    metal_set_fragment_samplers_impl(encoder, samplers);
}

HL_PRIM void HL_NAME(set_fragment_sampler)(metal_handle *encoder, metal_handle *sampler, int index) {
    metal_set_fragment_sampler_impl(encoder, sampler, index);
}

// ============================================================================
// Thin wrappers — Pipeline (metal_pipeline.m)
// ============================================================================

HL_PRIM metal_handle* HL_NAME(compile_shader)(vstring *source, int shaderType) {
    return metal_compile_shader_impl(source, shaderType);
}

HL_PRIM metal_handle* HL_NAME(create_render_pipeline)(metal_handle *vertexShader, metal_handle *fragmentShader, vstring *vertexDesc, int blendSrc, int blendDst, int blendAlphaSrc, int blendAlphaDst, int blendOp, int blendAlphaOp, int colorMask) {
    return metal_create_render_pipeline_impl(vertexShader, fragmentShader, vertexDesc, blendSrc, blendDst, blendAlphaSrc, blendAlphaDst, blendOp, blendAlphaOp, colorMask);
}

HL_PRIM metal_handle* HL_NAME(create_compute_pipeline_from_function)(metal_handle *func) {
    return metal_create_compute_pipeline_from_function_impl(func);
}

HL_PRIM void HL_NAME(dispose_pipeline)(metal_handle *pipeline) {
    metal_dispose_pipeline_impl(pipeline);
}

// ============================================================================
// Thin wrappers — Render (metal_render.m)
// ============================================================================

HL_PRIM metal_handle* HL_NAME(begin_render_pass)(metal_handle *cmdBuffer, bool clearColor, double r, double g, double b, double a, double clearDepth, int stencil) {
    return metal_begin_render_pass_impl(cmdBuffer, clearColor, r, g, b, a, clearDepth, stencil);
}

HL_PRIM metal_handle* HL_NAME(begin_texture_render_pass)(metal_handle *cmdBuffer, metal_handle *texture, int r, int g, int b, int a, metal_handle *depthTexParam, int layer, int mipLevel, int depthAction, double clearDepth, int stencil) {
    return metal_begin_texture_render_pass_impl(cmdBuffer, texture, r, g, b, a, depthTexParam, layer, mipLevel, depthAction, clearDepth, stencil);
}

HL_PRIM metal_handle* HL_NAME(begin_mrt_render_pass)(metal_handle *cmdBuffer, varray *textures, int r, int g, int b, int a, int clearMask, metal_handle *depthTex, int depthAction, double clearDepth, int stencil) {
    return metal_begin_mrt_render_pass_impl(cmdBuffer, textures, r, g, b, a, clearMask, depthTex, depthAction, clearDepth, stencil);
}

HL_PRIM metal_handle* HL_NAME(begin_depth_render_pass)(metal_handle *cmdBuffer, metal_handle *depthTexture, int layer, bool clear, double clearDepth, int stencil) {
    return metal_begin_depth_render_pass_impl(cmdBuffer, depthTexture, layer, clear, clearDepth, stencil);
}

HL_PRIM void HL_NAME(set_render_pipeline_state)(metal_handle *encoder, metal_handle *pipeline) {
    metal_set_render_pipeline_state_impl(encoder, pipeline);
}

HL_PRIM void HL_NAME(set_depth_state)(metal_handle *encoder, bool depthTest, bool depthWrite) {
    metal_set_depth_state_impl(encoder, depthTest, depthWrite);
}

HL_PRIM void HL_NAME(set_stencil_state)(metal_handle *encoder, int depthCompareFunc, bool depthWrite,
    int frontFunc, int frontSTfail, int frontDPfail, int frontPass,
    int backFunc, int backSTfail, int backDPfail, int backPass,
    int reference, int readMask, int writeMask) {
    metal_set_stencil_state_impl(encoder, depthCompareFunc, depthWrite,
        frontFunc, frontSTfail, frontDPfail, frontPass,
        backFunc, backSTfail, backDPfail, backPass,
        reference, readMask, writeMask);
}

HL_PRIM void HL_NAME(set_right_handed_winding)(metal_handle *handle, bool rightHanded) {
    id<MTLRenderCommandEncoder> encoder = (__bridge id<MTLRenderCommandEncoder>)handle;
    [encoder setFrontFacingWinding:rightHanded ? MTLWindingCounterClockwise : MTLWindingClockwise];
}

HL_PRIM void HL_NAME(set_cull_mode)(metal_handle *encoder, int cullMode) {
    metal_set_cull_mode_impl(encoder, cullMode);
}

HL_PRIM void HL_NAME(set_triangle_fill_mode)(metal_handle *encoder, bool wireframe) {
    metal_set_triangle_fill_mode_impl(encoder, wireframe);
}

HL_PRIM void HL_NAME(set_viewport)(metal_handle *encoder, double x, double y, double width, double height) {
    metal_set_viewport_impl(encoder, x, y, width, height);
}

HL_PRIM void HL_NAME(set_scissor_rect)(metal_handle *encoder, int x, int y, int width, int height) {
    metal_set_scissor_rect_impl(encoder, x, y, width, height);
}

HL_PRIM void HL_NAME(set_vertex_buffer)(metal_handle *encoder, metal_handle *buffer, int offset, int index) {
    metal_set_vertex_buffer_impl(encoder, buffer, offset, index);
}

HL_PRIM void HL_NAME(set_vertex_bytes)(metal_handle *encoder, vbyte *data, int length, int index) {
    metal_set_vertex_bytes_impl(encoder, data, length, index);
}

HL_PRIM void HL_NAME(set_fragment_bytes)(metal_handle *encoder, vbyte *data, int length, int index) {
    metal_set_fragment_bytes_impl(encoder, data, length, index);
}

HL_PRIM void HL_NAME(set_fragment_texture)(metal_handle *encoder, metal_handle *texture, int index) {
    metal_set_fragment_texture_impl(encoder, texture, index);
}

HL_PRIM void HL_NAME(set_fragment_buffer)(metal_handle *encoder, metal_handle *buffer, int offset, int index) {
    metal_set_fragment_buffer_impl(encoder, buffer, offset, index);
}

HL_PRIM void HL_NAME(draw_primitives)(metal_handle *encoder, int primitiveType, int vertexStart, int vertexCount) {
    metal_draw_primitives_impl(encoder, primitiveType, vertexStart, vertexCount);
}

HL_PRIM void HL_NAME(draw_indexed_primitives)(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int is32bit) {
    metal_draw_indexed_primitives_impl(encoder, primitiveType, indexCount, indexBuffer, indexOffset, is32bit);
}

HL_PRIM bool HL_NAME(draw_indexed_ranges)(metal_handle *encoder, metal_handle *indexBuffer, varray *ranges, int count, int indexLimit, int stride) {
    return metal_draw_indexed_ranges_impl(encoder, indexBuffer, ranges, count, indexLimit, stride);
}

HL_PRIM void HL_NAME(draw_indexed_primitives_instanced)(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int instanceCount, int is32bit) {
    metal_draw_indexed_primitives_instanced_impl(encoder, primitiveType, indexCount, indexBuffer, indexOffset, instanceCount, is32bit);
}

HL_PRIM void HL_NAME(end_encoding)(metal_handle *encoder, bool discardBackbufferDepth) {
    if (encoder != NULL && encoder == ctx->backbufferEncoder) {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        MTLStoreAction action = discardBackbufferDepth ? MTLStoreActionDontCare : MTLStoreActionStore;
        [renderEncoder setDepthStoreAction:action];
        [renderEncoder setStencilStoreAction:action];
        ctx->backbufferEncoder = NULL;
    }
    metal_end_encoding_impl(encoder);
}

// ============================================================================
// Thin wrappers — Compute (metal_compute.m)
// ============================================================================

HL_PRIM metal_handle* HL_NAME(create_compute_pipeline)(vbyte *source, vbyte *functionName) {
    return metal_create_compute_pipeline_impl(source, functionName);
}

HL_PRIM void HL_NAME(set_compute_pipeline)(metal_handle *pipeline) {
    metal_set_compute_pipeline_impl(pipeline);
}

HL_PRIM metal_handle *HL_NAME(begin_compute)(metal_handle *command, metal_handle *pipelineHandle, int x, int y, int z) {
    id<MTLComputePipelineState> pipeline = (__bridge id<MTLComputePipelineState>)pipelineHandle;
    if (pipeline == nil || command == NULL || x <= 0 || y <= 0 || z <= 0) return NULL;
    NSUInteger limit = pipeline.maxTotalThreadsPerThreadgroup;
    if ((NSUInteger)x > limit || (NSUInteger)y > limit / x || (NSUInteger)z > limit / x / y) return NULL;

    @autoreleasepool {
        id<MTLCommandBuffer> buffer = (__bridge id<MTLCommandBuffer>)command;
        ctx->currentCommandBuffer = (__bridge void *)buffer;
        id<MTLComputeCommandEncoder> encoder = [buffer computeCommandEncoder];
        [encoder setComputePipelineState:pipeline];
        return (__bridge_retained void *)encoder;
    }
}

HL_PRIM bool HL_NAME(set_compute_bytes)(metal_handle *handle, vbyte *data, int size, int index) {
    if (data == NULL || size <= 0) return false;
    id<MTLComputeCommandEncoder> encoder = (__bridge id<MTLComputeCommandEncoder>)handle;
    if (size <= 4096) {
        [encoder setBytes:data length:size atIndex:index];
        return true;
    }
    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
        id<MTLBuffer> buffer = [device newBufferWithBytes:data length:size options:MTLResourceStorageModeShared];
        if (buffer == nil) return false;
        [encoder setBuffer:buffer offset:0 atIndex:index];
        return true;
    }
}

HL_PRIM void HL_NAME(bind_compute_buffer)(metal_handle *handle, metal_handle *command, metal_handle *buffer, int index) {
    id<MTLBuffer> resource = (__bridge id<MTLBuffer>)buffer;
    LimenMetalBufferUse *use = metal_buffer_use(resource);
    use.stream = NO;
    use.command = (__bridge id<MTLCommandBuffer>)command;
    [(__bridge id<MTLComputeCommandEncoder>)handle setBuffer:resource offset:0 atIndex:index];
}

HL_PRIM void HL_NAME(bind_compute_texture)(metal_handle *handle, metal_handle *texture, int index) {
    metal_mark_texture_used((__bridge id<MTLTexture>)texture, (__bridge id<MTLCommandBuffer>)ctx->currentCommandBuffer, false);
    [(__bridge id<MTLComputeCommandEncoder>)handle setTexture:(__bridge id<MTLTexture>)texture atIndex:index];
}

HL_PRIM void HL_NAME(end_compute)(metal_handle *handle, int x, int y, int z, int tx, int ty, int tz) {
    id<MTLComputeCommandEncoder> encoder = (__bridge_transfer id<MTLComputeCommandEncoder>)handle;
    if (x > 0)
        [encoder dispatchThreadgroups:MTLSizeMake(x, y, z) threadsPerThreadgroup:MTLSizeMake(tx, ty, tz)];
    [encoder endEncoding];
}

HL_PRIM void HL_NAME(set_compute_buffer)(metal_handle *buffer, int index) {
    metal_set_compute_buffer_impl(buffer, index);
}

HL_PRIM void HL_NAME(set_compute_texture)(metal_handle *texture, int index) {
    metal_set_compute_texture_impl(texture, index);
}

HL_PRIM bool HL_NAME(dispatch_compute)(metal_handle *cmdBuffer, int x, int y, int z) {
    return metal_dispatch_compute_impl(cmdBuffer, x, y, z);
}

HL_PRIM void HL_NAME(memory_barrier)(metal_handle *cmdBuffer) {
    metal_memory_barrier_impl(cmdBuffer);
}

// ============================================================================
// All DEFINE_PRIM registrations — consolidated
// ============================================================================

// Context lifecycle
DEFINE_PRIM(_VOID, init, _NO_ARG);
DEFINE_PRIM(_BOOL, setup_window, TWIN);
DEFINE_PRIM(_VOID, shutdown, _NO_ARG);

// Command buffer management
DEFINE_PRIM(_BOOL, is_available, _NO_ARG);
DEFINE_PRIM(_BOOL, is_initialized, _NO_ARG);
DEFINE_PRIM(_VOID, set_vsync, _BOOL);
DEFINE_PRIM(_I32, render_layout_id, _NO_ARG);
DEFINE_PRIM(_I32, profile_sequence, _NO_ARG);
DEFINE_PRIM(_I32, profile_window_state, TWIN);
DEFINE_PRIM(_BOOL, profile_sampling, _NO_ARG);
DEFINE_PRIM(_VOID, profile_target, _STRING);
DEFINE_PRIM(_VOID, profile_shader, _I32);
DEFINE_PRIM(_BYTES, device_name, _NO_ARG);
DEFINE_PRIM(THANDLE, create_command_buffer, _NO_ARG);
DEFINE_PRIM(_BOOL, commit_command_buffer, THANDLE);
DEFINE_PRIM(_VOID, commit_offscreen, THANDLE _BOOL);

// Resources
DEFINE_PRIM(THANDLE, create_buffer, _I32 _I32);
DEFINE_PRIM(_BOOL, upload_buffer_data, THANDLE _BYTES _I32 _I32);
DEFINE_PRIM(THANDLE, update_buffer, THANDLE _BYTES _I32 _I32);
DEFINE_PRIM(THANDLE, create_texture, _I32 _I32 _I32 _I32 _BOOL _BOOL _I32);
DEFINE_PRIM(_BOOL, upload_texture_data, THANDLE _BYTES _I32 _I32 _I32 _I32);
DEFINE_PRIM(_BOOL, capture_texture_pixels, THANDLE _BYTES _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, generate_mipmaps, THANDLE);
DEFINE_PRIM(_VOID, dispose_buffer, THANDLE);
DEFINE_PRIM(_VOID, dispose_texture, THANDLE);
DEFINE_PRIM(THANDLE, create_sampler_state, _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, dispose_sampler, THANDLE);
DEFINE_PRIM(_VOID, set_fragment_samplers, THANDLE _ARR);
DEFINE_PRIM(_VOID, set_fragment_sampler, THANDLE THANDLE _I32);

// Pipeline
DEFINE_PRIM(THANDLE, compile_shader, _STRING _I32);
DEFINE_PRIM(THANDLE, create_render_pipeline, THANDLE THANDLE _STRING _I32 _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(THANDLE, create_compute_pipeline_from_function, THANDLE);
DEFINE_PRIM(_VOID, dispose_pipeline, THANDLE);

// Render pass and encoding
DEFINE_PRIM(THANDLE, begin_render_pass, THANDLE _BOOL _F64 _F64 _F64 _F64 _F64 _I32);
DEFINE_PRIM(THANDLE, begin_texture_render_pass, THANDLE THANDLE _I32 _I32 _I32 _I32 THANDLE _I32 _I32 _I32 _F64 _I32);
DEFINE_PRIM(THANDLE, begin_mrt_render_pass, THANDLE _ARR _I32 _I32 _I32 _I32 _I32 THANDLE _I32 _F64 _I32);
DEFINE_PRIM(THANDLE, begin_depth_render_pass, THANDLE THANDLE _I32 _BOOL _F64 _I32);
DEFINE_PRIM(_VOID, set_render_pipeline_state, THANDLE THANDLE);
DEFINE_PRIM(_VOID, set_depth_state, THANDLE _BOOL _BOOL);
DEFINE_PRIM(_VOID, set_stencil_state, THANDLE _I32 _BOOL _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, set_right_handed_winding, THANDLE _BOOL);
DEFINE_PRIM(_VOID, set_cull_mode, THANDLE _I32);
DEFINE_PRIM(_VOID, set_triangle_fill_mode, THANDLE _BOOL);
DEFINE_PRIM(_VOID, set_viewport, THANDLE _F64 _F64 _F64 _F64);
DEFINE_PRIM(_VOID, set_scissor_rect, THANDLE _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, set_vertex_buffer, THANDLE THANDLE _I32 _I32);
DEFINE_PRIM(_VOID, set_vertex_bytes, THANDLE _BYTES _I32 _I32);
DEFINE_PRIM(_VOID, set_fragment_bytes, THANDLE _BYTES _I32 _I32);
DEFINE_PRIM(_VOID, set_fragment_texture, THANDLE THANDLE _I32);
DEFINE_PRIM(_VOID, set_fragment_buffer, THANDLE THANDLE _I32 _I32);
DEFINE_PRIM(_VOID, draw_primitives, THANDLE _I32 _I32 _I32);
DEFINE_PRIM(_VOID, draw_indexed_primitives, THANDLE _I32 _I32 THANDLE _I32 _I32);
DEFINE_PRIM(_BOOL, draw_indexed_ranges, THANDLE THANDLE _ARR _I32 _I32 _I32);
DEFINE_PRIM(_VOID, draw_indexed_primitives_instanced, THANDLE _I32 _I32 THANDLE _I32 _I32 _I32);
DEFINE_PRIM(_VOID, end_encoding, THANDLE _BOOL);

// Compute
DEFINE_PRIM(THANDLE, create_compute_pipeline, _BYTES _BYTES);
DEFINE_PRIM(_VOID, set_compute_pipeline, THANDLE);
DEFINE_PRIM(THANDLE, begin_compute, THANDLE THANDLE _I32 _I32 _I32);
DEFINE_PRIM(_BOOL, set_compute_bytes, THANDLE _BYTES _I32 _I32);
DEFINE_PRIM(_VOID, bind_compute_buffer, THANDLE THANDLE THANDLE _I32);
DEFINE_PRIM(_VOID, bind_compute_texture, THANDLE THANDLE _I32);
DEFINE_PRIM(_VOID, end_compute, THANDLE _I32 _I32 _I32 _I32 _I32 _I32);
DEFINE_PRIM(_VOID, set_compute_buffer, THANDLE _I32);
DEFINE_PRIM(_VOID, set_compute_texture, THANDLE _I32);
DEFINE_PRIM(_BOOL, dispatch_compute, THANDLE _I32 _I32 _I32);
DEFINE_PRIM(_VOID, memory_barrier, THANDLE);

// Logging
DEFINE_PRIM(_VOID, set_debug_level, _I32);


