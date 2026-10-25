#pragma once

#include <hl.h>
#include "../types.h"

enum { FsrInvalidState = -3, FsrNotLoaded = -1, FsrOk = 0, FsrErrorParameter = 6 };

struct FsrDispatchParams {
	TextureResource* color;
	TextureResource* depth;
	TextureResource* motionVectors;
	TextureResource* exposure;
	TextureResource* reactive;
	TextureResource* transparencyAndComposition;
	TextureResource* output;
	float jitterOffsetX;
	float jitterOffsetY;
	float motionVectorScaleX;
	float motionVectorScaleY;
	int renderWidth;
	int renderHeight;
	int upscaleWidth;
	int upscaleHeight;
	float sharpness;
	float frameTimeDelta;
	float preExposure;
	float cameraNear;
	float cameraFar;
	float cameraFovAngleVertical;
	float viewSpaceToMetersFactor;
	int flags;
	bool enableSharpening;
	bool reset;
};

struct FsrBackend {
	int (*init)(PostProcessDevice*, int);
	int (*shutdown)();
	int (*renderResolution)(PostProcessDevice*, int, int, int, int*, int*);
	void* (*createContext)(PostProcessDevice*, int, int, int, int, int, int*);
	int (*destroyContext)(void*);
	vbyte* (*version)(void*);
	int (*dispatch)(void*, void*, FsrDispatchParams*);
	int (*versionCount)(PostProcessDevice*, int, int*);
	vbyte* (*versionName)(PostProcessDevice*, int, int);
};

struct FsrContext {
	const FsrBackend* backend;
	void* native;
};

#ifdef LIMEN_POSTPROCESS_D3D12
extern const FsrBackend fsrD3D12;
#endif
#ifdef LIMEN_POSTPROCESS_VULKAN
extern const FsrBackend fsrVulkan;
#endif

FsrContext* wrapFsrContext(const FsrBackend* backend, void* native);
