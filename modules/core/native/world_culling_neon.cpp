#include "world_culling_kernel.h"
#if defined(_MSC_VER)
#include <arm64_neon.h>
#else
#include <arm_neon.h>
#endif

namespace limen {
namespace {

struct Vector {
	static constexpr size_t width = 2;
	float64x2_t value;
	static Vector load(const double* source) { return {vld1q_f64(source)}; }
	static Vector splat(double value) { return {vdupq_n_f64(value)}; }
	unsigned negative() const {
		const auto mask = vcltq_f64(value, vdupq_n_f64(0.));
		return static_cast<unsigned>((vgetq_lane_u64(mask, 0) >> 63) | ((vgetq_lane_u64(mask, 1) >> 63) << 1));
	}
	friend Vector operator+(Vector a, Vector b) { return {vaddq_f64(a.value, b.value)}; }
	friend Vector operator-(Vector a, Vector b) { return {vsubq_f64(a.value, b.value)}; }
	friend Vector operator*(Vector a, Vector b) { return {vmulq_f64(a.value, b.value)}; }
};

}

void cull_world_neon(const WorldCulling& input, size_t begin, size_t end) {
	cull_world_blocks<Vector>(input, begin, end);
}

}
