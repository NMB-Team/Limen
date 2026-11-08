#ifdef _WIN32
#include <windows.h>

static INIT_ONCE gl_cleanup_once = INIT_ONCE_STATIC_INIT;
static DWORD gl_cleanup_key = FLS_OUT_OF_INDEXES;

static void WINAPI gl_cleanup_callback(void* value) {
	gl_thread_exit();
}

static BOOL CALLBACK gl_create_cleanup_key(PINIT_ONCE once, PVOID parameter, PVOID* context) {
	gl_cleanup_key = FlsAlloc(gl_cleanup_callback);
	return gl_cleanup_key != FLS_OUT_OF_INDEXES;
}

static bool gl_register_thread_cleanup(void) {
	if (gl_cleanup_registered) return true;
	if (!InitOnceExecuteOnce(&gl_cleanup_once, gl_create_cleanup_key, nullptr, nullptr)) return false;
	if (!FlsSetValue(gl_cleanup_key, (void*)1)) return false;

	gl_cleanup_registered = true;
	return true;
}

static void gl_unregister_thread_cleanup(void) {
	if (!gl_cleanup_registered) return;
	FlsSetValue(gl_cleanup_key, nullptr);
	gl_cleanup_registered = false;
}
#else
#include <pthread.h>

static pthread_once_t gl_cleanup_once = PTHREAD_ONCE_INIT;
static pthread_key_t gl_cleanup_key;
static int gl_cleanup_key_error;

static void gl_cleanup_callback(void* value) {
	gl_thread_exit();
}

static void gl_create_cleanup_key(void) {
	gl_cleanup_key_error = pthread_key_create(&gl_cleanup_key, gl_cleanup_callback);
}

static bool gl_register_thread_cleanup(void) {
	if (gl_cleanup_registered) return true;
	if (pthread_once(&gl_cleanup_once, gl_create_cleanup_key) || gl_cleanup_key_error) return false;
	if (pthread_setspecific(gl_cleanup_key, (void*)1)) return false;

	gl_cleanup_registered = true;
	return true;
}

static void gl_unregister_thread_cleanup(void) {
	if (!gl_cleanup_registered) return;
	pthread_setspecific(gl_cleanup_key, nullptr);
	gl_cleanup_registered = false;
}
#endif
