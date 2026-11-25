#include <stdio.h>
#include <hl.h>
#include "../modules/graphics/common/native/indexed_commands.h"

int main(void) {
	hl_type type = {0};
	struct {
		varray array;
		int32_t words[11];
	} input = {0};

	type.kind = HI32;
	input.array.at = &type;
	input.array.size = 11;
	input.words[0] = LIMEN_INDEXED_COMMANDS_V1;
	input.words[1] = 3;
	input.words[4] = -1;
	input.words[6] = 6;

	if (limen_validate_indexed_commands(&input.array, 11) != input.words + 1 ||
		limen_validate_indexed_commands(&input.array, 6) != input.words + 1 ||
		limen_validate_indexed_commands(&input.array, 16) ||
		limen_validate_indexed_commands(&input.array, 10) ||
		limen_validate_indexed_commands(&input.array, 1) ||
		limen_validate_indexed_commands(&input.array, -1)) {
		fputs("indexed command bounds validation failed\n", stderr);
		return 1;
	}

	input.words[0]++;
	if (limen_validate_indexed_commands(&input.array, 11)) {
		fputs("unknown indexed command version accepted\n", stderr);
		return 1;
	}

	input.words[0] = LIMEN_INDEXED_COMMANDS_V1;
	input.words[8] = -1;
	if (limen_validate_indexed_commands(&input.array, 11)) {
		fputs("invalid unsigned field in later draw accepted\n", stderr);
		return 1;
	}

	input.array.size = 5;
	input.words[0] = LIMEN_INDEXED_RANGES_V2;
	input.words[1] = 0;
	input.words[2] = 3;
	input.words[3] = 3;
	input.words[4] = 3;
	if (limen_validate_indexed_ranges(&input.array, 2, 6) != input.words + 1 ||
		limen_validate_indexed_ranges(&input.array, 2, 5) ||
		limen_validate_indexed_ranges(&input.array, 3, 6) ||
		limen_validate_indexed_ranges(&input.array, 1, 6)) {
		fputs("indexed range bounds validation failed\n", stderr);
		return 1;
	}

	input.words[3] = INT32_MAX;
	if (limen_validate_indexed_ranges(&input.array, 2, INT32_MAX)) {
		fputs("overflowing index range accepted\n", stderr);
		return 1;
	}

	return 0;
}
