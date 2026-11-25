#include "jobs_bridge.h"
#include "limen_native.h"
#include "module_loader.h"

#include <cstring>

HL_PRIM bool HL_NAME(decode_dxt_jobs)(vbyte* input, int length, int offset, vbyte* output, int outputLength,
	int width, int height, int format, int workers) {
	if (workers <= 0 || !limen_can_run_jobs() || !input || !output || input == output ||
		length <= 0 || offset < 0 || offset >= length || outputLength <= 0 ||
		width <= 0 || height < 16 || ((width | height) & 3) != 0 || format < 1 || format > 3)
		return false;

	const size_t blockBytes = format == 1 ? 8 : 16;
	const size_t inputRow = static_cast<size_t>(width / 4) * blockBytes;
	const size_t rows = static_cast<size_t>(height / 4);
	const uint64_t pixels = static_cast<uint64_t>(width) * height;
	if (rows > static_cast<size_t>(length - offset) / inputRow ||
		pixels > static_cast<size_t>(outputLength) / sizeof(int))
		return false;

	const char* signature = nullptr;
	void* function = nullptr;
	#if IS_64
	function = limen_module_resolve("fmt64.hdll", "dxt_decode", &signature);
	#endif
	if (!signature)
		function = limen_module_resolve("fmt.hdll", "dxt_decode", &signature);
	if (!signature || std::strcmp(signature, _FUN(_BOOL, _BYTES _BYTES _I32 _I32 _I32)) != 0)
		return false;

	using Decoder = bool (*)(vbyte*, int*, int, int, int);
	struct Decode {
		Decoder decoder;
		vbyte* input;
		int* output;
		size_t inputRow;
		int width;
		int format;
		std::atomic_bool failed = false;
	} payload{reinterpret_cast<Decoder>(function), input + offset, reinterpret_cast<int*>(output), inputRow, width, format};

	// each DXT block row reads isolated compressed blocks and writes four output rows
	const bool ran = limen_run_jobs(static_cast<unsigned>(workers), rows, 4, &payload,
		[](limen::jobs::Context&, void* data, size_t begin, size_t end) {
			auto& job = *static_cast<Decode*>(data);
			if (!job.decoder(job.input + begin * job.inputRow, job.output + begin * job.width * 4,
				job.width, static_cast<int>((end - begin) * 4), job.format))
				job.failed.store(true, std::memory_order_relaxed);
		}, input, output);
	return ran && !payload.failed.load(std::memory_order_relaxed);
}
DEFINE_PRIM(_BOOL, decode_dxt_jobs, _BYTES _I32 _I32 _BYTES _I32 _I32 _I32 _I32 _I32);
