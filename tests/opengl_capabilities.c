#include "hlsystem.h"
#include <GL/gl.h>
#include "native_window.h"
#include <string.h>
#include <stdio.h>

static const char* test_version = "2.1";
static const char* test_extensions = "";
static const char* missing_proc;

static const GLubyte* APIENTRY test_get_string(GLenum name) {
	return (const GLubyte*)(name == GL_VERSION ? test_version : test_extensions);
}

static void APIENTRY test_get_integer(GLenum name, GLint* value) {
	*value = *test_extensions ? 1 : 0;
}

static const GLubyte* APIENTRY test_get_string_i(GLenum name, GLuint index) {
	return (const GLubyte*)test_extensions;
}

static void APIENTRY test_noop(void) {}

static void* test_resolve(const char* name) {
	if (missing_proc && strncmp(name, missing_proc, strlen(missing_proc)) == 0) return nullptr;
	if (strcmp(name, "glGetStringi") == 0) return (void*)test_get_string_i;
	return (void*)test_noop;
}

#define glGetString test_get_string
#define glGetIntegerv test_get_integer
#define limen_gl_get_proc_address test_resolve
#undef HL_NAME
#include "../backend/src/graphics/opengl/gl.c"

#define CHECK(condition) do { if (!(condition)) { fprintf(stderr, "Line %d: %s\n", __LINE__, #condition); return 1; } } while (0)

int main(void) {
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
	puts("OpenGL capability checks passed");
	return 0;
}
