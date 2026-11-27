#include "jobs_bridge.h"
#include "limen_native.h"
#include "world_culling.h"

#include <cmath>
#include <cstring>

namespace {

struct Plane {
	double x, y, z, distance;
};

struct Box {
	double center[3], extent[3];
};

struct Culling {
	Plane planes[6];
	int planeCount;
	const vbyte* boxes;
	vbyte* visible;
};

}

HL_PRIM bool HL_NAME(cull_world_boxes)(vbyte* bytes, int length, int count, bool checkNearFar, int workers) {
	constexpr size_t header = sizeof(Culling::planes);
	constexpr size_t stride = sizeof(Box) + 1;
	static_assert(header == 192 && stride == 49);
	if (workers <= 0 || !bytes || count < 2048 || length < static_cast<int>(header) ||
		static_cast<size_t>(count) > (length - header) / stride)
		return false;

	auto* boxes = bytes + header;
	Culling input{{}, checkNearFar ? 6 : 4, boxes, boxes + static_cast<size_t>(count) * sizeof(Box)};
	std::memcpy(input.planes, bytes, header);
	return limen_run_jobs(static_cast<unsigned>(workers), count, 512, &input,
		[](limen::jobs::Context&, void* data, size_t begin, size_t end) {
			const auto& input = *static_cast<const Culling*>(data);
			for (size_t i = begin; i < end; ++i) {
				Box box;
				std::memcpy(&box, input.boxes + i * sizeof(Box), sizeof(Box));
				bool visible = true;
				for (int j = 0; j < input.planeCount; ++j) {
					const auto& p = input.planes[j];
					const double center = p.x * box.center[0] + p.y * box.center[1] + p.z * box.center[2];
					const double radius = std::abs(p.x) * box.extent[0] + std::abs(p.y) * box.extent[1] +
						std::abs(p.z) * box.extent[2];
					if (center + radius - p.distance * 2 < 0) {
						visible = false;
						break;
					}
				}
				input.visible[i] = visible;
			}
		}, nullptr, bytes);
}
DEFINE_PRIM(_BOOL, cull_world_boxes, _BYTES _I32 _I32 _BOOL _I32);

HL_PRIM int HL_NAME(world_cull_kernels)() {
	return static_cast<int>(limen::world_cull_kernels());
}
DEFINE_PRIM(_I32, world_cull_kernels, _NO_ARG);

HL_PRIM bool HL_NAME(cull_world_boxes_soa)(vbyte* bytes, int length, int count, bool checkNearFar,
	int workers, int implementation) {
	constexpr size_t header = sizeof(limen::WorldCulling::planes);
	constexpr size_t blockBytes = 6 * 8 * sizeof(double);
	static_assert(header == 192);
	const auto kernel = limen::world_cull_kernel(implementation);
	if (!bytes || length < static_cast<int>(header) || count < 0 || workers < 0 || workers > 63 || !kernel ||
		reinterpret_cast<uintptr_t>(bytes) % alignof(double))
		return false;

	const size_t blocks = (static_cast<size_t>(count) + 7) / 8;
	const size_t available = static_cast<size_t>(length) - header;
	if (blocks > available / blockBytes || static_cast<size_t>(count) > available - blocks * blockBytes)
		return false;

	limen::WorldCulling input{{}, reinterpret_cast<const double*>(bytes + header),
		bytes + header + blocks * blockBytes, static_cast<size_t>(count), checkNearFar ? 6 : 4};
	std::memcpy(input.planes, bytes, header);
	if (workers > 0 && count >= 2048) {
		struct Work {
			limen::WorldCulling input;
			limen::WorldCullKernel kernel;
		} work{input, kernel};
		if (limen_run_jobs(workers, blocks, 64, &work,
			[](limen::jobs::Context&, void* data, size_t begin, size_t end) {
				const auto& work = *static_cast<const Work*>(data);
				work.kernel(work.input, begin, end);
			}, nullptr, bytes))
			return true;
	}
	kernel(input, 0, blocks);
	return true;
}
DEFINE_PRIM(_BOOL, cull_world_boxes_soa, _BYTES _I32 _I32 _BOOL _I32 _I32);
