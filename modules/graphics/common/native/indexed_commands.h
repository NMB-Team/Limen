#ifndef LIMEN_INDEXED_COMMANDS_H
#define LIMEN_INDEXED_COMMANDS_H

#include <stdint.h>

enum {
	LIMEN_INDEXED_COMMANDS_V1 = 1,
	LIMEN_INDEXED_COMMANDS_HEADER = 1,
	LIMEN_INDEXED_COMMANDS_STRIDE = 5,
	LIMEN_INDEXED_RANGES_V2 = 2,
	LIMEN_INDEXED_RANGES_STRIDE = 2
};

static const int32_t* limen_validate_indexed_commands(varray* stream, int used) {
	if (!stream || stream->at->kind != HI32 || used <= LIMEN_INDEXED_COMMANDS_HEADER || used > stream->size ||
		(used - LIMEN_INDEXED_COMMANDS_HEADER) % LIMEN_INDEXED_COMMANDS_STRIDE != 0)
		return NULL;

	const int32_t* words = hl_aptr(stream, int32_t);
	if (words[0] != LIMEN_INDEXED_COMMANDS_V1)
		return NULL;

	for (int i = LIMEN_INDEXED_COMMANDS_HEADER; i < used; i += LIMEN_INDEXED_COMMANDS_STRIDE)
		if (words[i] < 0 || words[i + 1] < 0 || words[i + 2] < 0 || words[i + 4] < 0)
			return NULL;

	return words + LIMEN_INDEXED_COMMANDS_HEADER;
}

static const int32_t* limen_validate_indexed_ranges(varray* stream, int count, int index_limit) {
	if (!stream || stream->at->kind != HI32 || stream->size < LIMEN_INDEXED_COMMANDS_HEADER ||
		count < 2 || count > (stream->size - LIMEN_INDEXED_COMMANDS_HEADER) / LIMEN_INDEXED_RANGES_STRIDE || index_limit < 0)
		return NULL;

	const int32_t* ranges = hl_aptr(stream, int32_t);
	if (ranges[0] != LIMEN_INDEXED_RANGES_V2)
		return NULL;
	ranges += LIMEN_INDEXED_COMMANDS_HEADER;

	for (int i = 0; i < count; i++) {
		const int32_t* range = ranges + i * LIMEN_INDEXED_RANGES_STRIDE;
		if (range[0] < 0 || range[0] > index_limit || range[1] <= 0 || range[1] > index_limit - range[0])
			return NULL;
	}

	return ranges;
}

#endif
