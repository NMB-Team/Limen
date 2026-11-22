// use registry values so older SDL EGL headers work too
static bool limen_egl_robustness(int* attributes, int* count, int* flags,
	bool core15, bool ext, bool khr, bool es, bool notify) {
	bool robust = (*flags & SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG) != 0;
	if (!robust && !notify) return true;

	if (core15 || (es && ext)) {
		if (robust) {
			attributes[(*count)++] = core15 ? 0x31B2 : 0x30BF;
			attributes[(*count)++] = 1;
		}
		if (notify) {
			attributes[(*count)++] = core15 ? 0x31BD : 0x3138;
			attributes[(*count)++] = 0x31BF;
		}
		*flags &= ~SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG;
		return true;
	}

	if (!es && khr) {
		if (notify) {
			attributes[(*count)++] = 0x31BD;
			attributes[(*count)++] = 0x31BF;
		}
		return true;
	}

	return SDL_SetError("EGL reset notification attributes are not supported");
}
