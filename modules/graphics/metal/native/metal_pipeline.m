#include "metal.h"

// ============================================================================
// Pipeline management: shader compilation, render/compute pipeline creation
// ============================================================================

metal_handle* metal_compile_shader_impl(vstring *source, int shaderType) {
    if (ctx == NULL || ctx->device == NULL || source == NULL) return NULL;

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

        NSString *shaderSource = [NSString stringWithUTF8String:(const char*)hl_to_utf8(source->bytes)];
        if (shaderSource == NULL) return NULL;

        // Log full shader source for debugging
        metal_debug_log("=== FULL SHADER SOURCE (type=%d) ===\n%s\n=== END SHADER SOURCE ===", shaderType, [shaderSource UTF8String]);

        NSError *error = nil;
        CFTimeInterval compileStart = ctx->profileEnabled ? CACurrentMediaTime() : 0;
        id<MTLLibrary> library = [device newLibraryWithSource:shaderSource options:nil error:&error];
        METAL_PROFILE(compile, CACurrentMediaTime() - compileStart);
        if (library) METAL_PROFILE(libraries, 1);
        if (library == NULL || error != nil) {
            metal_log_error("Shader compilation failed: %s", [error.localizedDescription UTF8String]);
            return NULL;
        }

        // Get the main function - Metal shaders should have a main function
        // shaderType: 0=vertex, 1=fragment, 2=compute
        NSString *functionName;
        if (shaderType == 0) {
            functionName = @"vertex_main";
        } else if (shaderType == 1) {
            functionName = @"fragment_main";
        } else if (shaderType == 2) {
            functionName = @"compute_main";
        } else {
            metal_debug_log("Unknown shader type: %d", shaderType);
            return NULL;
        }
        
        id<MTLFunction> function = [library newFunctionWithName:functionName];
        if (function == NULL) {
            metal_debug_log("Failed to find function %s in shader", [functionName UTF8String]);
            return NULL;
        }

        return (metal_handle*)(__bridge_retained void*)function;
    }
}

metal_handle* metal_create_compute_pipeline_from_function_impl(metal_handle *func) {
    if (ctx == NULL || ctx->device == NULL || func == NULL) return NULL;

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
        id<MTLFunction> function = (__bridge id<MTLFunction>)func;

        NSError *error = nil;
        id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:function error:&error];
        if (!pipelineState) {
            metal_debug_log("Failed to create compute pipeline state: %s", [[error localizedDescription] UTF8String]);
            return NULL;
        }

        metal_debug_log("Created compute pipeline state successfully");
        return (metal_handle*)(__bridge_retained void*)pipelineState;
    }
}

// Map Heaps Blend enum to MTLBlendFactor
// MUST match order in h3d/mat/Data.hx Blend enum:
// One=0, Zero=1, SrcAlpha=2, SrcColor=3, DstAlpha=4, DstColor=5,
// OneMinusSrcAlpha=6, OneMinusSrcColor=7, OneMinusDstAlpha=8, OneMinusDstColor=9,
// ConstantColor=10, ConstantAlpha=11, OneMinusConstantColor=12, OneMinusConstantAlpha=13, SrcAlphaSaturate=14
static const MTLBlendFactor BLEND_FACTORS[] = {
    MTLBlendFactorOne,                      // One = 0
    MTLBlendFactorZero,                     // Zero = 1
    MTLBlendFactorSourceAlpha,              // SrcAlpha = 2
    MTLBlendFactorSourceColor,              // SrcColor = 3
    MTLBlendFactorDestinationAlpha,         // DstAlpha = 4
    MTLBlendFactorDestinationColor,         // DstColor = 5
    MTLBlendFactorOneMinusSourceAlpha,      // OneMinusSrcAlpha = 6
    MTLBlendFactorOneMinusSourceColor,      // OneMinusSrcColor = 7
    MTLBlendFactorOneMinusDestinationAlpha, // OneMinusDstAlpha = 8
    MTLBlendFactorOneMinusDestinationColor, // OneMinusDstColor = 9
    MTLBlendFactorBlendColor,
    MTLBlendFactorBlendAlpha,
    MTLBlendFactorOneMinusBlendColor,
    MTLBlendFactorOneMinusBlendAlpha,
    MTLBlendFactorSourceAlphaSaturated,
};

// Map Heaps Operation enum to MTLBlendOperation
// MUST match order in h3d/mat/Data.hx Operation enum:
// Add=0, Sub=1, ReverseSub=2, Min=3, Max=4
static const MTLBlendOperation BLEND_OPS[] = {
    MTLBlendOperationAdd,             // Add = 0
    MTLBlendOperationSubtract,        // Sub = 1
    MTLBlendOperationReverseSubtract, // ReverseSub = 2
    MTLBlendOperationMin,             // Min = 3
    MTLBlendOperationMax,             // Max = 4
};

metal_handle* metal_create_render_pipeline_impl(metal_handle *vertexShader, metal_handle *fragmentShader, vstring *vertexDesc, int blendSrc, int blendDst, int blendAlphaSrc, int blendAlphaDst, int blendOp, int blendAlphaOp, int colorMask) {
    if (ctx == NULL || ctx->device == NULL || vertexShader == NULL || fragmentShader == NULL) return NULL;

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
        id<MTLFunction> vertexFunction = (__bridge id<MTLFunction>)vertexShader;
        id<MTLFunction> fragmentFunction = (__bridge id<MTLFunction>)fragmentShader;

#ifdef METAL_DEBUG
        // Debug: log the vertex descriptor string
        if (vertexDesc != NULL && vertexDesc->bytes != NULL) {
            const char *descStr = (const char*)hl_to_utf8(vertexDesc->bytes);
            metal_debug_log("create_render_pipeline() - vertexDesc: '%s'", descStr);
        } else {
            metal_debug_log("create_render_pipeline() - vertexDesc is NULL");
        }
#endif

        MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
        descriptor.vertexFunction = vertexFunction;
        descriptor.fragmentFunction = fragmentFunction;

        descriptor.depthAttachmentPixelFormat = ctx->depthFormat;
        descriptor.stencilAttachmentPixelFormat = ctx->stencilFormat;
        for (int i = 0; i < 8; i++) {
            MTLPixelFormat format = ctx->colorFormats[i];
            if (format == MTLPixelFormatInvalid) continue;
            MTLRenderPipelineColorAttachmentDescriptor *color = descriptor.colorAttachments[i];
            color.pixelFormat = format;
            unsigned channels = ((uint32_t)colorMask >> (4 * i)) & 15;
            color.writeMask = (channels & 1 ? MTLColorWriteMaskRed : 0) |
                              (channels & 2 ? MTLColorWriteMaskGreen : 0) |
                              (channels & 4 ? MTLColorWriteMaskBlue : 0) |
                              (channels & 8 ? MTLColorWriteMaskAlpha : 0);
            color.blendingEnabled = !(blendSrc == 0 && blendDst == 1 &&
                                      blendAlphaSrc == 0 && blendAlphaDst == 1 &&
                                      blendOp == 0 && blendAlphaOp == 0);
            color.rgbBlendOperation = BLEND_OPS[blendOp];
            color.alphaBlendOperation = BLEND_OPS[blendAlphaOp];
            color.sourceRGBBlendFactor = BLEND_FACTORS[blendSrc];
            color.sourceAlphaBlendFactor = BLEND_FACTORS[blendAlphaSrc];
            color.destinationRGBBlendFactor = BLEND_FACTORS[blendDst];
            color.destinationAlphaBlendFactor = BLEND_FACTORS[blendAlphaDst];
        }

        MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
        NSString *layout = [NSString stringWithUTF8String:(const char *)hl_to_utf8(vertexDesc->bytes)];
        NSArray<NSString *> *attributes = [layout length] == 0 ? @[] : [layout componentsSeparatedByString:@","];
        static const MTLVertexFormat formats[][4] = {
            { MTLVertexFormatFloat, MTLVertexFormatFloat2, MTLVertexFormatFloat3, MTLVertexFormatFloat4 },
            { MTLVertexFormatHalf, MTLVertexFormatHalf2, MTLVertexFormatHalf3, MTLVertexFormatHalf4 },
            { MTLVertexFormatUCharNormalized, MTLVertexFormatUChar2Normalized,
              MTLVertexFormatUChar3Normalized, MTLVertexFormatUChar4Normalized },
            { MTLVertexFormatCharNormalized, MTLVertexFormatChar2Normalized,
              MTLVertexFormatChar3Normalized, MTLVertexFormatChar4Normalized },
        };

        for (NSUInteger index = 0; index < attributes.count; index++) {
            NSArray<NSString *> *fields = [attributes[index] componentsSeparatedByString:@":"];
            if (fields.count != 6) return NULL;
            int components = fields[0].intValue;
            int precision = fields[1].intValue;
            int slot = fields[2].intValue;
            int divisor = fields[3].intValue;
            int offset = fields[4].intValue;
            int stride = fields[5].intValue;
            if (slot < 0 || slot >= 16 || components < 1 || components > 6 ||
                precision < 0 || precision > 3 || offset < 0 || offset >= stride)
                return NULL;

            MTLVertexFormat format = components == 6 ? MTLVertexFormatUChar4 :
                components == 5 ? MTLVertexFormatInt : formats[precision][components - 1];
            vertexDescriptor.attributes[index].format = format;
            vertexDescriptor.attributes[index].offset = offset;
            vertexDescriptor.attributes[index].bufferIndex = slot;

            MTLVertexBufferLayoutDescriptor *stream = vertexDescriptor.layouts[slot];
            MTLVertexStepFunction step = divisor == 0 ? MTLVertexStepFunctionPerVertex : MTLVertexStepFunctionPerInstance;
            NSUInteger rate = divisor == 0 ? 1 : (NSUInteger)divisor;
            if (stream.stride != 0 && (stream.stepFunction != step || stream.stepRate != rate)) {
                metal_log_error("Mixed vertex step rates in buffer %d", slot);
                return NULL;
            }
            stream.stride = stride;
            stream.stepFunction = step;
            stream.stepRate = rate;
        }
        descriptor.vertexDescriptor = vertexDescriptor;

        NSError *error = nil;
        CFTimeInterval compileStart = ctx->profileEnabled ? CACurrentMediaTime() : 0;
        id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
        METAL_PROFILE(compile, CACurrentMediaTime() - compileStart);
        if (pipelineState) METAL_PROFILE(pipelines, 1);
        if (pipelineState == NULL || error != nil) {
            metal_debug_log("Pipeline creation failed: %s", [error.localizedDescription UTF8String]);
            return NULL;
        }

        metal_debug_log("create_render_pipeline() - SUCCESS");
        return (metal_handle*)(__bridge_retained void*)pipelineState;
    }
}

void metal_dispose_pipeline_impl(metal_handle *pipeline) {
    if (pipeline == NULL) return;

    @autoreleasepool {
        id<MTLRenderPipelineState> pipelineState = (__bridge_transfer id<MTLRenderPipelineState>)pipeline;
        (void)pipelineState; // ARC will handle release
    }
}
