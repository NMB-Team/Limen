#include "world_culling_kernel.h"
#include <immintrin.h>

namespace limen {
namespace {

struct Vector {
	static constexpr size_t width = 8;
	__m512d value;
	static Vector load(const double* source) { return {_mm512_loadu_pd(source)}; }
	static Vector splat(double value) { return {_mm512_set1_pd(value)}; }
	unsigned negative() const { return _mm512_cmp_pd_mask(value, _mm512_setzero_pd(), _CMP_LT_OQ); }
	friend Vector operator+(Vector a, Vector b) { return {_mm512_add_pd(a.value, b.value)}; }
	friend Vector operator-(Vector a, Vector b) { return {_mm512_sub_pd(a.value, b.value)}; }
	friend Vector operator*(Vector a, Vector b) { return {_mm512_mul_pd(a.value, b.value)}; }
};

}

void cull_world_avx512(const WorldCulling& input, size_t begin, size_t end) {
	cull_world_blocks<Vector>(input, begin, end);
}

}
