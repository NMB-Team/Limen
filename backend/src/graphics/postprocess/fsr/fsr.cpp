#define HL_NAME(n) limen_fsr_##n
#include "backend.h"

#define _CONTEXT _ABSTRACT(fsr_context)
#define _COMMAND_BUFFER _ABSTRACT(postprocess_command_buffer)

static const FsrBackend* activeBackend;
static int liveContexts;

static const FsrBackend* getBackend(PostProcessDevice* device) {
	if (device == nullptr || device->device == nullptr)
		return nullptr;
	switch (device->backend) {
#ifdef LIMEN_POSTPROCESS_D3D12
	case PostProcessBackend::D3D12: return &fsrD3D12;
#endif
#ifdef LIMEN_POSTPROCESS_VULKAN
	case PostProcessBackend::Vulkan:
		return device->instance != nullptr && device->physicalDevice != nullptr ? &fsrVulkan : nullptr;
#endif
	default: return nullptr;
	}
}

HL_PRIM int HL_NAME(init)(PostProcessDevice* device, int debugLevel) {
	const auto backend = getBackend(device);
	if (backend == nullptr) return FsrErrorParameter;
	if (activeBackend != nullptr) return FsrInvalidState;
	const int result = backend->init(device, debugLevel);
	if (result == FsrOk) activeBackend = backend;
	return result;
}

HL_PRIM int HL_NAME(shutdown)() {
	if (activeBackend == nullptr) return FsrNotLoaded;
	if (liveContexts != 0) return FsrInvalidState;
	const int result = activeBackend->shutdown();
	if (result == FsrOk) activeBackend = nullptr;
	return result;
}

HL_PRIM int HL_NAME(get_render_resolution)(PostProcessDevice* device, int quality, int width, int height, int* renderWidth, int* renderHeight) {
	if (activeBackend == nullptr) return FsrNotLoaded;
	if (getBackend(device) != activeBackend) return FsrErrorParameter;
	return activeBackend->renderResolution(device, quality, width, height, renderWidth, renderHeight);
}

FsrContext* wrapFsrContext(const FsrBackend* backend, void* native) {
	liveContexts++;
	return new FsrContext{backend, native};
}

HL_PRIM FsrContext* HL_NAME(create_context)(PostProcessDevice* device, int flags, int renderWidth, int renderHeight, int outputWidth, int outputHeight, int* result) {
	if (result == nullptr) return nullptr;
	if (activeBackend == nullptr || getBackend(device) != activeBackend) {
		*result = activeBackend == nullptr ? FsrNotLoaded : FsrErrorParameter;
		return nullptr;
	}
	void* native = activeBackend->createContext(device, flags, renderWidth, renderHeight, outputWidth, outputHeight, result);
	if (native == nullptr) return nullptr;
	return wrapFsrContext(activeBackend, native);
}

HL_PRIM int HL_NAME(destroy_context)(FsrContext* context) {
	if (context == nullptr) return FsrErrorParameter;
	const int result = context->backend->destroyContext(context->native);
	if (result == FsrOk) {
		liveContexts--;
		delete context;
	}
	return result;
}

HL_PRIM vbyte* HL_NAME(get_version_name)(FsrContext* context) {
	return context == nullptr ? nullptr : context->backend->version(context->native);
}

HL_PRIM int HL_NAME(dispatch)(FsrContext* context, void* commands, FsrDispatchParams* params) {
	if (activeBackend == nullptr) return FsrNotLoaded;
	if (context == nullptr || context->backend != activeBackend || commands == nullptr || params == nullptr
		|| params->color == nullptr || params->depth == nullptr || params->motionVectors == nullptr || params->output == nullptr
		|| params->color->native == nullptr || params->depth->native == nullptr || params->motionVectors->native == nullptr || params->output->native == nullptr
		|| params->renderWidth <= 0 || params->renderHeight <= 0 || params->upscaleWidth <= 0 || params->upscaleHeight <= 0
		|| (params->flags & ~7) != 0)
		return FsrErrorParameter;
	return context->backend->dispatch(context->native, commands, params);
}

HL_PRIM int HL_NAME(get_effect_version_count)(PostProcessDevice* device, int effect, int* count) {
	if (count == nullptr) return FsrErrorParameter;
	*count = 0;
	if (activeBackend == nullptr) return FsrNotLoaded;
	if (getBackend(device) != activeBackend) return FsrErrorParameter;
	return activeBackend->versionCount(device, effect, count);
}

HL_PRIM vbyte* HL_NAME(get_effect_version_name)(PostProcessDevice* device, int effect, int index) {
	if (activeBackend == nullptr || getBackend(device) != activeBackend) return nullptr;
	return activeBackend->versionName(device, effect, index);
}

DEFINE_PRIM(_I32, init, _STRUCT _I32);
DEFINE_PRIM(_I32, shutdown, _NO_ARG);
DEFINE_PRIM(_I32, get_render_resolution, _STRUCT _I32 _I32 _I32 _REF(_I32) _REF(_I32));
DEFINE_PRIM(_CONTEXT, create_context, _STRUCT _I32 _I32 _I32 _I32 _I32 _REF(_I32));
DEFINE_PRIM(_I32, destroy_context, _CONTEXT);
DEFINE_PRIM(_BYTES, get_version_name, _CONTEXT);
DEFINE_PRIM(_I32, dispatch, _CONTEXT _COMMAND_BUFFER _STRUCT);
DEFINE_PRIM(_I32, get_effect_version_count, _STRUCT _I32 _REF(_I32));
DEFINE_PRIM(_BYTES, get_effect_version_name, _STRUCT _I32 _I32);

HL_PRIM bool HL_NAME(is_backend_supported)(PostProcessBackend backend) {
	switch (backend) {
#ifdef LIMEN_POSTPROCESS_D3D12
	case PostProcessBackend::D3D12: return true;
#endif
#ifdef LIMEN_POSTPROCESS_VULKAN
	case PostProcessBackend::Vulkan: return true;
#endif
	default: return false;
	}
}
DEFINE_PRIM(_BOOL, is_backend_supported, _I32);
