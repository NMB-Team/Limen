#include "metal.h"

// ============================================================================
// Compute shader support
// ============================================================================

// Stores current compute state for dispatch
typedef struct {
    void *pipelineState;     // id<MTLComputePipelineState>
    void *outputTexture;     // id<MTLTexture> - texture to write to
    void *inputBuffer;       // id<MTLBuffer> - optional input buffer
} MetalComputeState;

static MetalComputeState currentComputeState = {NULL, NULL, NULL};

metal_handle* metal_create_compute_pipeline_impl(vbyte *source, vbyte *functionName) {
    if (!ctx || !ctx->device) {
        metal_log_error("create_compute_pipeline - context not initialized");
        return NULL;
    }

    if (!source || !functionName) {
        metal_log_error("create_compute_pipeline - null source or function name");
        return NULL;
    }

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;
        NSError *error = nil;

        // Convert source to NSString
        NSString *sourceStr = [NSString stringWithUTF8String:(const char*)source];
        NSString *funcNameStr = [NSString stringWithUTF8String:(const char*)functionName];

        // Compile shader source
        id<MTLLibrary> library = [device newLibraryWithSource:sourceStr options:nil error:&error];
        if (!library) {
            metal_log_error("create_compute_pipeline - failed to compile shader: %s", 
                          [[error localizedDescription] UTF8String]);
            return NULL;
        }

        // Get compute function
        id<MTLFunction> computeFunction = [library newFunctionWithName:funcNameStr];
        if (!computeFunction) {
            metal_log_error("create_compute_pipeline - function '%s' not found in shader", 
                          [funcNameStr UTF8String]);
            return NULL;
        }

        // Create compute pipeline state
        id<MTLComputePipelineState> pipelineState = [device newComputePipelineStateWithFunction:computeFunction error:&error];
        if (!pipelineState) {
            metal_log_error("create_compute_pipeline - failed to create pipeline: %s",
                          [[error localizedDescription] UTF8String]);
            return NULL;
        }

        metal_debug_log("create_compute_pipeline - created pipeline for function '%s'", 
                       [funcNameStr UTF8String]);
        
        return (metal_handle*)(__bridge_retained void*)pipelineState;
    }
}

void metal_set_compute_pipeline_impl(metal_handle *pipeline) {
    currentComputeState.pipelineState = pipeline;
    metal_debug_log("set_compute_pipeline - pipeline set");
}

void metal_set_compute_texture_impl(metal_handle *texture, int index) {
    if (index == 0) {
        currentComputeState.outputTexture = texture;
        metal_debug_log("set_compute_texture - output texture set at index %d", index);
    }
}

void metal_set_compute_buffer_impl(metal_handle *buffer, int index) {
    if (index == 0) {
        currentComputeState.inputBuffer = buffer;
        metal_debug_log("set_compute_buffer - input buffer set at index %d", index);
    }
}

bool metal_dispatch_compute_impl(metal_handle *cmdBuffer, int x, int y, int z) {
    if (!ctx || !ctx->device) {
        metal_log_error("dispatch_compute - context not initialized");
        return false;
    }

    if (cmdBuffer == NULL) {
        metal_log_error("dispatch_compute - null command buffer");
        return false;
    }

    void *pipeline = currentComputeState.pipelineState;
    void *texture  = currentComputeState.outputTexture;
    void *buffer   = currentComputeState.inputBuffer;

    if (!pipeline) {
        metal_log_error("dispatch_compute - no compute pipeline set");
        return false;
    }

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

        if (!computeEncoder) {
            metal_log_error("dispatch_compute - failed to create compute encoder");
            return false;
        }

        // Set the compute pipeline state
        [computeEncoder setComputePipelineState:(__bridge id<MTLComputePipelineState>)pipeline];

        // Set output texture if available
        if (texture) {
            metal_mark_texture_used((__bridge id<MTLTexture>)texture, commandBuffer, false);
            [computeEncoder setTexture:(__bridge id<MTLTexture>)texture atIndex:0];
        }

        // Set input buffer if available
        if (buffer) {
            id<MTLBuffer> resource = (__bridge id<MTLBuffer>)buffer;
            LimenMetalBufferUse *use = metal_buffer_use(resource);
            use.stream = NO;
            use.command = commandBuffer;
            [computeEncoder setBuffer:resource offset:0 atIndex:0];
        }

        // Dispatch thread groups
        // x, y, z are thread GROUP counts, not total thread counts
        // Each group has 8x8x1 threads (from setLayout in shader)
        MTLSize threadgroupsPerGrid = MTLSizeMake(x, y, z);
        MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);

        // Dispatch the compute shader using thread groups
        [computeEncoder dispatchThreadgroups:threadgroupsPerGrid threadsPerThreadgroup:threadsPerThreadgroup];

        // End encoding
        [computeEncoder endEncoding];

        metal_debug_log("dispatch_compute - dispatched %dx%dx%d threads", x, y, z);
        return true;
    }
}

void metal_memory_barrier_impl(metal_handle *cmdBuffer) {
    if (cmdBuffer == NULL) {
        metal_log_warning("memory_barrier - null command buffer");
        return;
    }

    @autoreleasepool {
        id<MTLCommandBuffer> commandBuffer = (__bridge id<MTLCommandBuffer>)cmdBuffer;
        
        // In Metal, we use a blit encoder to ensure ordering
        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        [blitEncoder endEncoding];
        
        metal_debug_log("memory_barrier - barrier inserted");
    }
}
