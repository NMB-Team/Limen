#pragma once

#include <cstddef>
#include <cstdint>

namespace limen {

struct CullingPlane {
	double x, y, z, distance;
};

struct WorldCulling {
	CullingPlane planes[6];
	// eight-wide streams contain center sums and full extents in double precision
	const double* bounds;
	uint8_t* visible;
	size_t count;
	int planeCount;
};

using WorldCullKernel = void (*)(const WorldCulling&, size_t, size_t);

unsigned world_cull_kernels();
WorldCullKernel world_cull_kernel(unsigned implementation);
void cull_world_scalar(const WorldCulling&, size_t, size_t);

#if defined(LIMEN_CULL_X86)
void cull_world_sse2(const WorldCulling&, size_t, size_t);
void cull_world_avx2(const WorldCulling&, size_t, size_t);
void cull_world_avx512(const WorldCulling&, size_t, size_t);
#elif defined(LIMEN_CULL_NEON)
void cull_world_neon(const WorldCulling&, size_t, size_t);
#endif

}
