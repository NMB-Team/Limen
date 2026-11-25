package limen;

/**
	Reusable, thread-confined indexed draw records. Each submission borrows the
	current backend bindings for the duration of the call. The caller owns the
	command list and GPU resource lifetimes through completion.
**/
class IndexedCommandStream {
	final words:hl.NativeArray<Int>;
	var used = 1;

	public function new(capacity:Int) {
		// leave room for hashlink array headers and allocator alignment
		if (capacity < 1 || capacity > Std.int((0x7FFE0000 - 4) / 20))
			throw "Invalid indexed command capacity";

		words = new hl.NativeArray<Int>(1 + capacity * 5);
		words[0] = 1;
	}

	public inline function clear() {
		used = 1;
	}

	public inline function draw(indexCount:Int, instanceCount:Int, firstIndex:Int, vertexOffset:Int, firstInstance:Int) {
		final start = used;
		if (start == words.length)
			throw "Indexed command stream is full";

		words[start] = indexCount;
		words[start + 1] = instanceCount;
		words[start + 2] = firstIndex;
		words[start + 3] = vertexOffset;
		words[start + 4] = firstInstance;
		used = start + 5;
	}
}
