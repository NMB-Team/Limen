#include "metal.h"

metal_context *ctx = NULL;
static id<MTLCommandBuffer> metal_last_submitted_command;

enum { METAL_PROFILE_PASS_LIMIT = 64 };
typedef struct {
    char name[128];
    unsigned width, height, color, depth, load, store, draws, firstDraw;
    unsigned shaderIds[16], shaderDraws[16], shaderCount;
    int shader;
    double start, cpu;
} metal_pass_sample;

@interface LimenMetalPassFrame : NSObject {
@public
    metal_pass_sample passes[METAL_PROFILE_PASS_LIMIT];
    unsigned count;
}
@property (nonatomic, strong) id<MTLCounterSampleBuffer> counters;
@property (nonatomic) MTLTimestamp cpuStart;
@property (nonatomic) MTLTimestamp gpuStart;
@end
@implementation LimenMetalPassFrame
@end

static void metal_profile_begin_command(void) {
    if (!ctx->profileDetailed || ctx->profile.id % ctx->profileInterval != 0) return;
    LimenMetalPassFrame *frame = [LimenMetalPassFrame new];
    if (ctx->profileCounterSet != NULL) {
        MTLCounterSampleBufferDescriptor *descriptor = [MTLCounterSampleBufferDescriptor new];
        descriptor.counterSet = (__bridge id<MTLCounterSet>)ctx->profileCounterSet;
        descriptor.storageMode = MTLStorageModeShared;
        descriptor.sampleCount = METAL_PROFILE_PASS_LIMIT * 4;
        NSError *error = nil;
        frame.counters = [(__bridge id<MTLDevice>)ctx->device newCounterSampleBufferWithDescriptor:descriptor error:&error];
        if (frame.counters == nil)
            metal_log_error("GPU timestamp allocation failed: %s", error.localizedDescription.UTF8String);
    }
    MTLTimestamp cpu, gpu;
    [(__bridge id<MTLDevice>)ctx->device sampleTimestamps:&cpu gpuTimestamp:&gpu];
    frame.cpuStart = cpu;
    frame.gpuStart = gpu;
    ctx->profilePassFrame = (__bridge_retained void *)frame;
}

static void metal_profile_begin_pass(MTLRenderPassDescriptor *pass) {
    LimenMetalPassFrame *frame = (__bridge LimenMetalPassFrame *)ctx->profilePassFrame;
    if (frame == nil) return;
    unsigned index = frame->count++;
    if (index >= METAL_PROFILE_PASS_LIMIT) return;
    metal_pass_sample *sample = &frame->passes[index];
    id<MTLTexture> color = pass.colorAttachments[0].texture;
    id<MTLTexture> target = color != nil ? color : pass.depthAttachment.texture;
    sample->width = (unsigned)MAX(1, target.width >> (color != nil ? pass.colorAttachments[0].level : pass.depthAttachment.level));
    sample->height = (unsigned)MAX(1, target.height >> (color != nil ? pass.colorAttachments[0].level : pass.depthAttachment.level));
    sample->color = (unsigned)color.pixelFormat;
    sample->depth = (unsigned)pass.depthAttachment.texture.pixelFormat;
    sample->load = (unsigned)pass.colorAttachments[0].loadAction;
    sample->store = (unsigned)pass.colorAttachments[0].storeAction;
    sample->shader = -1;
    sample->firstDraw = ctx->profile.draws;
    sample->start = CACurrentMediaTime();
    snprintf(sample->name, sizeof(sample->name), "%s", "backbuffer");
    if (frame.counters != nil) {
        MTLRenderPassSampleBufferAttachmentDescriptor *attachment = pass.sampleBufferAttachments[0];
        attachment.sampleBuffer = frame.counters;
        attachment.startOfVertexSampleIndex = index * 4;
        attachment.endOfVertexSampleIndex = index * 4 + 1;
        attachment.startOfFragmentSampleIndex = index * 4 + 2;
        attachment.endOfFragmentSampleIndex = index * 4 + 3;
    }
}

static void metal_profile_end_pass(void) {
    LimenMetalPassFrame *frame = (__bridge LimenMetalPassFrame *)ctx->profilePassFrame;
    if (frame == nil || frame->count == 0 || frame->count > METAL_PROFILE_PASS_LIMIT) return;
    metal_pass_sample *sample = &frame->passes[frame->count - 1];
    sample->draws = ctx->profile.draws - sample->firstDraw;
    sample->cpu = CACurrentMediaTime() - sample->start;
}

static void metal_profile_draw(unsigned count) {
    METAL_PROFILE(draws, count);
    LimenMetalPassFrame *frame = (__bridge LimenMetalPassFrame *)ctx->profilePassFrame;
    if (frame == nil || frame->count == 0 || frame->count > METAL_PROFILE_PASS_LIMIT) return;
    metal_pass_sample *pass = &frame->passes[frame->count - 1];
    for (unsigned i = 0; i < pass->shaderCount; i++)
        if (pass->shaderIds[i] == (unsigned)pass->shader) { pass->shaderDraws[i] += count; return; }
    if (pass->shaderCount < 16) {
        unsigned i = pass->shaderCount++;
        pass->shaderIds[i] = (unsigned)pass->shader;
        pass->shaderDraws[i] = count;
    }
}

static double metal_profile_gpu_delta(const MTLCounterResultTimestamp *times, unsigned start, unsigned end, double scale) {
    uint64_t a = times[start].timestamp, b = times[end].timestamp;
    return a != 0 && b != 0 && a != MTLCounterErrorValue && b != MTLCounterErrorValue && b >= a ? (b - a) * scale : -1;
}

static void metal_profile_resolve(LimenMetalPassFrame *frame, unsigned sequence) {
    if (frame == nil) return;
    @autoreleasepool {
        MTLTimestamp cpuEnd = 0, gpuEnd = 0;
        [frame.counters.device sampleTimestamps:&cpuEnd gpuTimestamp:&gpuEnd];
        double scale = cpuEnd > frame.cpuStart && gpuEnd > frame.gpuStart
            ? (double)(cpuEnd - frame.cpuStart) / (gpuEnd - frame.gpuStart) / 1000000 : -1;
        fprintf(stderr, "metal-counter-scale,%u,%.12f\n", sequence, scale);
        unsigned count = MIN(frame->count, METAL_PROFILE_PASS_LIMIT);
        NSData *data = [frame.counters resolveCounterRange:NSMakeRange(0, count * 4)];
        const MTLCounterResultTimestamp *times = scale > 0 && data.length >= count * 4 * sizeof(MTLCounterResultTimestamp) ? data.bytes : NULL;
        for (unsigned i = 0; i < count; i++) {
            const metal_pass_sample *pass = &frame->passes[i];
            double vertex = times == NULL ? -1 : metal_profile_gpu_delta(times, i * 4, i * 4 + 1, scale);
            double fragment = times == NULL ? -1 : metal_profile_gpu_delta(times, i * 4 + 2, i * 4 + 3, scale);
            double span = times == NULL ? -1 : metal_profile_gpu_delta(times, i * 4, i * 4 + 3, scale);
            fprintf(stderr, "metal-pass,%u,%u,%s,%u,%u,%u,%u,%u,%u,%u,%.6f,%.6f,%.6f,%.6f\n",
                sequence, i, pass->name, pass->width, pass->height, pass->color, pass->depth,
                pass->load, pass->store, pass->draws, pass->cpu * 1000, vertex, fragment, span);
            for (unsigned j = 0; j < pass->shaderCount; j++)
                fprintf(stderr, "metal-pass-shader,%u,%u,%u,%u\n", sequence, i, pass->shaderIds[j], pass->shaderDraws[j]);
        }
    }
}

static void metal_profile_copy(void *destination, const void *source, size_t size) {
    double start = ctx->profileDetailed ? CACurrentMediaTime() : 0;
    memcpy(destination, source, size);
    if (ctx->profileDetailed) ctx->profile.upload += CACurrentMediaTime() - start;
}

// ============================================================================
// Error logging - ALWAYS compiled in (errors indicate real problems)
// ============================================================================
void metal_log_error_impl(const char* message, ...) {
    va_list args;
    va_start(args, message);
    fprintf(stderr, "[METAL ERROR] ");
    vfprintf(stderr, message, args);
    fprintf(stderr, "\n");
    fflush(stderr);
    va_end(args);
}

// ============================================================================
// Debug logging - Only compiled when METAL_DEBUG is defined
// ============================================================================
#ifdef METAL_DEBUG

static int metal_log_level = 0;  // Default: errors only

void metal_set_log_level(int level) {
    metal_log_level = level;
    if (level > 0) {
        fprintf(stderr, "[METAL] Log level set to %d\n", level);
    }
}

int metal_get_log_level(void) {
    return metal_log_level;
}

void metal_debug_log_impl(const char* message, ...) {
    if (metal_log_level < 3) return;
    
    va_list args;
    va_start(args, message);
    fprintf(stderr, "[METAL] ");
    vfprintf(stderr, message, args);
    fprintf(stderr, "\n");
    fflush(stderr);
    va_end(args);
}

void metal_log_warning_impl(const char* message, ...) {
    if (metal_log_level < 1) return;
    
    va_list args;
    va_start(args, message);
    fprintf(stderr, "[METAL WARNING] ");
    vfprintf(stderr, message, args);
    fprintf(stderr, "\n");
    fflush(stderr);
    va_end(args);
}

void metal_log_info_impl(const char* message, ...) {
    if (metal_log_level < 2) return;
    
    va_list args;
    va_start(args, message);
    fprintf(stderr, "[METAL INFO] ");
    vfprintf(stderr, message, args);
    fprintf(stderr, "\n");
    fflush(stderr);
    va_end(args);
}

#endif // METAL_DEBUG

void metal_init_context(void) {
    if (ctx != NULL) return;

    metal_debug_log("Metal init() called");

    @autoreleasepool {
        ctx = (metal_context*)calloc(1, sizeof(metal_context)); // Use calloc to zero-initialize

        ctx->profileEnabled = getenv("LIMEN_METAL_PROFILE") != NULL;
        const char *texturePool = getenv("LIMEN_METAL_TEXTURE_POOL");
        ctx->texturePoolEnabled = texturePool == NULL || strcmp(texturePool, "0") != 0;
        const char *passDescriptors = getenv("LIMEN_METAL_PASS_DESCRIPTORS");
        ctx->reusePassDescriptors = passDescriptors == NULL || strcmp(passDescriptors, "0") != 0;
        ctx->profileDetailed = ctx->profileEnabled && getenv("LIMEN_METAL_PROFILE_DETAIL") != NULL;
        const char *interval = getenv("LIMEN_METAL_PROFILE_INTERVAL");
        long parsed = interval == NULL ? 30 : strtol(interval, NULL, 10);
        ctx->profileInterval = parsed > 0 && parsed <= 100000 ? (unsigned)parsed : 30;

        // Get the default Metal device
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        if (!device) {
            metal_debug_log("Metal is not supported on this device");
            free(ctx);
            ctx = NULL;
            return;
        }

        ctx->device = (__bridge_retained void*)device; // Bridge with retain
        if (ctx->profileDetailed) {
            if ([device supportsFamily:MTLGPUFamilyApple1] && [device supportsCounterSampling:MTLCounterSamplingPointAtStageBoundary])
                for (id<MTLCounterSet> counters in device.counterSets)
                    if ([counters.name isEqualToString:MTLCommonCounterSetTimestamp]) {
                        ctx->profileCounterSet = (__bridge_retained void *)counters;
                        break;
                    }
            fprintf(stderr, "metal-detail,counters=%d,interval=%u\n", ctx->profileCounterSet != NULL, ctx->profileInterval);
        }
        metal_debug_log("Metal device created: %s", [[device name] UTF8String]);

        // Create a command queue
        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        if (!commandQueue) {
            metal_debug_log("Failed to create Metal command queue");
            // Release device before freeing context
            id<MTLDevice> deviceToRelease = (__bridge_transfer id<MTLDevice>)ctx->device;
            (void)deviceToRelease; // Suppress unused variable warning - ARC will handle release
            free(ctx);
            ctx = NULL;
            return;
        }

        ctx->commandQueue = (__bridge_retained void*)commandQueue; // Bridge with retain
        metal_debug_log("Metal command queue created");

        ctx->windowSetup = false;
        metal_debug_log("Metal init complete");
    }
}

bool metal_setup_window_context(void *window) {
    if (ctx == NULL || window == NULL || ctx->windowSetup)
        return false;

    @autoreleasepool {
        void *layerHandle;
        if (!limen_metal_create_view(window, &ctx->metalView, &layerHandle)) {
            metal_log_error("Failed to create Metal view for the SDL window");
            return false;
        }
        ctx->window = window;
        CAMetalLayer *layer = (__bridge CAMetalLayer *)layerHandle;
        ctx->layer = (__bridge_retained void *)layer;
        layer.device = (__bridge id<MTLDevice>)ctx->device;
        layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
        layer.framebufferOnly = YES;
        layer.opaque = YES;
        layer.magnificationFilter = kCAFilterNearest;
        layer.minificationFilter = kCAFilterNearest;
        ctx->windowSetup = true;
    }
    return true;
}

bool metal_update_drawable_size(void) {
    int width, height;
    if (!limen_metal_get_pixel_size(ctx->window, &width, &height) || width <= 0 || height <= 0)
        return false;

    CAMetalLayer *layer = (__bridge CAMetalLayer *)ctx->layer;
    id<MTLTexture> depth = (__bridge id<MTLTexture>)ctx->depthTexture;
    if (depth == nil || depth.width != (NSUInteger)width || depth.height != (NSUInteger)height) {
        MTLTextureDescriptor *descriptor = [MTLTextureDescriptor
            texture2DDescriptorWithPixelFormat:MTLPixelFormatDepth32Float_Stencil8
            width:width height:height mipmapped:NO];
        descriptor.usage = MTLTextureUsageRenderTarget;
        descriptor.storageMode = MTLStorageModePrivate;
        id<MTLTexture> replacement = [layer.device newTextureWithDescriptor:descriptor];
        if (replacement) METAL_PROFILE(textures, 1);
        if (replacement == nil) {
            metal_log_error("Failed to allocate %dx%d backbuffer depth texture", width, height);
            return false;
        }
        if (ctx->depthTexture)
            CFRelease(ctx->depthTexture);
        ctx->depthTexture = (__bridge_retained void *)replacement;
    }
    CGSize size = CGSizeMake(width, height);
    if (!CGSizeEqualToSize(layer.drawableSize, size))
        layer.drawableSize = size;
    return true;
}

void metal_shutdown_context(void) {
    if (ctx != NULL) {
        @autoreleasepool {
            metal_last_submitted_command = nil;
            if (ctx->profilePassFrame) CFRelease(ctx->profilePassFrame);
            if (ctx->profileCounterSet) CFRelease(ctx->profileCounterSet);

            // Destroy SDL Metal view
            if (ctx->metalView) {
                limen_metal_destroy_view(ctx->metalView);
                ctx->metalView = NULL;
            }

            for (NSUInteger i = 0; i < ctx->bufferPoolCount; i++)
                CFRelease(ctx->bufferPool[i]);
            for (NSUInteger i = 0; i < ctx->texturePoolCount; i++)
                CFRelease(ctx->texturePool[i].texture);
            for (int i = 0; i < 4; i++)
                if (ctx->passDescriptors[i]) CFRelease(ctx->passDescriptors[i]);

            // Release retained production resources
            if (ctx->depthTexture) {
                id<MTLTexture> depthTexture = (__bridge_transfer id<MTLTexture>)ctx->depthTexture;
                (void)depthTexture;
                ctx->depthTexture = NULL;
            }

            for (int i = 0; i < 16; i++)
                if (ctx->depthStates[i] != NULL) CFRelease(ctx->depthStates[i]);
            while (ctx->layouts != NULL) {
                metal_render_layout *layout = ctx->layouts;
                ctx->layouts = layout->next;
                free(layout);
            }

            if (ctx->depthStencilStateCache) {
                NSMutableDictionary *cache = (__bridge_transfer NSMutableDictionary *)ctx->depthStencilStateCache;
                (void)cache;
                ctx->depthStencilStateCache = NULL;
            }

            // Release Metal resources with proper ARC handling
            if (ctx->commandQueue) {
                id<MTLCommandQueue> commandQueue = (__bridge_transfer id<MTLCommandQueue>)ctx->commandQueue;
                (void)commandQueue; // Suppress unused variable warning - ARC will handle release
                ctx->commandQueue = NULL;
            }

            if (ctx->layer) {
                CAMetalLayer* layer = (__bridge_transfer CAMetalLayer*)ctx->layer;
                (void)layer; // Suppress unused variable warning - ARC will handle release
                ctx->layer = NULL;
            }

            if (ctx->device) {
                id<MTLDevice> device = (__bridge_transfer id<MTLDevice>)ctx->device;
                (void)device; // Suppress unused variable warning - ARC will handle release
                ctx->device = NULL;
            }
        }

        free(ctx);
        ctx = NULL;
    }
}

