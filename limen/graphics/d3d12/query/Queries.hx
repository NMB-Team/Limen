package limen.graphics.d3d12.query;

import limen.graphics.d3d12.resource.Resources.Dx12Resource;

import haxe.Int64;

@:forward(release)
abstract QueryHeap(Dx12Resource) {}

@:struct class QueryHeapDesc {
	public var type:QueryHeapType;
	public var count:Int;
	public var nodeMask:Int;

	public function new() {}
}

enum abstract QueryHeapType(Int) {
	final OCCLUSION = 0;
	final TIMESTAMP = 1;
	final PIPELINE_STATISTICS = 2;
	final SO_STATISTICS = 3;
	final VIDEO_DECODE_STATISTICS = 4;
	final COPY_QUEUE_TIMESTAMP = 5;
}

enum abstract QueryType(Int) {
	final OCCLUSION = 0;
	final BINARY_OCCLUSION = 1;
	final TIMESTAMP = 2;
	final PIPELINE_STATISTICS = 3;
	final SO_STATISTICS_STREAM0 = 4;
	final SO_STATISTICS_STREAM1 = 5;
	final SO_STATISTICS_STREAM2 = 6;
	final SO_STATISTICS_STREAM3 = 7;
	final VIDEO_DECODE_STATISTICS = 8;
}
