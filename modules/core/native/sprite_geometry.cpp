#include "jobs_bridge.h"
#include "limen_native.h"

#include <cmath>
#include <cstring>

namespace {

using limen::jobs::Context;

struct Sprite {
	double x, y, dx, dy, width, height, scaleX, scaleY, rotation;
	float uv[4][2];
	float color[4];
	std::byte padding[8];
};

struct Vertex {
	float x, y, u, v;
	float color[4];
};

struct Quad {
	Vertex vertices[4];
};

static_assert(sizeof(Sprite) == 128 && sizeof(Quad) == sizeof(Sprite));

void build_quads(std::byte* geometry, size_t begin, size_t end) {
	for (size_t i = begin; i < end; ++i) {
		auto* slot = geometry + i * sizeof(Sprite);
		Sprite sprite;
		std::memcpy(&sprite, slot, sizeof(Sprite));

		const double c = std::cos(sprite.rotation), s = std::sin(sprite.rotation);
		const double x[]{sprite.dx * sprite.scaleX, (sprite.dx + sprite.width) * sprite.scaleX};
		const double y[]{sprite.dy * sprite.scaleY, (sprite.dy + sprite.height) * sprite.scaleY};

		Quad result;
		for (size_t j = 0; j < 4; ++j) {
			const double px = x[j & 1], py = y[j >> 1];
			auto& vertex = result.vertices[j];
			vertex.x = static_cast<float>(px * c - py * s + sprite.x);
			vertex.y = static_cast<float>(py * c + px * s + sprite.y);
			vertex.u = sprite.uv[j][0];
			vertex.v = sprite.uv[j][1];
			std::memcpy(vertex.color, sprite.color, sizeof(vertex.color));
		}
		std::memcpy(slot, &result, sizeof(result));
	}
}

}

HL_PRIM void HL_NAME(build_sprite_geometry)(vbyte* buffer, int size, int count, int workers) {
	if (!buffer || count < 1 || size < 0 || static_cast<size_t>(count) > static_cast<size_t>(size) / sizeof(Sprite))
		hl_error("Invalid sprite geometry range");

	auto* geometry = reinterpret_cast<std::byte*>(buffer);
	if (workers > 0 && count >= 1024) {
		const bool ran = limen_run_jobs(static_cast<unsigned>(workers), count, 512, geometry,
			[](Context&, void* data, size_t begin, size_t end) {
				build_quads(static_cast<std::byte*>(data), begin, end);
			}, nullptr, buffer);
		if (ran)
			return;
	}

	build_quads(geometry, 0, static_cast<size_t>(count));
}
DEFINE_PRIM(_VOID, build_sprite_geometry, _BYTES _I32 _I32 _I32);
