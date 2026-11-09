#include "hlsystem.h"
#include <GL/gl.h>
#include <GL/glext.h>
#include <windows.h>
#include "native_window.h"
#include <string.h>
#include <stdio.h>

typedef struct mock_context {
	const char* version;
	const char* missing;
	GLenum reset;
	int dispatch;
	bool no_notification;
} mock_context;

static bool multi_context_mode;
static __declspec(thread) void* current_context;
static __declspec(thread) void* current_window;
static int activation_calls;
static int binds[2], uploads[2];
static int version_queries, extension_queries, integer_queries, proc_queries, reset_queries, instanced_calls;
static bool missing_reset_core;
static GLenum error_result;
static void APIENTRY test_bind_a(GLenum target, GLuint buffer) { binds[0]++; }
static void APIENTRY test_bind_b(GLenum target, GLuint buffer) { binds[1]++; }
static void APIENTRY test_named_a(GLuint buffer, GLintptr offset, GLsizeiptr size, const void* data) { uploads[0]++; }
static void APIENTRY test_named_b(GLuint buffer, GLintptr offset, GLsizeiptr size, const void* data) { uploads[1]++; }
static GLenum APIENTRY test_context_reset(void) { reset_queries++; return ((mock_context*)current_context)->reset; }
static GLenum APIENTRY test_get_error(void) { return error_result; }
static void APIENTRY test_divisor(GLuint index, GLuint divisor) { instanced_calls++; }
static void APIENTRY test_draw_arrays(GLenum mode, GLint first, GLsizei count, GLsizei instances) { instanced_calls++; }
static void APIENTRY test_draw_elements(GLenum mode, GLsizei count, GLenum type, const void* offset, GLsizei instances) { instanced_calls++; }

static const char* test_version = "2.1";
static const char* test_extensions = "";
static const char* missing_proc;

static const GLubyte* APIENTRY test_get_string(GLenum name) {
	if (name == GL_VERSION) version_queries++;
	if (name == GL_EXTENSIONS) extension_queries++;
	const char* version = multi_context_mode ? ((mock_context*)current_context)->version : test_version;
	return (const GLubyte*)(name == GL_VERSION ? version : test_extensions);
}

static void APIENTRY test_get_integer(GLenum name, GLint* value) {
	integer_queries++;
	if (name == 0x8256) {
		*value = multi_context_mode && ((mock_context*)current_context)->no_notification ? 0x8261 : 0x8252;
		return;
	}
	*value = multi_context_mode && name == 0x82E8 ? 64 : *test_extensions ? 1 : 0;
}

static const GLubyte* APIENTRY test_get_string_i(GLenum name, GLuint index) {
	extension_queries++;
	return (const GLubyte*)test_extensions;
}

static int framebuffer_binds;
static void APIENTRY test_bind_framebuffer(GLenum target, GLuint id) { framebuffer_binds++; }
static void APIENTRY test_delete_framebuffer(GLsizei count, const GLuint* ids) {}
static GLenum reset_result;
static GLenum APIENTRY test_reset(void) { reset_queries++; return reset_result; }
static GLenum APIENTRY test_framebuffer(GLenum target) { return reset_result; }
static void APIENTRY test_noop(void) {}
static void* next_context;
static bool activation_succeeds = true;
static bool activation_drops_current;
static void* test_current_context(void) { return current_context; }
static void* test_create_context(void* window) { current_context = next_context; return next_context; }
static bool test_context_current(void* window, void* context) {
	return current_context == context && current_window == window;
}
static bool test_make_current(void* window, void* context) {
	activation_calls++;
	if (!activation_succeeds) {
		if (activation_drops_current) current_context = nullptr;
		return false;
	}
	current_context = context;
	current_window = window;
	return true;
}
static void test_destroy_context(void* context) { if (current_context == context) current_context = nullptr; }
static bool test_context_error(const char* message) { return false; }

static void* test_resolve(const char* name) {
	proc_queries++;
	if (missing_reset_core && strcmp(name, "glGetGraphicsResetStatus") == 0) return nullptr;
	const char* missing = multi_context_mode ? ((mock_context*)current_context)->missing : missing_proc;
	if (missing && strncmp(name, missing, strlen(missing)) == 0) return nullptr;
	if (multi_context_mode) {
		mock_context* context = current_context;
		if (strcmp(name, "glBindBuffer") == 0) return context->dispatch ? (void*)test_bind_b : (void*)test_bind_a;
		if (strcmp(name, "glNamedBufferSubData") == 0) return context->dispatch ? (void*)test_named_b : (void*)test_named_a;
		if (strcmp(name, "glGetGraphicsResetStatus") == 0) return (void*)test_context_reset;
	}
	if (strcmp(name, "glGetStringi") == 0) return (void*)test_get_string_i;
	if (strncmp(name, "glGetGraphicsResetStatus", strlen("glGetGraphicsResetStatus")) == 0) return (void*)test_reset;
	return (void*)test_noop;
}

#define glGetString test_get_string
#define glGetIntegerv test_get_integer
#define glGetError test_get_error
#define limen_gl_get_proc_address test_resolve
#define limen_gl_context_current test_context_current
#define limen_gl_current_context test_current_context
#define limen_gl_create_context test_create_context
#define limen_gl_make_current test_make_current
#define limen_gl_destroy_context test_destroy_context
#define limen_gl_context_error test_context_error
#undef HL_NAME
#include "../backend/src/graphics/opengl/gl.c"

#define current_readbacks (gl_state()->readbacks)

#define CHECK(condition) do { if (!(condition)) { fprintf(stderr, "Line %d: %s\n", __LINE__, #condition); return 1; } } while (0)

static int deleted_buffers, deleted_fences, mapped_count;
static GLenum wait_result;
static bool map_fails, unmap_fails;
static unsigned char readback_data[16] = { 42 };
static void APIENTRY test_delete_buffers(GLsizei count, const GLuint* buffers) { deleted_buffers += count; }
static void APIENTRY test_delete_sync(GLsync sync) { deleted_fences++; }
static GLenum APIENTRY test_wait(GLsync sync, GLbitfield flags, GLuint64 timeout) { return wait_result; }
static void APIENTRY test_bind(GLenum target, GLuint buffer) {}
static void* APIENTRY test_map(GLenum target, GLintptr offset, GLsizeiptr size, GLbitfield flags) {
	mapped_count++;
	return map_fails ? nullptr : readback_data;
}
static GLboolean APIENTRY test_unmap(GLenum target) { return !unmap_fails; }

static void* add_readback(void* context) {
	gl_context_state* state = gl_find_context(context);
	gl_readback* r = calloc(1, sizeof(gl_readback));
	r->id = ++readback_id;
	r->buffer = 7;
	r->fence = (GLsync)1;
	r->size = 16;
	r->context = context;
	r->next = state->readbacks;
	state->readbacks = r;
	return (void*)r->id;
}

typedef struct thread_context_test {
	void* context;
	HANDLE ready;
	HANDLE finish;
	int result;
	bool abandon;
} thread_context_test;

static DWORD WINAPI test_context_thread(void* argument) {
	thread_context_test* test = argument;
	if (gl_current || !limen_gl_activate_context(nullptr, test->context)) test->result = 1;
	else if (gl_capability(2) || gl_named_buffer_sub_data || HL_NAME(gl_is_context_lost)()) test->result = 2;

	SetEvent(test->ready);
	if (WaitForSingleObject(test->finish, 10000) != WAIT_OBJECT_0) test->result = 3;
	if (!test->abandon && (!limen_gl_activate_context(nullptr, nullptr) || gl_current)) test->result = 4;
	return 0;
}

static int test_context_switching(void) {
	mock_context modern = { "4.6", nullptr, 0, 0 };
	mock_context legacy = { "2.1", nullptr, 0, 1 };
	mock_context es = { "OpenGL ES 3.2", nullptr, 0, 1 };
	mock_context missing = { "4.6", "glDispatchCompute", 0, 1 };
	multi_context_mode = true;
	test_extensions = "";

	next_context = &modern;
	CHECK(limen_gl_new_context(nullptr) == &modern);
	CHECK(HL_NAME(gl_init)());
	CHECK(gl_capability(2) && gl_capability(5));
	CHECK(gl_current->reset_notifications);
	CHECK(gl_current->supports_readback && gl_current->version == 406 && !gl_current->is_es);
	CHECK(gl_named_buffer_sub_data && gl_label_proc && gl_max_label_length == 64);
	glVertexAttribDivisor = test_divisor;
	glDrawArraysInstanced = test_draw_arrays;
	glDrawElementsInstanced = test_draw_elements;
	int versions_before = version_queries;
	int extensions_before = extension_queries;
	int integers_before = integer_queries;
	int procs_before = proc_queries;

	for (int i = 0; i < 1000; i++) {
		HL_NAME(gl_vertex_attrib_divisor)(0, 1);
		HL_NAME(gl_draw_arrays_instanced)(GL_TRIANGLES, 0, 3, 1);
		HL_NAME(gl_draw_elements_instanced)(GL_TRIANGLES, 3, GL_UNSIGNED_SHORT, 0, 1);
		CHECK(gl_version_at_least(403, 0) && gl_capability(2));
	}
	CHECK(instanced_calls == 3000);
	CHECK(version_queries == versions_before && extension_queries == extensions_before);
	CHECK(integer_queries == integers_before && proc_queries == procs_before);
	glBindBuffer(GL_ARRAY_BUFFER, 1);
	CHECK(binds[0] == 1 && binds[1] == 0);

	next_context = &legacy;
	CHECK(limen_gl_new_context(nullptr) == &legacy);
	CHECK(HL_NAME(gl_init)());
	CHECK(!gl_capability(2) && !gl_capability(5));
	CHECK(!gl_current->supports_readback && gl_current->version == 201);
	CHECK(!gl_reset_status && !gl_named_buffer_sub_data && !gl_label_proc);
	CHECK(!gl_current->reset_notifications);
	glBindBuffer(GL_ARRAY_BUFFER, 1);
	CHECK(binds[0] == 1 && binds[1] == 1);
	versions_before = version_queries;
	extensions_before = extension_queries;
	CHECK(!HL_NAME(gl_start_buffer_readback)(&legacy, nullptr, 0, 16));
	CHECK(version_queries == versions_before && extension_queries == extensions_before);

	CHECK(limen_gl_activate_context(nullptr, &modern));
	int calls_before = activation_calls;
	for (int i = 0; i < 1000; i++) CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(activation_calls == calls_before);

	glDeleteBuffers = test_delete_buffers;
	glDeleteSync = test_delete_sync;
	add_readback(&modern);
	gl_current->readbacks->id = 0;
	int released_before = deleted_buffers;
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(!gl_current->readbacks && deleted_buffers == released_before + 1);
	CHECK(activation_calls == calls_before);

	void* window = &calls_before;
	CHECK(limen_gl_activate_context(window, &modern));
	CHECK(current_window == window && activation_calls == calls_before + 1);
	CHECK(limen_gl_activate_context(window, &modern));
	CHECK(activation_calls == calls_before + 1);

	activation_succeeds = false;
	CHECK(!limen_gl_activate_context(nullptr, &modern));
	CHECK(gl_current && current_window == window);
	activation_drops_current = true;
	CHECK(!limen_gl_activate_context(nullptr, &modern));
	CHECK(!gl_current);
	activation_succeeds = true;
	activation_drops_current = false;
	CHECK(limen_gl_activate_context(nullptr, &modern));

	current_context = &legacy;
	calls_before = activation_calls;
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(current_context == &modern && activation_calls == calls_before + 1);
	CHECK(gl_capability(2) && gl_named_buffer_sub_data);
	CHECK(HL_NAME(gl_try_named_buffer_sub_data)(nullptr, 0, (vbyte*)"x", 0, 1));
	CHECK(uploads[0] == 1 && uploads[1] == 0);
	modern.reset = 0x8253;
	CHECK(HL_NAME(gl_is_context_lost)());
	modern.reset = 0;
	CHECK(HL_NAME(gl_init)() && HL_NAME(gl_is_context_lost)());

	CHECK(limen_gl_activate_context(nullptr, &legacy));
	CHECK(!HL_NAME(gl_is_context_lost)());
	CHECK(!HL_NAME(gl_try_named_buffer_sub_data)(nullptr, 0, (vbyte*)"x", 0, 1));
	activation_succeeds = false;
	CHECK(!limen_gl_activate_context(nullptr, &modern));
	CHECK(gl_current->context == &legacy && !gl_named_buffer_sub_data);
	activation_drops_current = true;
	CHECK(!limen_gl_activate_context(nullptr, &modern));
	CHECK(!gl_current);
	activation_drops_current = false;
	activation_succeeds = true;
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(HL_NAME(gl_is_context_lost)());

	next_context = &es;
	CHECK(limen_gl_new_context(nullptr) == &es);
	CHECK(HL_NAME(gl_init)());
	CHECK(gl_capability(6) && !gl_capability(2) && !gl_named_buffer_sub_data);
	CHECK(gl_current->supports_readback && gl_current->version == 302 && gl_current->is_es);
	CHECK(!HL_NAME(gl_is_context_lost)());
	int resets_before = reset_queries;
	current_context = nullptr;
	CHECK(HL_NAME(gl_is_context_lost)() && reset_queries == resets_before);
	current_context = &es;
	CHECK(!HL_NAME(gl_is_context_lost)());
	error_result = 0x0507;
	CHECK(HL_NAME(gl_get_error)() == 0x0507 && HL_NAME(gl_is_context_lost)());
	error_result = GL_NO_ERROR;
	CHECK(limen_gl_delete_context(&modern));
	CHECK(gl_current->context == &es && HL_NAME(gl_is_context_lost)());

	next_context = &modern;
	CHECK(limen_gl_new_context(nullptr) == &modern);
	CHECK(!gl_current->initialized);
	CHECK(HL_NAME(gl_init)() && !HL_NAME(gl_is_context_lost)());
	CHECK(gl_named_buffer_sub_data && gl_capability(2));
	CHECK(gl_current->supports_readback && gl_current->version == 406 && !gl_current->is_es);
	CHECK(limen_gl_activate_context(nullptr, nullptr));
	CHECK(!gl_current && !HL_NAME(gl_init)());
	versions_before = version_queries;
	extensions_before = extension_queries;
	CHECK(!gl_version_at_least(201, 200) && !gl_capability(6) && !gl_extension("GL_KHR_robustness"));
	CHECK(HL_NAME(gl_is_context_lost)());
	CHECK(version_queries == versions_before && extension_queries == extensions_before);

	next_context = &missing;
	CHECK(limen_gl_new_context(nullptr) == &missing);
	CHECK(HL_NAME(gl_init)() && !gl_capability(2));
	CHECK(HL_NAME(gl_try_named_buffer_sub_data)(nullptr, 0, (vbyte*)"x", 0, 1));
	CHECK(uploads[0] == 1 && uploads[1] == 1);
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(gl_capability(2));

	mock_context no_mapping = { "4.6", "glMapBufferRange", 0, 1 };
	next_context = &no_mapping;
	CHECK(limen_gl_new_context(nullptr) == &no_mapping);
	CHECK(HL_NAME(gl_init)() && !gl_current->supports_readback);
	versions_before = version_queries;
	extensions_before = extension_queries;
	CHECK(!HL_NAME(gl_start_buffer_readback)(&no_mapping, nullptr, 0, 16));
	CHECK(version_queries == versions_before && extension_queries == extensions_before);
	CHECK(limen_gl_delete_context(&no_mapping));

	no_mapping.missing = nullptr;
	CHECK(limen_gl_new_context(nullptr) == &no_mapping);
	CHECK(HL_NAME(gl_init)() && gl_current->supports_readback);
	CHECK(limen_gl_delete_context(&no_mapping));
	CHECK(limen_gl_activate_context(nullptr, &modern));

	thread_context_test thread_test = {
		&legacy, CreateEventW(nullptr, TRUE, FALSE, nullptr), CreateEventW(nullptr, TRUE, FALSE, nullptr), 0
	};
	CHECK(thread_test.ready && thread_test.finish);
	HANDLE thread = CreateThread(nullptr, 0, test_context_thread, &thread_test, 0, nullptr);
	CHECK(thread);
	CHECK(WaitForSingleObject(thread_test.ready, 10000) == WAIT_OBJECT_0);
	CHECK(thread_test.result == 0);
	CHECK(gl_current->context == &modern && gl_capability(2) && gl_named_buffer_sub_data);
	CHECK(!limen_gl_activate_context(nullptr, &legacy));
	CHECK(!limen_gl_delete_context(&legacy));
	CHECK(gl_current->context == &modern);
	SetEvent(thread_test.finish);
	CHECK(WaitForSingleObject(thread, 10000) == WAIT_OBJECT_0 && thread_test.result == 0);
	CloseHandle(thread);
	CloseHandle(thread_test.ready);
	CloseHandle(thread_test.finish);
	CHECK(limen_gl_activate_context(nullptr, &legacy));
	CHECK(!gl_capability(2) && !gl_named_buffer_sub_data);
	CHECK(limen_gl_activate_context(nullptr, &modern));

	CHECK(limen_gl_activate_context(nullptr, &legacy));
	glDeleteBuffers = test_delete_buffers;
	glDeleteSync = test_delete_sync;
	CHECK(limen_gl_activate_context(nullptr, &modern));
	int deletions_before = deleted_buffers;
	void* pending = add_readback(&legacy);
	thread_test.result = 0;
	thread_test.abandon = true;
	thread_test.ready = CreateEventW(nullptr, TRUE, FALSE, nullptr);
	thread_test.finish = CreateEventW(nullptr, TRUE, FALSE, nullptr);
	CHECK(thread_test.ready && thread_test.finish);
	thread = CreateThread(nullptr, 0, test_context_thread, &thread_test, 0, nullptr);
	CHECK(thread && WaitForSingleObject(thread_test.ready, 10000) == WAIT_OBJECT_0);
	CHECK(thread_test.result == 0);
	HL_NAME(gl_cancel_buffer_readback)(pending);
	HL_NAME(gl_cancel_buffer_readback)(pending);
	CHECK(deleted_buffers == deletions_before);
	CHECK(gl_find_context(&legacy)->readbacks && gl_find_context(&legacy)->readbacks->id == 0);
	SetEvent(thread_test.finish);
	CHECK(WaitForSingleObject(thread, 10000) == WAIT_OBJECT_0 && thread_test.result == 0);
	CHECK(!gl_find_context(&legacy)->owner && !gl_find_context(&legacy)->readbacks);
	CHECK(deleted_buffers == deletions_before + 1);
	CloseHandle(thread);
	CloseHandle(thread_test.ready);
	CloseHandle(thread_test.finish);
	CHECK(limen_gl_activate_context(nullptr, &legacy));
	CHECK(limen_gl_activate_context(nullptr, &modern));

	pending = add_readback(&legacy);
	thread_test.result = 0;
	thread_test.ready = CreateEventW(nullptr, TRUE, FALSE, nullptr);
	thread_test.finish = CreateEventW(nullptr, TRUE, FALSE, nullptr);
	CHECK(thread_test.ready && thread_test.finish);
	thread = CreateThread(nullptr, 0, test_context_thread, &thread_test, 0, nullptr);
	CHECK(thread && WaitForSingleObject(thread_test.ready, 10000) == WAIT_OBJECT_0);
	SetEvent(thread_test.finish);
	CHECK(WaitForSingleObject(thread, 10000) == WAIT_OBJECT_0 && thread_test.result == 0);
	CHECK(!gl_find_context(&legacy)->owner && !gl_find_context(&legacy)->readbacks);
	CHECK(HL_NAME(gl_poll_buffer_readback)(pending, readback_data, 0) == -1);
	CloseHandle(thread);
	CloseHandle(thread_test.ready);
	CloseHandle(thread_test.finish);

	mock_context invalid = { "3.3", "glCreateShader", 0, 1 };
	next_context = &invalid;
	CHECK(limen_gl_new_context(nullptr) == &invalid);
	CHECK(!HL_NAME(gl_init)() && !gl_current->initialized && !gl_named_buffer_sub_data);
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(gl_capability(2) && gl_named_buffer_sub_data);
	CHECK(limen_gl_delete_context(&invalid));
	mock_context no_notifications = { "4.6", nullptr, 0x8253, 0, true };
	next_context = &no_notifications;
	CHECK(limen_gl_new_context(nullptr) == &no_notifications && HL_NAME(gl_init)());
	CHECK(gl_reset_status && !gl_current->reset_notifications);
	int reset_checks = reset_queries;
	CHECK(!HL_NAME(gl_is_context_lost)() && reset_queries == reset_checks);
	CHECK(limen_gl_delete_context(&no_notifications));
	CHECK(limen_gl_activate_context(nullptr, &modern));
	next_context = nullptr;
	CHECK(!limen_gl_new_context(nullptr) && !gl_current);
	CHECK(limen_gl_activate_context(nullptr, &modern));
	CHECK(gl_capability(2));
	CHECK(limen_gl_delete_context(&missing));
	CHECK(limen_gl_delete_context(&es));
	CHECK(limen_gl_delete_context(&legacy));
	CHECK(limen_gl_delete_context(&modern));
	CHECK(!gl_current);
	multi_context_mode = false;
	return 0;
}

static int test_readback_lifecycle(void) {
	void* owner = (void*)1;
	void* other = (void*)2;
	unsigned char destination[18] = { 0 };
	next_context = owner;
	CHECK(limen_gl_new_context(nullptr) == owner);
	gl_current->initialized = true;
	gl_context_state* owner_state = gl_current;
	next_context = other;
	CHECK(limen_gl_new_context(nullptr) == other);
	gl_current->initialized = true;
	glDeleteBuffers = test_delete_buffers;
	glDeleteSync = test_delete_sync;
	CHECK(limen_gl_activate_context(nullptr, owner));
	glDeleteBuffers = test_delete_buffers;
	glDeleteSync = test_delete_sync;
	glClientWaitSync = test_wait;
	glBindBuffer = test_bind;
	glMapBufferRange = test_map;
	glUnmapBuffer = test_unmap;
	gl_reset_status = nullptr;
	gl_context_lost = false;
	CHECK(limen_gl_activate_context(nullptr, owner));

	void* request = add_readback(owner);
	wait_result = GL_TIMEOUT_EXPIRED;
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 1) == 0);
	CHECK(current_readbacks && !deleted_buffers && !mapped_count);
	wait_result = GL_ALREADY_SIGNALED;
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 1) == 1);
	CHECK(destination[0] == 0 && destination[1] == 42 && destination[17] == 0);
	CHECK(!current_readbacks && deleted_buffers == 1 && deleted_fences == 1);
	HL_NAME(gl_cancel_buffer_readback)(request);
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
	CHECK(deleted_buffers == 1);
	void* replacement = add_readback(owner);
	CHECK(replacement != request);
	HL_NAME(gl_cancel_buffer_readback)(request);
	CHECK(current_readbacks && current_readbacks->id == (uintptr_t)replacement);
	HL_NAME(gl_cancel_buffer_readback)(replacement);
	CHECK(!current_readbacks && deleted_buffers == 2 && deleted_fences == 2);
	deleted_buffers = deleted_fences = 1;

	for (int failure = 0; failure < 3; failure++) {
		request = add_readback(owner);
		wait_result = failure == 0 ? GL_WAIT_FAILED : GL_CONDITION_SATISFIED;
		map_fails = failure == 1;
		unmap_fails = failure == 2;
		CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
		CHECK(!current_readbacks);
	}
	CHECK(deleted_buffers == 4 && deleted_fences == 4);
	map_fails = unmap_fails = false;

	request = add_readback(owner);
	CHECK(limen_gl_activate_context(nullptr, other));
	HL_NAME(gl_cancel_buffer_readback)(request);
	HL_NAME(gl_cancel_buffer_readback)(request);
	CHECK(owner_state->readbacks && owner_state->readbacks->id == 0 && deleted_buffers == 4);
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
	limen_gl_release_cancelled_readbacks(other);
	CHECK(owner_state->readbacks && deleted_buffers == 4);
	CHECK(limen_gl_activate_context(nullptr, owner));
	limen_gl_release_cancelled_readbacks(owner);
	CHECK(!current_readbacks && deleted_buffers == 5);

	request = add_readback(owner);
	CHECK(limen_gl_activate_context(nullptr, nullptr));
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
	CHECK(owner_state->readbacks && owner_state->readbacks->id == 0 && deleted_buffers == 5);
	void* second = add_readback(other);
	limen_gl_delete_context(owner);
	limen_gl_delete_context(owner);
	CHECK(gl_find_context(other)->readbacks && !gl_find_context(other)->readbacks->next);
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
	CHECK(limen_gl_activate_context(nullptr, other));
	HL_NAME(gl_cancel_buffer_readback)(second);
	CHECK(!current_readbacks && deleted_buffers == 6 && deleted_fences == 6);

	next_context = owner;
	CHECK(limen_gl_new_context(nullptr) == owner);
	gl_current->initialized = true;
	request = add_readback(owner);
	gl_context_lost = true;
	HL_NAME(gl_cancel_buffer_readback)(request);
	limen_gl_delete_context(owner);
	CHECK(!gl_current && deleted_buffers == 6);
	CHECK(HL_NAME(gl_poll_buffer_readback)(request, destination, 0) == -1);
	return 0;
}

int main(void) {
	next_context = (void*)3;
	CHECK(limen_gl_new_context(nullptr) == next_context);
	CHECK(GLLoadAPI() == 0);
	CHECK(!gl_capability(0));
	CHECK(!gl_capability(2));
	CHECK(!gl_capability(3));
	CHECK(!gl_capability(4));
	CHECK(!gl_capability(5));

#define GL_IMPORT(fun, type) missing_proc = #fun; CHECK(GLLoadAPI() != 0)
#define GL_IMPORT_OPTIONAL(fun, type)
#include "../backend/src/graphics/opengl/GLImports.h"
#undef GL_IMPORT_OPTIONAL
#undef GL_IMPORT
	missing_proc = "glDispatchCompute";
	test_version = "4.6";
	CHECK(GLLoadAPI() == 0);
	CHECK(!gl_capability(2));
	CHECK(gl_capability(0));
	CHECK(gl_capability(1));
	CHECK(gl_capability(3));
	CHECK(gl_capability(4));
	CHECK(gl_capability(5));
	glDebugMessageCallback = nullptr;
	CHECK(!gl_capability(5));
	CHECK(!HL_NAME(gl_set_debug)(true));
	glGetQueryObjectui64v = nullptr;
	CHECK(!gl_capability(4));

	missing_proc = nullptr;
	CHECK(GLLoadAPI() == 0);
	test_version = "OpenGL ES 3.2";
	CHECK(!gl_capability(0));
	CHECK(!gl_capability(2));
	CHECK(!gl_capability(3));
	CHECK(!gl_capability(4));
	CHECK(!gl_capability(5));
	CHECK(gl_capability(6));
	test_extensions = "GL_EXT_depth_clamp";
	CHECK(gl_capability(3));
	CHECK(!gl_extension(""));
	CHECK(!gl_extension("GL_EXT_depth"));

	test_version = "2.1";
	test_extensions = "GL_ARB_depth_clamp_suffix GL_ARB_timer_query";
	CHECK(!gl_capability(3));
	CHECK(gl_capability(4));
	test_version = "3.3";
	test_extensions = "";
	CHECK(!gl_extension("GL_ARB_timer_query"));
	test_version = "2.1";
	test_extensions = "";
	gl_load_reset_status();
	CHECK(!gl_reset_status);
	CHECK(!HL_NAME(gl_is_context_lost)());
	for (int i = 0; i < 3; i++) {
		test_extensions = i == 0 ? "GL_ARB_robustness" : i == 1 ? "GL_KHR_robustness" : "GL_EXT_robustness";
		gl_load_reset_status();
		CHECK(gl_reset_status != nullptr);
	}
	missing_reset_core = true;
	test_version = "4.6";
	test_extensions = "";
	gl_load_reset_status();
	CHECK(!gl_reset_status);
	for (int i = 0; i < 3; i++) {
		test_extensions = i == 0 ? "GL_ARB_robustness" : i == 1 ? "GL_KHR_robustness" : "GL_EXT_robustness";
		gl_load_reset_status();
		CHECK(gl_reset_status == test_reset);
	}
	missing_reset_core = false;
	test_extensions = "";
	test_version = "OpenGL ES 3.2";
	gl_load_reset_status();
	CHECK(gl_reset_status != nullptr);
	gl_reset_status = test_reset;
	CHECK(!HL_NAME(gl_is_context_lost)());
	reset_result = 0x8253;
	CHECK(HL_NAME(gl_is_context_lost)());
	reset_result = 0;
	CHECK(HL_NAME(gl_is_context_lost)());
	glCheckFramebufferStatus = test_framebuffer;
	reset_result = GL_FRAMEBUFFER_COMPLETE;
	CHECK(HL_NAME(gl_check_framebuffer_status)(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
	reset_result = GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT;
	CHECK(HL_NAME(gl_check_framebuffer_status)(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT);
	glBindFramebuffer = test_bind_framebuffer;
	glDeleteFramebuffers = test_delete_framebuffer;
	gl_current->framebuffer_binding_known = false;
	vdynamic framebuffer = {0};
	framebuffer.v.i = 7;
	HL_NAME(gl_bind_framebuffer)(GL_FRAMEBUFFER, &framebuffer);
	HL_NAME(gl_bind_framebuffer)(GL_FRAMEBUFFER, &framebuffer);
	CHECK(framebuffer_binds == 1);
	HL_NAME(gl_bind_framebuffer)(GL_READ_FRAMEBUFFER, nullptr);
	HL_NAME(gl_bind_framebuffer)(GL_DRAW_FRAMEBUFFER, &framebuffer);
	CHECK(framebuffer_binds == 2);
	HL_NAME(gl_bind_framebuffer)(GL_FRAMEBUFFER, &framebuffer);
	CHECK(framebuffer_binds == 3);
	HL_NAME(gl_delete_framebuffer)(&framebuffer);
	HL_NAME(gl_bind_framebuffer)(GL_FRAMEBUFFER, &framebuffer);
	CHECK(framebuffer_binds == 4);
	CHECK(limen_gl_activate_context(current_window, current_context));
	HL_NAME(gl_bind_framebuffer)(GL_FRAMEBUFFER, &framebuffer);
	CHECK(framebuffer_binds == 5);
	CHECK(test_readback_lifecycle() == 0);
	CHECK(test_context_switching() == 0);
	while (gl_contexts) CHECK(limen_gl_delete_context(gl_contexts->context));
	puts("OpenGL capability, failure, and readback lifecycle checks passed");
	return 0;
}
