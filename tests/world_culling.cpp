#include "world_culling.h"
#include "jobs.h"

#include <algorithm>
#include <cmath>
#include <iostream>
#include <limits>
#include <stdexcept>
#include <vector>

int main() {
	try {
		limen::jobs::Scheduler scheduler(3);
		for (size_t count : {size_t(0), size_t(1), size_t(7), size_t(8), size_t(9), size_t(1033)}) {
			for (size_t offset : {size_t(0), size_t(1)}) {
				const size_t blocks = (count + 7) / 8;
				std::vector<double> storage(blocks * 48 + 1);
				// keep double alignment while also exercising unaligned SIMD loads
				auto* bounds = storage.data() + offset;
				std::vector<uint8_t> expected(count), output(count + 16, 0xcd);

				for (size_t i = 0; i < count; ++i) {
					auto* slot = bounds + (i / 8) * 48 + i % 8;
					slot[0] = static_cast<double>(i % 53) - 15.;
					slot[8] = static_cast<double>(i % 31) - 6.;
					slot[16] = static_cast<double>(i % 23) - 4.;
					slot[24] = slot[32] = slot[40] = 0.5;
					if (i % 17 == 0) slot[0] = std::numeric_limits<double>::quiet_NaN();
					else if (i % 19 == 0) slot[0] = std::numeric_limits<double>::infinity();
					else if (i % 23 == 0) slot[0] = -std::numeric_limits<double>::infinity();
					else if (i % 29 == 0) slot[0] = std::nextafter(-10.5, -11.);
					else if (i % 31 == 0) slot[0] = std::nextafter(-10.5, -10.);
					else if (i % 37 == 0) slot[0] = -10.5;
				}

				for (int planeCount : {4, 6}) {
					limen::WorldCulling input{{{1,0,0,-5}, {-1,0,0,-5}, {0,1,0,-5},
						{0,-1,0,-5}, {0,0,1,-5}, {0,0,-1,-5}}, bounds, output.data(), count, planeCount};
					for (size_t i = 0; i < count; ++i) {
						const auto* box = bounds + (i / 8) * 48 + i % 8;
						bool visible = true;
						for (int j = 0; j < planeCount; ++j) {
							const auto& p = input.planes[j];
							const double center = p.x*box[0] + p.y*box[8] + p.z*box[16];
							const double radius = std::abs(p.x)*box[24] + std::abs(p.y)*box[32] + std::abs(p.z)*box[40];
							if (center + radius - p.distance*2 < 0) visible = false;
						}
						expected[i] = visible;
					}
					for (unsigned implementation : {0u, 1u, 2u, 4u, 8u, 16u}) {
						const auto kernel = limen::world_cull_kernel(implementation);
						if (!kernel) {
							if (implementation == 0 || (limen::world_cull_kernels() & implementation))
								throw std::runtime_error("advertised kernel is unavailable");
							continue;
						}
						for (bool parallel : {false, true}) {
							std::fill(output.begin(), output.end(), 0xcd);
							if (parallel && blocks > 0) {
								struct Work { limen::WorldCulling input; limen::WorldCullKernel kernel; } work{input, kernel};
								limen::jobs::Batch batch;
								scheduler.submit(batch, blocks, 1, &work,
									[](limen::jobs::Context&, void* data, size_t begin, size_t end) {
										const auto& work = *static_cast<const Work*>(data);
										work.kernel(work.input, begin, end);
									});
								if (!scheduler.wait(batch)) throw std::runtime_error("scheduler failed");
							} else {
								kernel(input, 0, blocks);
							}
							for (size_t i = 0; i < output.size(); ++i)
								if (output[i] != (i < count ? expected[i] : 0xcd))
									throw std::runtime_error("visibility or output guard mismatch");
						}
					}
				}
			}
		}
		std::cout << "world culling scalar, SIMD, tails and scheduler checks passed\n";
	} catch (const std::exception& error) {
		std::cerr << error.what() << '\n';
		return 1;
	}
}
