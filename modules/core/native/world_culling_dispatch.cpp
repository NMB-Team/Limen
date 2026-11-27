#include "world_culling.h"

#if defined(LIMEN_CULL_X86)
#if defined(_MSC_VER)
#include <intrin.h>
#else
#include <cpuid.h>
#endif
#endif

namespace limen {
namespace {

unsigned detect_kernels() {
	unsigned result = 1;
	#if defined(LIMEN_CULL_X86)
	int info[4]{};
	auto cpuid = [&](unsigned leaf, unsigned subleaf) {
		#if defined(_MSC_VER)
		__cpuidex(info, leaf, subleaf);
		#else
		unsigned a, b, c, d;
		__cpuid_count(leaf, subleaf, a, b, c, d);
		info[0] = a;
		info[1] = b;
		info[2] = c;
		info[3] = d;
		#endif
	};
	cpuid(0, 0);
	const unsigned maximum = info[0];
	if (maximum < 1)
		return result;

	cpuid(1, 0);
	if (info[3] & (1 << 26))
		result |= 2;
	if ((info[2] & ((1 << 27) | (1 << 28))) != ((1 << 27) | (1 << 28)))
		return result;

	#if defined(_MSC_VER)
	const auto state = _xgetbv(0);
	#else
	unsigned low, high;
	__asm__ volatile("xgetbv" : "=a"(low), "=d"(high) : "c"(0));
	const uint64_t state = (static_cast<uint64_t>(high) << 32) | low;
	#endif
	if ((state & 6) != 6 || maximum < 7)
		return result;

	cpuid(7, 0);
	if (info[1] & (1 << 5))
		result |= 4;
	// the MSVC AVX512 target can also emit DQ, CD, BW and VL instructions
	if ((state & 0xe6) == 0xe6 && (static_cast<unsigned>(info[1]) & 0xd0030020u) == 0xd0030020u)
		result |= 8;
	#elif defined(LIMEN_CULL_NEON)
	result |= 16;
	#endif
	return result;
}

}

unsigned world_cull_kernels() {
	static const unsigned supported = detect_kernels();
	return supported;
}

WorldCullKernel world_cull_kernel(unsigned implementation) {
	const unsigned supported = world_cull_kernels();
	if (implementation == 0) {
		#if defined(LIMEN_CULL_X86)
		if (supported & 4) return cull_world_avx2;
		if (supported & 2) return cull_world_sse2;
		#endif
		return cull_world_scalar;
	}
	if (!(supported & implementation))
		return nullptr;

	switch (implementation) {
	case 1: return cull_world_scalar;
	#if defined(LIMEN_CULL_X86)
	case 2: return cull_world_sse2;
	case 4: return cull_world_avx2;
	case 8: return cull_world_avx512;
	#elif defined(LIMEN_CULL_NEON)
	case 16: return cull_world_neon;
	#endif
	default: return nullptr;
	}
}

}
