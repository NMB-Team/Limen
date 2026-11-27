#pragma once

#include "world_culling.h"
#include <cmath>

namespace limen {

template<typename V>
void cull_world_blocks(const WorldCulling& input, size_t begin, size_t end) {
	for (size_t block = begin; block < end; ++block) {
		for (size_t lane = 0; lane < 8; lane += V::width) {
			const size_t first = block * 8 + lane;
			if (first >= input.count)
				break;
			if constexpr (V::width > 1) {
				if (first + V::width > input.count) {
					cull_world_scalar(input, block, block + 1);
					break;
				}
			}

			const auto* bounds = input.bounds + block * 48 + lane;
			const V x = V::load(bounds), y = V::load(bounds + 8), z = V::load(bounds + 16);
			const V ex = V::load(bounds + 24), ey = V::load(bounds + 32), ez = V::load(bounds + 40);
			unsigned visible = (1u << V::width) - 1;
			for (int j = 0; j < input.planeCount && visible; ++j) {
				const auto& p = input.planes[j];
				const V center = V::splat(p.x)*x + V::splat(p.y)*y + V::splat(p.z)*z;
				const V radius = V::splat(std::abs(p.x))*ex + V::splat(std::abs(p.y))*ey + V::splat(std::abs(p.z))*ez;
				visible &= ~(center + radius - V::splat(p.distance * 2)).negative();
			}
			for (size_t k = 0; k < V::width && first + k < input.count; ++k)
				input.visible[first + k] = (visible >> k) & 1;
		}
	}
}

}
