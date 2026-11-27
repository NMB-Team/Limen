#include "metal.h"

// ============================================================================
// Resource management: buffers, textures, samplers
// ============================================================================

#include <objc/runtime.h>

@interface LimenMetalBufferUse : NSObject
@property (nonatomic, weak) id<MTLCommandBuffer> command;
@property (nonatomic) NSUInteger initializedEnd;
@property (nonatomic) BOOL stream;
@end

@implementation LimenMetalBufferUse
@end

static const char bufferUseKey;

@interface LimenMetalTextureUse : NSObject {
@public
    NSUInteger key[5]; // Requested size, format, usage and resource options.
    BOOL fresh;
}
@property (nonatomic, weak) id<MTLCommandBuffer> command;
@end
@implementation LimenMetalTextureUse
@end
static const char textureUseKey;

static NSUInteger metal_pixel_size(MTLPixelFormat format);

static void metal_initialize_recycled_texture(id<MTLTexture> texture, LimenMetalTextureUse *use) {
    if (use == nil || !use->fresh) return;
    // Normally Heaps clears a new target in its first render pass. Preserve
    // fresh-allocation contents for the rarer read/partial-upload-first path.
    // Only CPU-accessible, completion-safe allocations enter this pool.
    NSUInteger stride = texture.width * metal_pixel_size(texture.pixelFormat);
    NSUInteger bytes = stride * texture.height;
    void *zero = calloc(1, bytes);
    if (zero == NULL) hl_error("Failed to initialize recycled Metal target");
    double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
    [texture replaceRegion:MTLRegionMake2D(0, 0, texture.width, texture.height)
               mipmapLevel:0 withBytes:zero bytesPerRow:stride];
    if (ctx->profileDetailed) ctx->profile.upload += CACurrentMediaTime() - start;
    METAL_PROFILE(uploadBytes, bytes);
    free(zero);
    use->fresh = NO;
}

static void metal_mark_texture_used(id<MTLTexture> texture, id<MTLCommandBuffer> command, bool overwrites) {
    if (!ctx->texturePoolEnabled || texture == nil || command == nil) return;
    LimenMetalTextureUse *use = objc_getAssociatedObject(texture, &textureUseKey);
    if (use != nil) {
        if (overwrites) use->fresh = NO;
        else metal_initialize_recycled_texture(texture, use);
        use.command = command;
    }
}

static id<MTLTexture> metal_remove_pooled_texture(NSUInteger index) {
    id<MTLTexture> texture = (__bridge_transfer id<MTLTexture>)ctx->texturePool[index].texture;
    ctx->texturePoolBytes -= texture.allocatedSize;
    // Keep release order so eviction removes the oldest cached allocation.
    for (NSUInteger i = index + 1; i < ctx->texturePoolCount; i++)
        ctx->texturePool[i - 1] = ctx->texturePool[i];
    ctx->texturePool[--ctx->texturePoolCount] = (metal_pooled_texture){0};
    return texture;
}

static id<MTLTexture> metal_acquire_texture(id<MTLDevice> device, MTLTextureDescriptor *descriptor) {
    NSUInteger key[] = {descriptor.width, descriptor.height, descriptor.pixelFormat,
                        descriptor.usage, descriptor.resourceOptions};
    bool reusable = ctx->texturePoolEnabled && descriptor.textureType == MTLTextureType2D &&
        descriptor.mipmapLevelCount == 1 && descriptor.sampleCount == 1 &&
        descriptor.storageMode != MTLStorageModePrivate && descriptor.storageMode != MTLStorageModeMemoryless &&
        (descriptor.usage & MTLTextureUsageRenderTarget) != 0 &&
        (descriptor.usage & MTLTextureUsageShaderWrite) == 0 &&
        descriptor.pixelFormat != MTLPixelFormatDepth16Unorm &&
        descriptor.pixelFormat != MTLPixelFormatDepth32Float &&
        descriptor.pixelFormat != MTLPixelFormatDepth32Float_Stencil8;
    if (reusable) {
        double lookupStart = ctx->profileDetailed ? CACurrentMediaTime() : 0;
        for (NSUInteger i = 0; i < ctx->texturePoolCount; i++) {
            // Reject other shapes using plain data, before entering the ObjC
            // associated-object and weak-reference machinery.
            if (memcmp(ctx->texturePool[i].key, key, sizeof(key)) != 0) continue;
            id<MTLTexture> texture = (__bridge id<MTLTexture>)ctx->texturePool[i].texture;
            LimenMetalTextureUse *use = objc_getAssociatedObject(texture, &textureUseKey);
            // Compare requested options, since Metal can resolve default resource
            // options differently on different GPU families.
            if (use == nil) continue;
            id<MTLCommandBuffer> command = use.command;
            if (command != nil && command.status < MTLCommandBufferStatusCompleted) continue;
            id<MTLTexture> recycled = metal_remove_pooled_texture(i);
            use.command = nil;
            use->fresh = YES;
            METAL_PROFILE(textureReuses, 1);
            if (ctx->profileDetailed) ctx->profile.texturePoolLookup += CACurrentMediaTime() - lookupStart;
            return recycled;
        }
        if (ctx->profileDetailed) ctx->profile.texturePoolLookup += CACurrentMediaTime() - lookupStart;
    }
    double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
    id<MTLTexture> texture = [device newTextureWithDescriptor:descriptor];
    if (ctx->profileDetailed) ctx->profile.textureAlloc += CACurrentMediaTime() - start;
    if (texture != nil) {
        METAL_PROFILE(textures, 1);
        if (reusable && texture.allocatedSize > 0 && texture.allocatedSize <= METAL_TEXTURE_POOL_BYTES) {
            LimenMetalTextureUse *use = [LimenMetalTextureUse new];
            memcpy(use->key, key, sizeof(key));
            objc_setAssociatedObject(texture, &textureUseKey, use, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return texture;
}

static LimenMetalBufferUse *metal_buffer_use(id<MTLBuffer> buffer) {
    LimenMetalBufferUse *use = objc_getAssociatedObject(buffer, &bufferUseKey);
    if (use == nil) {
        use = [LimenMetalBufferUse new];
        objc_setAssociatedObject(buffer, &bufferUseKey, use, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return use;
}

static bool metal_buffer_in_use(LimenMetalBufferUse *use) {
    id<MTLCommandBuffer> command = use.command;
    return command != nil && command.status < MTLCommandBufferStatusCompleted;
}

static id<MTLBuffer> metal_acquire_buffer(id<MTLDevice> device, NSUInteger length,
                                         MTLResourceOptions options, bool stream) {
    if (stream) {
        for (NSUInteger i = 0; i < ctx->bufferPoolCount; i++) {
            id<MTLBuffer> buffer = (__bridge id<MTLBuffer>)ctx->bufferPool[i];
            // Metal may report the resolved hazard mode even when Default
            // was requested. The pool only owns default-tracked allocations.
            const MTLResourceOptions storageAndCache = MTLResourceStorageModeMask | MTLResourceCPUCacheModeMask;
            if (buffer.length != length || (buffer.resourceOptions & storageAndCache) != (options & storageAndCache))
                continue;
            LimenMetalBufferUse *use = metal_buffer_use(buffer);
            if (metal_buffer_in_use(use)) continue;

            id<MTLBuffer> recycled = (__bridge_transfer id<MTLBuffer>)ctx->bufferPool[i];
            ctx->bufferPool[i] = ctx->bufferPool[--ctx->bufferPoolCount];
            ctx->bufferPool[ctx->bufferPoolCount] = NULL;
            ctx->bufferPoolBytes -= length;
            use.initializedEnd = 0;
            use.command = nil;
            METAL_PROFILE(bufferReuses, 1);
            return recycled;
        }
    }

    double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
    id<MTLBuffer> buffer = [device newBufferWithLength:length options:options];
    if (ctx->profileDetailed) ctx->profile.bufferAlloc += CACurrentMediaTime() - start;
    if (buffer != nil) {
        METAL_PROFILE(buffers, 1);
        if (stream) metal_buffer_use(buffer).stream = YES;
    }
    return buffer;
}

static void metal_mark_buffer_used(id<MTLBuffer> buffer) {
    if (ctx->currentCommandBuffer == NULL) return;
    LimenMetalBufferUse *use = metal_buffer_use(buffer);
    id<MTLCommandBuffer> command = (__bridge id<MTLCommandBuffer>)ctx->currentCommandBuffer;
    if (use.command != command)
        use.command = command;
}

metal_handle* metal_create_buffer_impl(int size, int usage) {
    if (ctx == NULL || ctx->device == NULL || size <= 0) {
        metal_debug_log("ERROR: create_buffer() - invalid parameters (size=%d)", size);
        return NULL;
    }

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

        MTLResourceOptions options = MTLResourceStorageModeShared;
        if (usage & 1) options = MTLResourceStorageModeShared; // Dynamic
        if (usage & 2) options |= MTLResourceCPUCacheModeWriteCombined; // Uniform

        id<MTLBuffer> buffer = metal_acquire_buffer(device, size, options, (usage & METAL_STREAM_BUFFER) != 0);
        if (buffer == NULL) {
            metal_debug_log("ERROR: create_buffer() - failed to create buffer");
            return NULL;
        }

        metal_debug_log("create_buffer() - SUCCESS (size=%d, usage=%d)", size, usage);
        return (metal_handle*)(__bridge_retained void*)buffer;
    }
}

metal_handle *metal_update_buffer_impl(metal_handle *handle, vbyte *data, int size, int offset) {
    if (handle == NULL || data == NULL || size < 0 || offset < 0)
        return NULL;

    @autoreleasepool {
        id<MTLBuffer> buffer = (__bridge id<MTLBuffer>)handle;
        NSUInteger end = (NSUInteger)offset + (NSUInteger)size;
        if (end > buffer.length) return NULL;
        if (size == 0) return handle;
        METAL_PROFILE(uploadBytes, size);

        LimenMetalBufferUse *use = metal_buffer_use(buffer);
        if ((NSUInteger)offset < use.initializedEnd && metal_buffer_in_use(use)) {
            // Appends into a streaming buffer are safe. An overlapping upload
            // needs independent storage until the earlier draws finish reading.
            id<MTLBuffer> replacement = metal_acquire_buffer(buffer.device, buffer.length,
                                                              buffer.resourceOptions, use.stream);
            if (replacement == nil) return NULL;
            METAL_PROFILE(renames, 1);
            if (offset != 0) {
                METAL_PROFILE(copyBytes, offset);
                metal_profile_copy(replacement.contents, buffer.contents, offset);
            }
            if (end < use.initializedEnd) {
                NSUInteger tail = use.initializedEnd - end;
                METAL_PROFILE(copyBytes, tail);
                metal_profile_copy((char *)replacement.contents + end, (char *)buffer.contents + end, tail);
            }
            LimenMetalBufferUse *replacementUse = metal_buffer_use(replacement);
            replacementUse.initializedEnd = MAX(use.initializedEnd, end);
            metal_profile_copy((char *)replacement.contents + offset, data, size);
            return (__bridge_retained void *)replacement;
        }

        metal_profile_copy((char *)buffer.contents + offset, data, size);
        use.initializedEnd = MAX(use.initializedEnd, end);
        return handle;
    }
}

bool metal_upload_buffer_data_impl(metal_handle *buffer, vbyte *data, int size, int offset) {
    if (buffer == NULL || data == NULL || size <= 0) {
        return false;
    }

    @autoreleasepool {
        id<MTLBuffer> metalBuffer = (__bridge id<MTLBuffer>)buffer;
        
        if (offset < 0 || (NSUInteger)offset + (NSUInteger)size > metalBuffer.length)
            return false;

        METAL_PROFILE(uploadBytes, size);
        metal_profile_copy((char*)metalBuffer.contents + offset, data, size);

        // Log ALL buffer uploads to debug lighting issue
        metal_debug_log("upload_buffer_data() - size=%d, offset=%d", size, offset);

#ifdef METAL_DEBUG
        // Verify data after upload for parameter buffers (128 bytes = 8 vec4s)
        if (size == 128 && offset == 0) {
            float *floats = (float*)metalBuffer.contents;
            metal_debug_log("=== NATIVE SIDE: Parameter buffer received (128 bytes) ===");
            metal_debug_log("vec4[0]: [%.6f, %.6f, %.6f, %.6f]", floats[0], floats[1], floats[2], floats[3]);
            metal_debug_log("vec4[1]: [%.6f, %.6f, %.6f, %.6f]", floats[4], floats[5], floats[6], floats[7]);
            metal_debug_log("vec4[2]: [%.6f, %.6f, %.6f, %.6f]", floats[8], floats[9], floats[10], floats[11]);
            metal_debug_log("vec4[3]: [%.6f, %.6f, %.6f, %.6f]", floats[12], floats[13], floats[14], floats[15]);
            metal_debug_log("vec4[4]: [%.6f, %.6f, %.6f, %.6f]", floats[16], floats[17], floats[18], floats[19]);
            metal_debug_log("vec4[5]: [%.6f, %.6f, %.6f, %.6f]", floats[20], floats[21], floats[22], floats[23]);
            metal_debug_log("vec4[6] (viewportA): [%.6f, %.6f, %.6f, %.6f]", floats[24], floats[25], floats[26], floats[27]);
            metal_debug_log("vec4[7] (viewportB): [%.6f, %.6f, %.6f, %.6f]", floats[28], floats[29], floats[30], floats[31]);
            metal_debug_log("=== END NATIVE VERIFICATION ===");
        }
        
        // Verify data after upload for fragment parameter buffers (112 bytes = 7 vec4s)
        if (size == 112 && offset == 0) {
            float *floats = (float*)metalBuffer.contents;
            metal_debug_log("=== NATIVE SIDE: Fragment parameter buffer received (112 bytes) ===");
            metal_debug_log("vec4[0] (albedo): [%.6f, %.6f, %.6f, %.6f]", floats[0], floats[1], floats[2], floats[3]);
            metal_debug_log("vec4[1] (metalness): [%.6f, %.6f, %.6f, %.6f]", floats[4], floats[5], floats[6], floats[7]);
            metal_debug_log("vec4[2] (roughness): [%.6f, %.6f, %.6f, %.6f]", floats[8], floats[9], floats[10], floats[11]);
            metal_debug_log("vec4[3] (occlusion): [%.6f, %.6f, %.6f, %.6f]", floats[12], floats[13], floats[14], floats[15]);
            metal_debug_log("vec4[4] (emissive): [%.6f, %.6f, %.6f, %.6f]", floats[16], floats[17], floats[18], floats[19]);
            metal_debug_log("vec4[5] (custom1): [%.6f, %.6f, %.6f, %.6f]", floats[20], floats[21], floats[22], floats[23]);
            metal_debug_log("vec4[6] (custom2): [%.6f, %.6f, %.6f, %.6f]", floats[24], floats[25], floats[26], floats[27]);
            metal_debug_log("=== END FRAGMENT NATIVE VERIFICATION ===");
        }
        
        // Verify data after upload for lighting parameter buffers (80 bytes = 5 vec4s)
        if (size == 80 && offset == 0) {
            float *floats = (float*)metalBuffer.contents;
            metal_debug_log("=== NATIVE SIDE: Lighting parameter buffer received (80 bytes) ===");
            metal_debug_log("vec4[0]: [%.6f, %.6f, %.6f, %.6f]", floats[0], floats[1], floats[2], floats[3]);
            metal_debug_log("vec4[1]: [%.6f, %.6f, %.6f, %.6f]", floats[4], floats[5], floats[6], floats[7]);
            metal_debug_log("vec4[2]: [%.6f, %.6f, %.6f, %.6f]", floats[8], floats[9], floats[10], floats[11]);
            metal_debug_log("vec4[3]: [%.6f, %.6f, %.6f, %.6f]", floats[12], floats[13], floats[14], floats[15]);
            metal_debug_log("vec4[4]: [%.6f, %.6f, %.6f, %.6f]", floats[16], floats[17], floats[18], floats[19]);
            metal_debug_log("=== END LIGHTING NATIVE VERIFICATION ===");
        }
#endif // METAL_DEBUG
        
        return true;
    }
}

metal_handle* metal_create_texture_impl(int width, int height, int format, int usage, bool mipmapped, bool isCube, int arrayLength) {
    if (ctx == NULL || ctx->device == NULL || width <= 0 || height <= 0) return NULL;

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

MTLTextureDescriptor *descriptor;
if (isCube) {
    descriptor = [MTLTextureDescriptor textureCubeDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                        size:width
                                                                   mipmapped:mipmapped];
} else if (arrayLength > 1) {
    // Texture array
    descriptor = [[MTLTextureDescriptor alloc] init];
    descriptor.textureType = MTLTextureType2DArray;
    descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
    descriptor.width = width;
    descriptor.height = height;
    descriptor.arrayLength = arrayLength;
    descriptor.mipmapLevelCount = mipmapped ? 1 + floor(log2(fmax(width, height))) : 1;
} else {
    descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                      width:width
                                                                     height:height
                                                                  mipmapped:mipmapped];
}

        // Map format parameter to Metal pixel format
        switch (format) {
            case 0: descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm; break;
            case 1: descriptor.pixelFormat = MTLPixelFormatBGRA8Unorm; break;
            case 2: descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm; break; // RGB8 -> RGBA8
            case 3: descriptor.pixelFormat = MTLPixelFormatRG8Unorm; break;
            case 4: descriptor.pixelFormat = MTLPixelFormatR8Unorm; break;
            case 5: descriptor.pixelFormat = MTLPixelFormatRGBA16Float; break;
            case 6: descriptor.pixelFormat = MTLPixelFormatRGBA32Float; break;
            case 7: descriptor.pixelFormat = MTLPixelFormatDepth16Unorm; break;  // Depth16 (legacy)
            case 8: descriptor.pixelFormat = MTLPixelFormatDepth32Float; break;  // Depth24 -> Depth32Float (Apple Silicon doesn't support Depth24)
            case 9: descriptor.pixelFormat = MTLPixelFormatDepth32Float_Stencil8; break;  // Depth24Stencil8 -> Depth32Float_Stencil8
            case 10: descriptor.pixelFormat = MTLPixelFormatDepth32Float; break;  // Depth32 (NEW: depth2d<float>)
            case 11: descriptor.pixelFormat = MTLPixelFormatR16Float; break;
            case 12: descriptor.pixelFormat = MTLPixelFormatR32Float; break;
            case 13: descriptor.pixelFormat = MTLPixelFormatRG16Float; break;
            case 14: descriptor.pixelFormat = MTLPixelFormatRG32Float; break;
            case 15: descriptor.pixelFormat = MTLPixelFormatRGBA16Float; break; // RGB16F -> RGBA16F
            case 16: descriptor.pixelFormat = MTLPixelFormatRGBA32Float; break; // RGB32F -> RGBA32F
            case 17: descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB; break; // SRGB -> RGBA8Unorm_sRGB
            case 18: descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB; break; // SRGB_ALPHA
            case 19: descriptor.pixelFormat = MTLPixelFormatRGB10A2Unorm; break;
            case 20: descriptor.pixelFormat = MTLPixelFormatRG11B10Float; break;
            case 21: descriptor.pixelFormat = MTLPixelFormatR16Unorm; break;
            case 22: descriptor.pixelFormat = MTLPixelFormatRG16Unorm; break;
            case 23: descriptor.pixelFormat = MTLPixelFormatRGBA16Unorm; break; // RGB16U -> RGBA16U
            case 24: descriptor.pixelFormat = MTLPixelFormatRGBA16Unorm; break;
            default: descriptor.pixelFormat = MTLPixelFormatRGBA8Unorm; break;
        }

        // Set texture usage
        MTLTextureUsage textureUsage = MTLTextureUsageShaderRead;
        if (usage & 2) textureUsage |= MTLTextureUsageRenderTarget;
        if (usage & 4) textureUsage |= MTLTextureUsageShaderWrite;
        descriptor.usage = textureUsage;

        id<MTLTexture> texture = metal_acquire_texture(device, descriptor);
        if (texture == NULL) {
            metal_debug_log("ERROR: create_texture() - failed to create texture");
            return NULL;
        }

        metal_debug_log("create_texture() - SUCCESS (width=%d, height=%d, format=%d, usage=%d)", width, height, format, usage);
        return (metal_handle*)(__bridge_retained void*)texture;
    }
}

static NSUInteger metal_pixel_size(MTLPixelFormat format) {
    switch (format) {
        case MTLPixelFormatR8Unorm:
            return 1;
        case MTLPixelFormatRG8Unorm:
        case MTLPixelFormatR16Float:
        case MTLPixelFormatR16Unorm:
            return 2;
        case MTLPixelFormatRGBA8Unorm:
        case MTLPixelFormatBGRA8Unorm:
        case MTLPixelFormatRGBA8Unorm_sRGB:
        case MTLPixelFormatRGB10A2Unorm:
        case MTLPixelFormatRG11B10Float:
        case MTLPixelFormatRG16Float:
        case MTLPixelFormatRG16Unorm:
        case MTLPixelFormatR32Float:
            return 4;
        case MTLPixelFormatRGBA16Float:
        case MTLPixelFormatRGBA16Unorm:
        case MTLPixelFormatRG32Float:
            return 8;
        case MTLPixelFormatRGBA32Float:
            return 16;
        default:
            return 0;
    }
}

static bool metal_texture_region_valid(id<MTLTexture> texture, int x, int y,
                                       int width, int height, int level, int slice) {
    if (x < 0 || y < 0 || width <= 0 || height <= 0 || level < 0 ||
        (NSUInteger)level >= texture.mipmapLevelCount || slice < 0)
        return false;
    NSUInteger slices = texture.arrayLength;
    if (texture.textureType == MTLTextureTypeCube || texture.textureType == MTLTextureTypeCubeArray)
        slices *= 6;
    return (NSUInteger)slice < slices &&
           (NSUInteger)x + (NSUInteger)width <= MAX(1, texture.width >> level) &&
           (NSUInteger)y + (NSUInteger)height <= MAX(1, texture.height >> level);
}

bool metal_upload_texture_data_impl(metal_handle *texture, vbyte *data, int width, int height, int level, int slice) {
    if (texture == NULL || data == NULL || width <= 0 || height <= 0) return false;

    @autoreleasepool {
        id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texture;
        
        if (!metal_texture_region_valid(metalTexture, 0, 0, width, height, level, slice))
            return false;
        NSUInteger bytesPerRow = width * metal_pixel_size(metalTexture.pixelFormat);
        if (bytesPerRow == 0) return false;

        LimenMetalTextureUse *use = objc_getAssociatedObject(metalTexture, &textureUseKey);
        if (use != nil && width == metalTexture.width && height == metalTexture.height) use->fresh = NO;
        else metal_initialize_recycled_texture(metalTexture, use);

        MTLRegion region = MTLRegionMake2D(0, 0, width, height);
        METAL_PROFILE(uploadBytes, bytesPerRow * height);
        double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
        [metalTexture replaceRegion:region
                        mipmapLevel:level
                              slice:slice
                          withBytes:data
                        bytesPerRow:bytesPerRow
                      bytesPerImage:bytesPerRow * height];
        if (ctx->profileDetailed) ctx->profile.upload += CACurrentMediaTime() - start;

        return true;
    }
}

bool metal_capture_texture_pixels_impl(metal_handle *texture, vbyte *data, int x, int y,
                                       int width, int height, int level, int slice) {
    if (texture == NULL || data == NULL) return false;

    @autoreleasepool {
        id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texture;
        if (!metal_texture_region_valid(metalTexture, x, y, width, height, level, slice))
            return false;
        NSUInteger bytesPerRow = width * metal_pixel_size(metalTexture.pixelFormat);
        if (bytesPerRow == 0) return false;
        // Haxe commits any active encoder before requesting a synchronous readback.
        // Mipmap generation also uses this queue and completes before returning.
        id<MTLCommandBuffer> last = metal_last_submitted_command;
        if (last != nil) {
            if (last.status < MTLCommandBufferStatusCompleted)
                [last waitUntilCompleted];
            if (last.status != MTLCommandBufferStatusCompleted) return false;
        }
        metal_initialize_recycled_texture(metalTexture, objc_getAssociatedObject(metalTexture, &textureUseKey));
        [metalTexture getBytes:data bytesPerRow:bytesPerRow bytesPerImage:bytesPerRow * height
                    fromRegion:MTLRegionMake2D(x, y, width, height) mipmapLevel:level slice:slice];
        return true;
    }
}

void metal_generate_mipmaps_impl(metal_handle *texture) {
    if (texture == NULL || ctx == NULL || ctx->commandQueue == NULL) return;

    @autoreleasepool {
        id<MTLTexture> metalTexture = (__bridge id<MTLTexture>)texture;
        id<MTLCommandQueue> commandQueue = (__bridge id<MTLCommandQueue>)ctx->commandQueue;

        // Create a blit command encoder to generate mipmaps
        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
        if (commandBuffer == NULL) {
            metal_debug_log("ERROR: generate_mipmaps() - failed to create command buffer");
            return;
        }

        id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
        if (blitEncoder == NULL) {
            metal_debug_log("ERROR: generate_mipmaps() - failed to create blit encoder");
            return;
        }

        [blitEncoder generateMipmapsForTexture:metalTexture];
        [blitEncoder endEncoding];

        [commandBuffer commit];
        [commandBuffer waitUntilCompleted];
        if (ctx->profileEnabled)
            fprintf(stderr, "metal-aux-gpu,%u,mipmap,%.9f,%.9f\n",
                    ctx->profile.id, commandBuffer.GPUStartTime, commandBuffer.GPUEndTime);

        metal_debug_log("generate_mipmaps() - SUCCESS");
    }
}

void metal_dispose_buffer_impl(metal_handle *buffer) {
    if (buffer == NULL) return;

    @autoreleasepool {
        id<MTLBuffer> metalBuffer = (__bridge_transfer id<MTLBuffer>)buffer;
        LimenMetalBufferUse *use = objc_getAssociatedObject(metalBuffer, &bufferUseKey);
        if (ctx != NULL && use.stream && ctx->bufferPoolCount < METAL_BUFFER_POOL_COUNT &&
            metalBuffer.length <= METAL_BUFFER_POOL_BYTES - ctx->bufferPoolBytes) {
            ctx->bufferPool[ctx->bufferPoolCount++] = (__bridge_retained void *)metalBuffer;
            ctx->bufferPoolBytes += metalBuffer.length;
        }
    }
}

void metal_dispose_texture_impl(metal_handle *texture) {
    if (texture == NULL) return;

    @autoreleasepool {
        id<MTLTexture> metalTexture = (__bridge_transfer id<MTLTexture>)texture;
        LimenMetalTextureUse *use = objc_getAssociatedObject(metalTexture, &textureUseKey);
        if (ctx != NULL && ctx->texturePoolEnabled && use != nil) {
            NSUInteger size = metalTexture.allocatedSize;
            while (ctx->texturePoolCount != 0 &&
                   (ctx->texturePoolCount == METAL_TEXTURE_POOL_COUNT || size > METAL_TEXTURE_POOL_BYTES - ctx->texturePoolBytes))
                (void)metal_remove_pooled_texture(0);
            metal_pooled_texture *entry = &ctx->texturePool[ctx->texturePoolCount++];
            entry->texture = (__bridge_retained void *)metalTexture;
            memcpy(entry->key, use->key, sizeof(entry->key));
            ctx->texturePoolBytes += size;
        }
    }
}

metal_handle* metal_create_sampler_state_impl(int minFilter, int magFilter, int mipFilter, int wrapS, int wrapT) {
    if (ctx == NULL || ctx->device == NULL) return NULL;

    @autoreleasepool {
        id<MTLDevice> device = (__bridge id<MTLDevice>)ctx->device;

        MTLSamplerDescriptor *samplerDesc = [[MTLSamplerDescriptor alloc] init];

        // Min/Mag filter
        samplerDesc.minFilter = (minFilter == 0) ? MTLSamplerMinMagFilterNearest : MTLSamplerMinMagFilterLinear;
        samplerDesc.magFilter = (magFilter == 0) ? MTLSamplerMinMagFilterNearest : MTLSamplerMinMagFilterLinear;

        // Mip filter
        if (mipFilter == 0) {
            samplerDesc.mipFilter = MTLSamplerMipFilterNotMipmapped;
        } else if (mipFilter == 1) {
            samplerDesc.mipFilter = MTLSamplerMipFilterNearest;
        } else {
            samplerDesc.mipFilter = MTLSamplerMipFilterLinear;
        }

        // Wrap modes
        static const MTLSamplerAddressMode addressModes[] = {
            MTLSamplerAddressModeClampToEdge, MTLSamplerAddressModeRepeat, MTLSamplerAddressModeMirrorRepeat,
        };
        if ((unsigned)wrapS >= 3 || (unsigned)wrapT >= 3) return NULL;
        samplerDesc.sAddressMode = addressModes[wrapS];
        samplerDesc.tAddressMode = addressModes[wrapT];

        id<MTLSamplerState> samplerState = [device newSamplerStateWithDescriptor:samplerDesc];
        if (samplerState == NULL) {
            metal_debug_log("ERROR: create_sampler_state() - failed to create sampler");
            return NULL;
        }

        return (metal_handle*)(__bridge_retained void*)samplerState;
    }
}

void metal_dispose_sampler_impl(metal_handle *sampler) {
    if (sampler == NULL) return;

    @autoreleasepool {
        id<MTLSamplerState> samplerState = (__bridge_transfer id<MTLSamplerState>)sampler;
        (void)samplerState; // ARC will handle release
    }
}

void metal_set_fragment_samplers_impl(metal_handle *encoder, varray *samplers) {
    if (encoder == NULL || samplers == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;

        int count = samplers->size;
        if (count <= 0) return;

        // Convert varray to id<MTLSamplerState> array
        id<MTLSamplerState> samplerArray[count];
        metal_handle **samplerPtrs = hl_aptr(samplers, metal_handle*);

        for (int i = 0; i < count; i++) {
            samplerArray[i] = (__bridge id<MTLSamplerState>)samplerPtrs[i];
        }

        [renderEncoder setFragmentSamplerStates:samplerArray withRange:NSMakeRange(0, count)];
    }
}

void metal_set_fragment_sampler_impl(metal_handle *encoder, metal_handle *sampler, int index) {
    if (encoder == NULL || sampler == NULL) return;

    @autoreleasepool {
        id<MTLRenderCommandEncoder> renderEncoder = (__bridge id<MTLRenderCommandEncoder>)encoder;
        id<MTLSamplerState> samplerState = (__bridge id<MTLSamplerState>)sampler;
        [renderEncoder setFragmentSamplerState:samplerState atIndex:index];
    }
}
