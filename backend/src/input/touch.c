#include "../core/internal.h"

HL_PRIM varray* HL_NAME(get_touch_devices)() {
	int count = 0;
	SDL_TouchID* devices = SDL_GetTouchDevices(&count);
	if (devices == nullptr)
		return nullptr;
	varray* result = hl_alloc_array(&hlt_i64, count);
	memcpy(hl_aptr(result, int64_t), devices, count * sizeof(SDL_TouchID));
	SDL_free(devices);
	return result;
}
DEFINE_PRIM(_ARR, get_touch_devices, _NO_ARG);

HL_PRIM vbyte* HL_NAME(get_touch_device_name)(int64_t id) {
	return (vbyte*)SDL_GetTouchDeviceName((SDL_TouchID)id);
}
DEFINE_PRIM(_BYTES, get_touch_device_name, _I64);

HL_PRIM int HL_NAME(get_touch_device_type)(int64_t id) {
	return SDL_GetTouchDeviceType((SDL_TouchID)id);
}
DEFINE_PRIM(_I32, get_touch_device_type, _I64);

HL_PRIM varray* HL_NAME(get_touch_fingers)(int64_t id) {
	int count = 0;
	SDL_Finger** fingers = SDL_GetTouchFingers((SDL_TouchID)id, &count);
	if (fingers == nullptr)
		return nullptr;
	varray* result = hl_alloc_array(&hlt_dynobj, count);
	for (int i = 0; i < count; i++) {
		vdynamic* object = (vdynamic*)hl_alloc_dynobj();
		hl_dyn_seti64(object, hl_hash_utf8("id"), (int64_t)fingers[i]->id);
		hl_dyn_setd(object, hl_hash_utf8("x"), fingers[i]->x);
		hl_dyn_setd(object, hl_hash_utf8("y"), fingers[i]->y);
		hl_dyn_setd(object, hl_hash_utf8("pressure"), fingers[i]->pressure);
		hl_aptr(result, vdynamic*)[i] = object;
	}
	SDL_free(fingers);
	return result;
}
DEFINE_PRIM(_ARR, get_touch_fingers, _I64);
