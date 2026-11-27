#include "world_culling_kernel.h"
#include <immintrin.h>

namespace limen {
namespace {

struct Vector {
	static constexpr size_t width = 4;
	__m256d value;
	static Vector load(const double* source) { return {_mm256_loadu_pd(source)}; }
	static Vector splat(double value) { return {_mm256_set1_pd(value)}; }
	unsigned negative() const { return _mm256_movemask_pd(_mm256_cmp_pd(value, _mm256_setzero_pd(), _CMP_LT_OQ)); }
	friend Vector operator+(Vector a, Vector b) { return {_mm256_add_pd(a.value, b.value)}; }
	friend Vector operator-(Vector a, Vector b) { return {_mm256_sub_pd(a.value, b.value)}; }
	friend Vector operator*(Vector a, Vector b) { return {_mm256_mul_pd(a.value, b.value)}; }
};

}

void cull_world_avx2(const WorldCulling& input, size_t begin, size_t end) {
	cull_world_blocks<Vector>(input, begin, end);
}

}
