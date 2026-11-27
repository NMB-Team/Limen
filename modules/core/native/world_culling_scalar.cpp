#include "world_culling_kernel.h"

namespace limen {
namespace {

struct Scalar {
	static constexpr size_t width = 1;
	double value;
	static Scalar load(const double* source) { return {*source}; }
	static Scalar splat(double value) { return {value}; }
	unsigned negative() const { return value < 0 ? 1 : 0; }
	friend Scalar operator+(Scalar a, Scalar b) { return {a.value + b.value}; }
	friend Scalar operator-(Scalar a, Scalar b) { return {a.value - b.value}; }
	friend Scalar operator*(Scalar a, Scalar b) { return {a.value * b.value}; }
};

}

void cull_world_scalar(const WorldCulling& input, size_t begin, size_t end) {
	cull_world_blocks<Scalar>(input, begin, end);
}

}
