#include "metal.h"
#include "../../common/native/indexed_commands.h"

// ============================================================================
// Render pass and encoding functions
// ============================================================================

static MTLRenderPassDescriptor *metal_render_pass_descriptor(unsigned kind) {
    MTLRenderPassDescriptor *pass = (__bridge MTLRenderPassDescriptor *)ctx->passDescriptors[kind];
    if (pass == nil || !ctx->reusePassDescriptors) {
        pass = [MTLRenderPassDescriptor renderPassDescriptor];
        METAL_PROFILE(passDescriptors, 1);
        if (ctx->reusePassDescriptors) ctx->passDescriptors[kind] = (__bridge_retained void *)pass;
    }
    return pass;
}

static bool metal_has_stencil(MTLPixelFormat format) {
    return format == MTLPixelFormatDepth32Float_Stencil8;
}

static void metal_attach_depth(MTLRenderPassDescriptor *pass, id<MTLTexture> texture,
                               MTLLoadAction load, double clear, int layer, bool readOnly, int stencil) {
    if (texture == nil) return;
    pass.depthAttachment.texture = texture;
    pass.depthAttachment.slice = layer;
    pass.depthAttachment.loadAction = load;
    pass.depthAttachment.clearDepth = MIN(1.0, MAX(0.0, clear));
    pass.depthAttachment.storeAction = MTLStoreActionStore;
    if (metal_has_stencil(texture.pixelFormat)) {
        pass.stencilAttachment.texture = texture;
        pass.stencilAttachment.slice = layer;
        bool clearStencil = !readOnly && stencil >= 0;
        pass.stencilAttachment.loadAction = clearStencil ? MTLLoadActionClear : MTLLoadActionLoad;
        pass.stencilAttachment.clearStencil = clearStencil ? (uint32_t)stencil : 0;
        pass.stencilAttachment.storeAction = MTLStoreActionStore;
    }
    ctx->depthReadOnly = readOnly;
}

static id<MTLRenderCommandEncoder> metal_new_render_encoder(id<MTLCommandBuffer> command,
                                                            MTLRenderPassDescriptor *pass, int colorCount) {
    id<MTLTexture> target = pass.depthAttachment.texture;
    NSUInteger level = pass.depthAttachment.level;
    memset(ctx->colorFormats, 0, sizeof(ctx->colorFormats));
    metal_mark_texture_used(pass.depthAttachment.texture, command, pass.depthAttachment.loadAction != MTLLoadActionLoad);
    metal_mark_texture_used(pass.stencilAttachment.texture, command, pass.stencilAttachment.loadAction != MTLLoadActionLoad);
    for (int i = 0; i < colorCount; i++) {
        MTLRenderPassColorAttachmentDescriptor *color = pass.colorAttachments[i];
        metal_mark_texture_used(color.texture, command, color.loadAction != MTLLoadActionLoad);
        ctx->colorFormats[i] = color.texture.pixelFormat;
        if (target == nil && color.texture != nil) {
            target = color.texture;
            level = color.level;
        }
    }
    ctx->depthFormat = pass.depthAttachment.texture.pixelFormat;
    ctx->stencilFormat = pass.stencilAttachment.texture.pixelFormat;
    ctx->targetWidth = MAX(1, target.width >> level);
    ctx->targetHeight = MAX(1, target.height >> level);
    if (ctx->depthFormat == MTLPixelFormatInvalid)
        ctx->depthReadOnly = false;
    METAL_PROFILE(passes, 1);
    metal_profile_begin_pass(pass);
    double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
    id<MTLRenderCommandEncoder> encoder = [command renderCommandEncoderWithDescriptor:pass];
    if (ctx->profileDetailed) ctx->profile.encoderCreate += CACurrentMediaTime() - start;
    if (ctx->reusePassDescriptors) {
        // The encoder captures its attachments. The cached description must not
        // keep old drawables, disposed targets or counter buffers alive.
        for (int i = 0; i < colorCount; i++) pass.colorAttachments[i].texture = nil;
        pass.depthAttachment.texture = nil;
        pass.stencilAttachment.texture = nil;
        if (ctx->profileDetailed) pass.sampleBufferAttachments[0].sampleBuffer = nil;
    }
    return encoder;
}

metal_handle* metal_begin_render_pass_impl(metal_handle *cmdBuffer, bool clearColor, double r, double g, double b,
                                             double a, double clearDepth, int stencil) {
    if (ctx == NULL || cmdBuffer == NULL) return NULL;

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        if (ctx->profileEnabled) ctx->profile.windowState = limen_metal_window_state(ctx->window);
        id<CAMetalDrawable> drawable = (__bridge id<CAMetalDrawable>)ctx->currentDrawable;
        if (drawable == nil) {
            double sizeStart = ctx->profileDetailed ? CACurrentMediaTime() : 0;
            bool sized = metal_update_drawable_size();
            if (ctx->profileDetailed) ctx->profile.sizeQuery += CACurrentMediaTime() - sizeStart;
            if (!sized) return NULL;
            CAMetalLayer *layer = (__bridge CAMetalLayer *)ctx->layer;
            CFTimeInterval start = ctx->profileEnabled ? CACurrentMediaTime() : 0;
            drawable = [layer nextDrawable];
            METAL_PROFILE(drawable, CACurrentMediaTime() - start);
            if (drawable == nil) return NULL;
            if (ctx->profileEnabled) {
                ctx->profile.drawableAcquired = CACurrentMediaTime();
                ctx->profile.passesBeforeDrawable = ctx->profile.passes;
                ctx->profile.drawsBeforeDrawable = ctx->profile.draws;
            }
            ctx->currentDrawable = (__bridge_retained void *)drawable;
        }
        id<MTLTexture> backbuffer = drawable.texture;
        ctx->currentCommandBuffer = (__bridge void *)commandBuffer;

        MTLRenderPassDescriptor *pass = metal_render_pass_descriptor(0);
        pass.colorAttachments[0].texture = backbuffer;
        pass.colorAttachments[0].loadAction = clearColor ? MTLLoadActionClear : MTLLoadActionLoad;
        pass.colorAttachments[0].storeAction = MTLStoreActionStore;
        pass.colorAttachments[0].clearColor = MTLClearColorMake(r, g, b, a);
        metal_attach_depth(pass, (__bridge id<MTLTexture>)ctx->depthTexture,
                           clearDepth >= 0 ? MTLLoadActionClear : MTLLoadActionLoad,
                           clearDepth, 0, false, stencil);
        pass.depthAttachment.storeAction = MTLStoreActionUnknown;
        pass.stencilAttachment.storeAction = MTLStoreActionUnknown;

        id<MTLRenderCommandEncoder> encoder = metal_new_render_encoder(commandBuffer, pass, 1);
        if (encoder == nil) return NULL;

        [encoder setFrontFacingWinding:MTLWindingClockwise];
        ctx->backbufferEncoder = (__bridge void *)encoder;
        return (metal_handle *)(__bridge_retained void *)encoder;
    }
}

metal_handle* metal_begin_texture_render_pass_impl(metal_handle *cmdBuffer, metal_handle *texture, int r, int g, int b, int a, metal_handle *depthTexParam, int layer, int mipLevel, int depthAction, double clearDepth, int stencil) {
    if (ctx == NULL || cmdBuffer == NULL || texture == NULL) {
        metal_debug_log("ERROR: begin_texture_render_pass() - invalid parameters");
        return NULL;
    }

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texture;
        
        // Update command buffer reference
        ctx->currentCommandBuffer = (__bridge void*)commandBuffer;

        MTLRenderPassDescriptor *renderPassDescriptor = metal_render_pass_descriptor(1);
        MTLLoadAction colorLoad = a < 0 ? MTLLoadActionLoad : MTLLoadActionClear;
        MTLLoadAction depthLoad = depthAction < 0 ? MTLLoadActionDontCare :
                                  depthAction == 1 ? MTLLoadActionClear : MTLLoadActionLoad;

        renderPassDescriptor.colorAttachments[0].texture = metalTexture;
        renderPassDescriptor.colorAttachments[0].slice = layer;
        renderPassDescriptor.colorAttachments[0].level = mipLevel;
        renderPassDescriptor.colorAttachments[0].loadAction = colorLoad;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(r/255.0, g/255.0, b/255.0, a/255.0);
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLTexture> depth = (__bridge id<MTLTexture>)depthTexParam;
        if (depth != nil && depth.width == MAX(1, metalTexture.width >> mipLevel)
                         && depth.height == MAX(1, metalTexture.height >> mipLevel)) {
            metal_attach_depth(renderPassDescriptor, depth, depthLoad, clearDepth, 0, depthAction == 2, stencil);
        }

        id<MTLRenderCommandEncoder> encoder = metal_new_render_encoder(commandBuffer, renderPassDescriptor, 1);
        if (encoder == NULL) {
            metal_debug_log("ERROR: begin_texture_render_pass() - failed to create encoder!");
            return NULL;
        }

        // Set winding order to counter-clockwise (Heaps/OpenGL convention)
        [encoder setFrontFacingWinding:MTLWindingClockwise];

        metal_debug_log("begin_texture_render_pass() - SUCCESS");
        return (metal_handle*)(__bridge_retained void*)encoder;
    }
}

metal_handle* metal_begin_mrt_render_pass_impl(metal_handle *cmdBuffer, varray *textures, int r, int g, int b, int a, int clearMask, metal_handle *depthTex, int depthAction, double clearDepth, int stencil) {
    if (ctx == NULL || cmdBuffer == NULL || textures == NULL) return NULL;
    
    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        
        // Update command buffer reference
        ctx->currentCommandBuffer = (__bridge void*)commandBuffer;
        
        int texCount = textures->size;
        if (texCount < 1 || texCount > 8) return NULL;
        
        MTLRenderPassDescriptor *renderPassDescriptor = metal_render_pass_descriptor(2);
        
        metal_handle **texPtrs = hl_aptr(textures, metal_handle*);
        id<MTLTexture> firstTexture = nil;
        
        // Set up each color attachment and store their pixel formats
        // CRITICAL: MRT requires per-attachment pixel format tracking for correct pipeline creation
        for (int i = 0; i < texCount; i++) {
            renderPassDescriptor.colorAttachments[i].texture = nil;
            if (texPtrs[i] == NULL) continue;
            
            id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texPtrs[i];
            if (i == 0) firstTexture = metalTexture;
            
            renderPassDescriptor.colorAttachments[i].texture = metalTexture;
            
            if ((clearMask & (1 << i)) == 0) {
                renderPassDescriptor.colorAttachments[i].loadAction = MTLLoadActionLoad;
            } else {
                renderPassDescriptor.colorAttachments[i].loadAction = MTLLoadActionClear;
                renderPassDescriptor.colorAttachments[i].clearColor = MTLClearColorMake(r/255.0, g/255.0, b/255.0, a/255.0);
            }
            renderPassDescriptor.colorAttachments[i].storeAction = MTLStoreActionStore;
            
            metal_debug_log("MRT attachment %d: format=%d (%s)", i, (int)metalTexture.pixelFormat,
                metalTexture.pixelFormat == MTLPixelFormatRGBA16Float ? "RGBA16F" :
                metalTexture.pixelFormat == MTLPixelFormatRGBA8Unorm ? "RGBA8" :
                metalTexture.pixelFormat == MTLPixelFormatR32Float ? "R32F" :
                metalTexture.pixelFormat == MTLPixelFormatBGRA8Unorm ? "BGRA8" : "other");
        }
        
        id<MTLTexture> depth = (__bridge id<MTLTexture>)depthTex;
        if (depth != nil && depth.width == firstTexture.width && depth.height == firstTexture.height)
            metal_attach_depth(renderPassDescriptor, depth,
                               depthAction == 1 ? MTLLoadActionClear : MTLLoadActionLoad,
                               clearDepth, 0, depthAction == 2, stencil);

        id<MTLRenderCommandEncoder> encoder = metal_new_render_encoder(commandBuffer, renderPassDescriptor, texCount);
        if (encoder == NULL) {
            metal_debug_log("ERROR: begin_mrt_render_pass() - failed to create encoder!");
            return NULL;
        }
        
        // Set winding order
        [encoder setFrontFacingWinding:MTLWindingClockwise];
        
        metal_debug_log("begin_mrt_render_pass() - SUCCESS with %d targets", texCount);
        return (metal_handle*)(__bridge_retained void*)encoder;
    }
}

metal_handle* metal_begin_depth_render_pass_impl(metal_handle *cmdBuffer, metal_handle *depthTexture, int layer, bool clear, double clearDepth, int stencil) {
    if (ctx == NULL || cmdBuffer == NULL || depthTexture == NULL) {
        metal_debug_log("ERROR: begin_depth_render_pass() - invalid parameters");
        return NULL;
    }

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        id<MTLTexture> metalDepthTexture = (__bridge id<MTLTexture>)depthTexture;

        // Update command buffer reference
        ctx->currentCommandBuffer = (__bridge void*)commandBuffer;

        // Create render pass descriptor with ONLY depth attachment (no color)
        MTLRenderPassDescriptor *renderPassDescriptor = metal_render_pass_descriptor(3);

        metal_attach_depth(renderPassDescriptor, metalDepthTexture,
                           clear ? MTLLoadActionClear : MTLLoadActionLoad, clearDepth, layer, false, stencil);

        id<MTLRenderCommandEncoder> encoder = metal_new_render_encoder(commandBuffer, renderPassDescriptor, 0);
        if (encoder == NULL) {
            metal_debug_log("ERROR: begin_depth_render_pass() - failed to create encoder!");
            return NULL;
        }

        // Set winding order to counter-clockwise (Heaps/OpenGL convention)
        [encoder setFrontFacingWinding:MTLWindingClockwise];

        metal_debug_log("begin_depth_render_pass() - SUCCESS");
        return (metal_handle*)(__bridge_retained void*)encoder;
    }
}

void metal_set_render_pipeline_state_impl(metal_handle *encoder, metal_handle *pipeline) {
    if (encoder == NULL || pipeline == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLRenderPipelineState> pipelineState = (__bridge id<MTLRenderPipelineState>)pipeline;

        [renderEncoder setRenderPipelineState:pipelineState];
        
        // Note: Depth state is now set separately via set_depth_state()
        metal_debug_log("set_render_pipeline_state() - SUCCESS");
    }
}

void metal_set_depth_state_impl(metal_handle *encoder, bool depthTest, bool depthWrite) {
    if (encoder == NULL || ctx == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

        // Lazily initialise cache if needed
        if (ctx->depthStencilStateCache == NULL) {
            NSMutableDictionary *cache = [[NSMutableDictionary alloc] init];
            ctx->depthStencilStateCache = (__bridge_retained void*)cache;
        }
        NSMutableDictionary *cache = (__bridge NSMutableDictionary*)ctx->depthStencilStateCache;

        // Build cache key from depthTest and depthWrite
        NSString *cacheKey = [NSString stringWithFormat:@"%d-%d", depthTest ? 1 : 0, depthWrite ? 1 : 0];

        id<MTLDepthStencilState> depthState = cache[cacheKey];

        if (depthState == nil) {
            MTLDepthStencilDescriptor *descriptor = [[MTLDepthStencilDescriptor alloc] init];
            descriptor.depthCompareFunction = depthTest ? MTLCompareFunctionLessEqual : MTLCompareFunctionAlways;
            descriptor.depthWriteEnabled = depthWrite;

            depthState = [device newDepthStencilStateWithDescriptor:descriptor];
            if (depthState) {
                cache[cacheKey] = depthState;
                metal_debug_log("set_depth_state() - Created and cached state (test=%d, write=%d)", depthTest, depthWrite);
            }
        }

        if (depthState) {
            [renderEncoder setDepthStencilState:depthState];
        }
    }
}

static const MTLCompareFunction compareFuncs[] = {
        MTLCompareFunctionAlways,      // 0: Always
        MTLCompareFunctionNever,       // 1: Never
        MTLCompareFunctionEqual,       // 2: Equal
        MTLCompareFunctionNotEqual,    // 3: NotEqual
        MTLCompareFunctionGreater,     // 4: Greater
        MTLCompareFunctionGreaterEqual,// 5: GreaterEqual
        MTLCompareFunctionLess,        // 6: Less
        MTLCompareFunctionLessEqual    // 7: LessEqual
    };

void metal_set_stencil_state_impl(metal_handle *encoder, int depthCompareFunc, bool depthWrite,
    int frontFunc, int frontSTfail, int frontDPfail, int frontPass,
    int backFunc, int backSTfail, int backDPfail, int backPass,
    int reference, int readMask, int writeMask) {

    if (encoder == NULL || ctx == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

        if (ctx->depthFormat == MTLPixelFormatInvalid)
            depthCompareFunc = 0;
        depthWrite = depthWrite && ctx->depthFormat != MTLPixelFormatInvalid && !ctx->depthReadOnly;
        bool hasStencil = ctx->stencilFormat != MTLPixelFormatInvalid;
        if (ctx->depthReadOnly)
            writeMask = 0;

        bool usesStencil = hasStencil &&
            (frontFunc != 0 || backFunc != 0 || frontSTfail != 0 || frontDPfail != 0 ||
             frontPass != 0 || backSTfail != 0 || backDPfail != 0 || backPass != 0);
        if (!usesStencil) {
            int key = depthCompareFunc * 2 + depthWrite;
            id<MTLDepthStencilState> state = (__bridge id<MTLDepthStencilState>)ctx->depthStates[key];
            if (state == nil) {
                MTLDepthStencilDescriptor *descriptor = [MTLDepthStencilDescriptor new];
                descriptor.depthCompareFunction = compareFuncs[depthCompareFunc];
                descriptor.depthWriteEnabled = depthWrite;
                state = [device newDepthStencilStateWithDescriptor:descriptor];
                ctx->depthStates[key] = (__bridge_retained void *)state;
            }
            [renderEncoder setDepthStencilState:state];
            return;
        }

        // Lazily initialise cache if needed
        if (ctx->depthStencilStateCache == NULL) {
            NSMutableDictionary *cache = [[NSMutableDictionary alloc] init];
            ctx->depthStencilStateCache = (__bridge_retained void*)cache;
        }
        NSMutableDictionary *cache = (__bridge NSMutableDictionary*)ctx->depthStencilStateCache;

        // Create cache key from all parameters
        // Format: "depthFunc-depthWrite-frontFunc-frontFail-frontDepthFail-frontPass-backFunc-backFail-backDepthFail-backPass-readMask-writeMask"
        NSString *cacheKey = [NSString stringWithFormat:@"%d-%d-%d-%d-%d-%d-%d-%d-%d-%d-%d-%d",
            depthCompareFunc, depthWrite ? 1 : 0,
            frontFunc, frontSTfail, frontDPfail, frontPass,
            backFunc, backSTfail, backDPfail, backPass,
            readMask, writeMask];

        // Check if state exists in cache
        id<MTLDepthStencilState> depthStencilState = cache[cacheKey];
        
        if (depthStencilState == nil) {
            // State not cached - create new one
            MTLDepthStencilDescriptor *descriptor = [[MTLDepthStencilDescriptor alloc] init];

            // Map Heaps Compare enum to Metal compare function
            // Compare enum: Always=0, Never=1, Equal=2, NotEqual=3, Greater=4, GreaterEqual=5, Less=6, LessEqual=7


            // Set depth compare function from the parameter
            descriptor.depthCompareFunction = compareFuncs[depthCompareFunc];
            descriptor.depthWriteEnabled = depthWrite ? YES : NO;

            // Map Heaps StencilOp enum to Metal stencil operation
            // StencilOp enum: Keep=0, Zero=1, Replace=2, Increment=3, IncrementWrap=4, Decrement=5, DecrementWrap=6, Invert=7
            MTLStencilOperation stencilOps[] = {
                MTLStencilOperationKeep,           // 0: Keep
                MTLStencilOperationZero,           // 1: Zero
                MTLStencilOperationReplace,        // 2: Replace
                MTLStencilOperationIncrementClamp, // 3: Increment
                MTLStencilOperationIncrementWrap,  // 4: IncrementWrap
                MTLStencilOperationDecrementClamp, // 5: Decrement
                MTLStencilOperationDecrementWrap,  // 6: DecrementWrap
                MTLStencilOperationInvert          // 7: Invert
            };

            // Front face stencil
            MTLStencilDescriptor *frontStencil = [[MTLStencilDescriptor alloc] init];
            frontStencil.stencilCompareFunction = compareFuncs[frontFunc];
            frontStencil.stencilFailureOperation = stencilOps[frontSTfail];
            frontStencil.depthFailureOperation = stencilOps[frontDPfail];
            frontStencil.depthStencilPassOperation = stencilOps[frontPass];
            frontStencil.readMask = (uint32_t)readMask;
            frontStencil.writeMask = (uint32_t)writeMask;
            descriptor.frontFaceStencil = frontStencil;

            // Back face stencil
            MTLStencilDescriptor *backStencil = [[MTLStencilDescriptor alloc] init];
            backStencil.stencilCompareFunction = compareFuncs[backFunc];
            backStencil.stencilFailureOperation = stencilOps[backSTfail];
            backStencil.depthFailureOperation = stencilOps[backDPfail];
            backStencil.depthStencilPassOperation = stencilOps[backPass];
            backStencil.readMask = (uint32_t)readMask;
            backStencil.writeMask = (uint32_t)writeMask;
            descriptor.backFaceStencil = backStencil;

            // Create the depth stencil state
            depthStencilState = [device newDepthStencilStateWithDescriptor:descriptor];
            
            // Cache it for future use
            if (depthStencilState) {
                cache[cacheKey] = depthStencilState;
                metal_debug_log("Created and cached new depth-stencil state: %s", [cacheKey UTF8String]);
            }
        }

        // Apply the state (cached or newly created)
        if (depthStencilState) {
            [renderEncoder setDepthStencilState:depthStencilState];
            [renderEncoder setStencilReferenceValue:(uint32_t)reference];
        }
    }
}

void metal_set_cull_mode_impl(metal_handle *encoder, int cullMode) {
    if (encoder == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        // Metal cull modes: 0 = None, 1 = Front, 2 = Back
        MTLCullMode metalCullMode;
        switch(cullMode) {
            case 0: metalCullMode = MTLCullModeNone; break;
            case 1: metalCullMode = MTLCullModeFront; break;
            case 2: metalCullMode = MTLCullModeBack; break;
            default: metalCullMode = MTLCullModeNone; break;
        }

        [renderEncoder setCullMode:metalCullMode];
        metal_debug_log("set_cull_mode() - Mode: %d (%s)", cullMode,
            cullMode == 0 ? "None" : cullMode == 1 ? "Front" : "Back");
    }
}

void metal_set_triangle_fill_mode_impl(metal_handle *encoder, bool wireframe) {
    if (encoder == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        // Metal triangle fill modes: MTLTriangleFillModeFill (solid) or MTLTriangleFillModeLines (wireframe)
        MTLTriangleFillMode fillMode = wireframe ? MTLTriangleFillModeLines : MTLTriangleFillModeFill;

        [renderEncoder setTriangleFillMode:fillMode];
        metal_debug_log("set_triangle_fill_mode() - Mode: %s", wireframe ? "Wireframe" : "Solid");
    }
}

void metal_set_viewport_impl(metal_handle *encoder, double x, double y, double width, double height) {
    if (encoder == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        MTLViewport viewport = {x, y, width, height, 0.0, 1.0};
        METAL_PROFILE(viewportSets, 1);
        [renderEncoder setViewport:viewport];
        metal_debug_log("set_viewport() - SUCCESS (x=%.2f, y=%.2f, width=%.2f, height=%.2f)", x, y, width, height);
    }
}

void metal_set_scissor_rect_impl(metal_handle *encoder, int x, int y, int width, int height) {
    if (encoder == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        int maxX = (int)ctx->targetWidth;
        int maxY = (int)ctx->targetHeight;
        int right = width < 0 ? maxX : (int)MIN((int64_t)x + width, maxX);
        int bottom = height < 0 ? maxY : (int)MIN((int64_t)y + height, maxY);
        x = MIN(MAX(x, 0), maxX);
        y = MIN(MAX(y, 0), maxY);
        MTLScissorRect scissor = {(NSUInteger)x, (NSUInteger)y,
            (NSUInteger)MAX(0, right - x), (NSUInteger)MAX(0, bottom - y)};
        METAL_PROFILE(scissorSets, 1);
        [renderEncoder setScissorRect:scissor];
        metal_debug_log("set_scissor_rect() - SUCCESS (x=%d, y=%d, width=%d, height=%d)", x, y, width, height);
    }
}

void metal_set_vertex_buffer_impl(metal_handle *encoder, metal_handle *buffer, int offset, int index) {
    if (encoder == NULL || buffer == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLBuffer> metalBuffer = (__bridge id<MTLBuffer>)buffer;

        metal_mark_buffer_used(metalBuffer);
        [renderEncoder setVertexBuffer:metalBuffer offset:offset atIndex:index];
        metal_debug_log("set_vertex_buffer() - SUCCESS (offset=%d, index=%d)", offset, index);
    }
}

void metal_set_vertex_bytes_impl(metal_handle *encoder, vbyte *data, int length, int index) {
    if (encoder == NULL || data == NULL || length <= 0) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        METAL_PROFILE(constantBytes, length);
        if (length <= 4096) {
            [renderEncoder setVertexBytes:data length:length atIndex:index];
        } else {
            id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
            id<MTLBuffer> buffer = [device newBufferWithBytes:data length:length options:MTLResourceStorageModeShared];
            if (buffer) METAL_PROFILE(buffers, 1);
            if (buffer == nil) hl_error("Failed to allocate Metal shader buffer");
            [renderEncoder setVertexBuffer:buffer offset:0 atIndex:index];
        }
    }
}

void metal_set_fragment_bytes_impl(metal_handle *encoder, vbyte *data, int length, int index) {
    if (encoder == NULL || data == NULL || length <= 0) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        METAL_PROFILE(constantBytes, length);
        if (length <= 4096) {
            [renderEncoder setFragmentBytes:data length:length atIndex:index];
        } else {
            id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
            id<MTLBuffer> buffer = [device newBufferWithBytes:data length:length options:MTLResourceStorageModeShared];
            if (buffer) METAL_PROFILE(buffers, 1);
            if (buffer == nil) hl_error("Failed to allocate Metal shader buffer");
            [renderEncoder setFragmentBuffer:buffer offset:0 atIndex:index];
        }
    }
}

void metal_set_fragment_texture_impl(metal_handle *encoder, metal_handle *texture, int index) {
    if (encoder == NULL || texture == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texture;
        metal_mark_texture_used(metalTexture, (__bridge id<MTLCommandBuffer>)ctx->currentCommandBuffer, false);
        [renderEncoder setFragmentTexture:metalTexture atIndex:index];
        
        // Enhanced debug: log texture details
        metal_debug_log("set_fragment_texture() - SUCCESS (index=%d, tex=%p, %lux%lu, format=%d)", 
            index, metalTexture, 
            (unsigned long)metalTexture.width, (unsigned long)metalTexture.height,
            (int)metalTexture.pixelFormat);
    }
}

void metal_set_fragment_buffer_impl(metal_handle *encoder, metal_handle *buffer, int offset, int index) {
    if (encoder == NULL || buffer == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLBuffer> metalBuffer = (__bridge id<MTLBuffer>)buffer;

        metal_mark_buffer_used(metalBuffer);
        [renderEncoder setFragmentBuffer:metalBuffer offset:offset atIndex:index];
        metal_debug_log("set_fragment_buffer() - SUCCESS (offset=%d, index=%d)", offset, index);
    }
}

void metal_draw_primitives_impl(metal_handle *encoder, int primitiveType, int vertexStart, int vertexCount) {
    if (encoder == NULL || vertexCount <= 0) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        MTLPrimitiveType metalPrimitiveType = MTLPrimitiveTypeTriangle;
        switch (primitiveType) {
            case 0: metalPrimitiveType = MTLPrimitiveTypePoint; break;
            case 1: metalPrimitiveType = MTLPrimitiveTypeLine; break;
            case 2: metalPrimitiveType = MTLPrimitiveTypeLineStrip; break;
            case 3: metalPrimitiveType = MTLPrimitiveTypeTriangle; break;
            case 4: metalPrimitiveType = MTLPrimitiveTypeTriangleStrip; break;
        }

        metal_profile_draw(1);
        [renderEncoder drawPrimitives:metalPrimitiveType vertexStart:vertexStart vertexCount:vertexCount];
        metal_debug_log("draw_primitives() - SUCCESS (primitiveType=%d, vertexStart=%d, vertexCount=%d)", primitiveType, vertexStart, vertexCount);
    }
}

void metal_draw_indexed_primitives_impl(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int is32bit) {
    if (encoder == NULL || indexBuffer == NULL || indexCount <= 0) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLBuffer> metalIndexBuffer = (__bridge id<MTLBuffer>)indexBuffer;

        MTLPrimitiveType metalPrimitiveType = MTLPrimitiveTypeTriangle;
        switch (primitiveType) {
            case 0: metalPrimitiveType = MTLPrimitiveTypePoint; break;
            case 1: metalPrimitiveType = MTLPrimitiveTypeLine; break;
            case 2: metalPrimitiveType = MTLPrimitiveTypeLineStrip; break;
            case 3: metalPrimitiveType = MTLPrimitiveTypeTriangle; break;
            case 4: metalPrimitiveType = MTLPrimitiveTypeTriangleStrip; break;
        }

        MTLIndexType indexType = is32bit ? MTLIndexTypeUInt32 : MTLIndexTypeUInt16;
        metal_profile_draw(1);
        metal_mark_buffer_used(metalIndexBuffer);
        [renderEncoder drawIndexedPrimitives:metalPrimitiveType
                                  indexCount:indexCount
                                   indexType:indexType
                                 indexBuffer:metalIndexBuffer
                           indexBufferOffset:indexOffset];
        metal_debug_log("draw_indexed_primitives() - SUCCESS (primitiveType=%d, indexCount=%d, indexOffset=%d, is32bit=%d)", primitiveType, indexCount, indexOffset, is32bit);
    }
}

bool metal_draw_indexed_ranges_impl(metal_handle *encoder, metal_handle *indexBuffer, varray *ranges, int count, int indexLimit, int stride) {
    if (encoder == NULL || indexBuffer == NULL || (stride != 2 && stride != 4)) return false;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLBuffer> metalIndexBuffer = (__bridge id<MTLBuffer>)indexBuffer;
        if (indexLimit < 0 || (NSUInteger)indexLimit > metalIndexBuffer.length / stride) return false;
        const int32_t *range = limen_validate_indexed_ranges(ranges, count, indexLimit);
        if (range == NULL) return false;

        MTLIndexType indexType = stride == 4 ? MTLIndexTypeUInt32 : MTLIndexTypeUInt16;
        metal_profile_draw(count);
        metal_mark_buffer_used(metalIndexBuffer);
        for (int i = 0; i < count; i++, range += LIMEN_INDEXED_RANGES_STRIDE) {
            [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                      indexCount:range[1]
                                       indexType:indexType
                                     indexBuffer:metalIndexBuffer
                               indexBufferOffset:(NSUInteger)range[0] * stride];
        }
        return true;
    }
}

void metal_draw_indexed_primitives_instanced_impl(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int instanceCount, int is32bit) {
    if (encoder == NULL || indexBuffer == NULL || indexCount <= 0 || instanceCount <= 0) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLBuffer> metalIndexBuffer = (__bridge id<MTLBuffer>)indexBuffer;

        MTLPrimitiveType metalPrimitiveType = MTLPrimitiveTypeTriangle;
        switch (primitiveType) {
            case 0: metalPrimitiveType = MTLPrimitiveTypePoint; break;
            case 1: metalPrimitiveType = MTLPrimitiveTypeLine; break;
            case 2: metalPrimitiveType = MTLPrimitiveTypeLineStrip; break;
            case 3: metalPrimitiveType = MTLPrimitiveTypeTriangle; break;
            case 4: metalPrimitiveType = MTLPrimitiveTypeTriangleStrip; break;
        }

        MTLIndexType indexType = is32bit ? MTLIndexTypeUInt32 : MTLIndexTypeUInt16;
        metal_profile_draw(1);
        metal_mark_buffer_used(metalIndexBuffer);
        [renderEncoder drawIndexedPrimitives:metalPrimitiveType
                                  indexCount:indexCount
                                   indexType:indexType
                                 indexBuffer:metalIndexBuffer
                           indexBufferOffset:indexOffset
                               instanceCount:instanceCount];
        metal_debug_log("draw_indexed_primitives_instanced() - SUCCESS (primitiveType=%d, indexCount=%d, indexOffset=%d, instanceCount=%d, is32bit=%d)", primitiveType, indexCount, indexOffset, instanceCount, is32bit);
    }
}

void metal_end_encoding_impl(metal_handle *encoder) {
    if (encoder == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge_transfer id<MTLRenderCommandEncoder>)encoder;
        
        // NOTE: Do NOT clear lastMRTCount here!
        // MRT textures need to remain available for subsequent passes to read from.
        // They are only cleared when:
        // 1. A new MRT pass starts (overwriting the old textures in begin_mrt_render_pass)
        // 2. At end of frame (in present() or begin_render_pass with clear)
        
        double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
        [renderEncoder endEncoding];
        if (ctx->profileDetailed) ctx->profile.encoderEnd += CACurrentMediaTime() - start;
        metal_profile_end_pass();
        metal_debug_log("end_encoding() - SUCCESS");
    }
}
