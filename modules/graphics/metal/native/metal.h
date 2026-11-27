#ifndef METAL_H
#define METAL_H

#define HL_NAME(n) limen_metal_##n

#include <hl.h>
#include "native_window.h"

typedef void metal_handle;
#define THANDLE _ABSTRACT(limen_metal_handle)
#define TWIN _ABSTRACT(limen_window)
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.h>
#include <simd/simd.h>
#include <stdarg.h>  // Add this for va_list

// Buffer usage flags (match h3d.Buffer.BufferFlag enum)
#define BUFFER_FLAG_DYNAMIC      (1 << 0)  // Dynamic buffer content
#define BUFFER_FLAG_VERTEX_READ  (1 << 1)  // Used as vertex buffer
#define BUFFER_FLAG_COMPUTE_WRITE (1 << 2) // Written by compute shaders

// Forward declarations
typedef struct metal_context metal_context;

typedef struct metal_render_layout {
    int formats[10];
    int id;
    struct metal_render_layout *next;
} metal_render_layout;

enum {
    METAL_STREAM_BUFFER = 1 << 3,
    METAL_BUFFER_POOL_COUNT = 128,
    METAL_BUFFER_POOL_BYTES = 8 * 1024 * 1024,
    METAL_TEXTURE_POOL_COUNT = 64,
    METAL_TEXTURE_POOL_BYTES = 32 * 1024 * 1024,
};

typedef struct {
    unsigned id, passes, draws, buffers, textures, pipelines, libraries, renames;
    size_t uploadBytes, copyBytes, constantBytes;
    double start, drawable, compile;
    double drawableAcquired;
    unsigned passesBeforeDrawable, drawsBeforeDrawable;
    unsigned bufferReuses, viewportSets, scissorSets;
    unsigned textureReuses;
    unsigned passDescriptors;
    int windowState;
    double commandCreate, encoderCreate, encoderEnd, bufferAlloc, textureAlloc, upload, presentRegister, sizeQuery;
    double texturePoolLookup;
} metal_profile_sample;

typedef struct {
    void *texture;
    NSUInteger key[5];
} metal_pooled_texture;

// Main context structure - use void* for ARC compatibility
struct metal_context {
    void *device;              // id<MTLDevice>
    void *commandQueue;        // id<MTLCommandQueue>
    void *layer;               // CAMetalLayer*
    void *metalView;
    void *window;
    bool windowSetup;
    bool profileEnabled;
    bool profileDetailed;
    unsigned profileInterval;
    void *profileCounterSet;
    void *profilePassFrame;
    unsigned profileSequence;
    metal_profile_sample profile;
    void *bufferPool[METAL_BUFFER_POOL_COUNT];
    NSUInteger bufferPoolCount;
    NSUInteger bufferPoolBytes;
    bool texturePoolEnabled;
    metal_pooled_texture texturePool[METAL_TEXTURE_POOL_COUNT];
    NSUInteger texturePoolCount;
    NSUInteger texturePoolBytes;
    bool reusePassDescriptors;
    void *passDescriptors[4];

    // Current frame rendering state
    void *currentDrawable;     // id<CAMetalDrawable>
    void *currentCommandBuffer; // id<MTLCommandBuffer>
    void *backbufferEncoder;    // Borrowed until endEncoding

    MTLPixelFormat colorFormats[8];
    metal_render_layout *layouts;
    int layoutCount;
    void *depthStates[16];
    MTLPixelFormat depthFormat;
    MTLPixelFormat stencilFormat;
    NSUInteger targetWidth;
    NSUInteger targetHeight;
    bool depthReadOnly;

    // Depth buffer
    void *depthTexture;               // id<MTLTexture>

    // Depth-stencil state cache
    void *depthStencilStateCache;     // NSMutableDictionary*
};

// Global context
extern metal_context *ctx;
#define METAL_PROFILE(field, amount) do { if (ctx->profileEnabled) ctx->profile.field += (amount); } while (0)

// ============================================================================
// Debug/Logging System
// ============================================================================
// Compile with -DMETAL_DEBUG to enable verbose logging
// Without this flag, all debug/warning/info logs compile to nothing (zero overhead)
//
// Logging levels (when METAL_DEBUG is defined):
// 0 = errors only (default)
// 1 = warnings + errors
// 2 = info + warnings + errors  
// 3 = verbose (all debug output)

// Error logging - ALWAYS available (errors indicate real problems)
void metal_log_error_impl(const char* message, ...);
#define metal_log_error(...) metal_log_error_impl(__VA_ARGS__)

#ifdef METAL_DEBUG
    // Debug build: logging functions are available and respect log level
    void metal_set_log_level(int level);
    int metal_get_log_level(void);
    void metal_debug_log_impl(const char* message, ...);
    void metal_log_warning_impl(const char* message, ...);
    void metal_log_info_impl(const char* message, ...);
    
    #define metal_debug_log(...) metal_debug_log_impl(__VA_ARGS__)
    #define metal_log_warning(...) metal_log_warning_impl(__VA_ARGS__)
    #define metal_log_info(...) metal_log_info_impl(__VA_ARGS__)
#else
    // Release build: all non-error logging compiles to nothing (zero overhead)
    static inline void metal_set_log_level(int level) { (void)level; }
    static inline int metal_get_log_level(void) { return 0; }
    
    #define metal_debug_log(...) ((void)0)
    #define metal_log_warning(...) ((void)0)
    #define metal_log_info(...) ((void)0)
#endif

// Context management functions (metal_context.m)
void metal_init_context(void);
bool metal_setup_window_context(void *window);
bool metal_update_drawable_size(void);
void metal_shutdown_context(void);

// Resources (metal_resources.m)
metal_handle* metal_create_buffer_impl(int size, int usage);
bool metal_upload_buffer_data_impl(metal_handle *buffer, vbyte *data, int size, int offset);
metal_handle* metal_create_texture_impl(int width, int height, int format, int usage, bool mipmapped, bool isCube, int arrayLength);
bool metal_upload_texture_data_impl(metal_handle *texture, vbyte *data, int width, int height, int level, int slice);
bool metal_capture_texture_pixels_impl(metal_handle *texture, vbyte *data, int x, int y, int width, int height, int level, int slice);
void metal_generate_mipmaps_impl(metal_handle *texture);
void metal_dispose_texture_impl(metal_handle *texture);
metal_handle* metal_create_sampler_state_impl(int minFilter, int magFilter, int mipFilter, int wrapS, int wrapT);
void metal_dispose_buffer_impl(metal_handle *buffer);
void metal_dispose_sampler_impl(metal_handle *sampler);
void metal_set_fragment_samplers_impl(metal_handle *encoder, varray *samplers);
void metal_set_fragment_sampler_impl(metal_handle *encoder, metal_handle *sampler, int index);

// Pipeline (metal_pipeline.m)
metal_handle* metal_compile_shader_impl(vstring *source, int shaderType);
metal_handle* metal_create_render_pipeline_impl(metal_handle *vertexShader, metal_handle *fragmentShader, vstring *vertexDesc, int blendSrc, int blendDst, int blendAlphaSrc, int blendAlphaDst, int blendOp, int blendAlphaOp, int colorMask);
metal_handle* metal_create_compute_pipeline_from_function_impl(metal_handle *func);
void metal_dispose_pipeline_impl(metal_handle *pipeline);

// Render (metal_render.m)
metal_handle* metal_begin_render_pass_impl(metal_handle *cmdBuffer, bool clearColor, double r, double g, double b, double a, double clearDepth, int stencil);
metal_handle* metal_begin_texture_render_pass_impl(metal_handle *cmdBuffer, metal_handle *texture, int r, int g, int b, int a, metal_handle *depthTexParam, int layer, int mipLevel, int depthAction, double clearDepth, int stencil);
metal_handle* metal_begin_mrt_render_pass_impl(metal_handle *cmdBuffer, varray *textures, int r, int g, int b, int a, int clearMask, metal_handle *depthTex, int depthAction, double clearDepth, int stencil);
metal_handle* metal_begin_depth_render_pass_impl(metal_handle *cmdBuffer, metal_handle *depthTexture, int layer, bool clear, double clearDepth, int stencil);
void metal_set_render_pipeline_state_impl(metal_handle *encoder, metal_handle *pipeline);
void metal_set_depth_state_impl(metal_handle *encoder, bool depthTest, bool depthWrite);
void metal_set_stencil_state_impl(metal_handle *encoder, int depthCompareFunc, bool depthWrite, int frontFunc, int frontSTfail, int frontDPfail, int frontPass, int backFunc, int backSTfail, int backDPfail, int backPass, int reference, int readMask, int writeMask);
void metal_set_cull_mode_impl(metal_handle *encoder, int cullMode);
void metal_set_triangle_fill_mode_impl(metal_handle *encoder, bool wireframe);
void metal_set_viewport_impl(metal_handle *encoder, double x, double y, double width, double height);
void metal_set_scissor_rect_impl(metal_handle *encoder, int x, int y, int width, int height);
void metal_set_vertex_buffer_impl(metal_handle *encoder, metal_handle *buffer, int offset, int index);
void metal_set_vertex_bytes_impl(metal_handle *encoder, vbyte *data, int length, int index);
void metal_set_fragment_bytes_impl(metal_handle *encoder, vbyte *data, int length, int index);
void metal_set_fragment_texture_impl(metal_handle *encoder, metal_handle *texture, int index);
void metal_set_fragment_buffer_impl(metal_handle *encoder, metal_handle *buffer, int offset, int index);
void metal_draw_primitives_impl(metal_handle *encoder, int primitiveType, int vertexStart, int vertexCount);
void metal_draw_indexed_primitives_impl(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int is32bit);
bool metal_draw_indexed_ranges_impl(metal_handle *encoder, metal_handle *indexBuffer, varray *ranges, int count, int indexLimit, int stride);
void metal_draw_indexed_primitives_instanced_impl(metal_handle *encoder, int primitiveType, int indexCount, metal_handle *indexBuffer, int indexOffset, int instanceCount, int is32bit);
void metal_end_encoding_impl(metal_handle *encoder);

// Compute (metal_compute.m)
metal_handle* metal_create_compute_pipeline_impl(vbyte *source, vbyte *functionName);
void metal_set_compute_pipeline_impl(metal_handle *pipeline);
void metal_set_compute_buffer_impl(metal_handle *buffer, int index);
void metal_set_compute_texture_impl(metal_handle *texture, int index);
bool metal_dispatch_compute_impl(metal_handle *cmdBuffer, int x, int y, int z);
void metal_memory_barrier_impl(metal_handle *cmdBuffer);

#endif // METAL_H
