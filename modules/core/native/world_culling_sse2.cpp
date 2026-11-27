#include "world_culling_kernel.h"
#include <emmintrin.h>

namespace limen {
namespace {

struct Vector {
	static constexpr size_t width = 2;
	__m128d value;
	static Vector load(const double* source) { return {_mm_loadu_pd(source)}; }
	static Vector splat(double value) { return {_mm_set1_pd(value)}; }
	unsigned negative() const { return _mm_movemask_pd(_mm_cmplt_pd(value, _mm_setzero_pd())); }
	friend Vector operator+(Vector a, Vector b) { return {_mm_add_pd(a.value, b.value)}; }
	friend Vector operator-(Vector a, Vector b) { return {_mm_sub_pd(a.value, b.value)}; }
	friend Vector operator*(Vector a, Vector b) { return {_mm_mul_pd(a.value, b.value)}; }
};

}

void cull_world_sse2(const WorldCulling& input, size_t begin, size_t end) {
	cull_world_blocks<Vector>(input, begin, end);
}

}
