package limen.graphics.d3d12.command;

import limen.graphics.d3d12.DX12Core.Address;
import limen.graphics.d3d12.DX12Core.Bool32;
import limen.graphics.d3d12.DX12Core.Box;
import limen.graphics.d3d12.DX12Core.ClearColor;
import limen.graphics.d3d12.DX12Core.Color;
import limen.graphics.d3d12.DX12Core.Dx12PrimitiveTopology;
import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.DX12Core.Rect;
import limen.graphics.d3d12.DX12Core.Viewport;
import limen.graphics.d3d12.descriptor.DescriptorHeap.DescriptorHeap;
import limen.graphics.d3d12.internal.D3D12Bindings.Constant;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.d3d12.resource.Resources.GpuResource;
import limen.graphics.d3d12.resource.Resources.ResourceBarrier;
import limen.graphics.d3d12.resource.Resources.TextureCopyLocation;
import limen.graphics.d3d12.pipeline.Pipeline.PipelineState;
import limen.graphics.d3d12.pipeline.RootSignature.RootSignature;
import limen.graphics.d3d12.query.Queries.QueryHeap;
import limen.graphics.d3d12.query.Queries.QueryType;

import haxe.Int64;

enum abstract ClearFlags(Int) {
	final DEPTH = 1;
	final STENCIL = 2;
	final BOTH = 3;
}

@:hlNative("limen", "d3d12_command_allocator_")
abstract CommandAllocator(Dx12Resource) {
	public function new(type) {
		this = create(type);
	}

	public function reset() {}

	static function create(type:CommandListType):Dx12Resource {
		return null;
	}
}

@:hlNative("limen", "d3d12_command_list_")
abstract CommandList(Dx12Resource) {
	public function new(type, alloc, state) {
		this = create(type, alloc, state);
	}

	public function close() {}

	public function clearRenderTargetView(rtv:Address, color:ClearColor) {}

	public function clearDepthStencilView(rtv:Address, flags:ClearFlags, depth:Single, stencil:Int) {}

	public function reset(alloc:CommandAllocator, state:PipelineState) {}

	public function resourceBarrier(b:ResourceBarrier) {}

	public function resourceBarriers(b:hl.CArray<ResourceBarrier>, barrierCount:Int) {}

	public function setPipelineState(state:PipelineState) {}

	public function setDescriptorHeaps(heaps:hl.NativeArray<DescriptorHeap>) {}

	public function copyBufferRegion(dst:GpuResource, dstOffset:Int64, src:GpuResource, srcOffset:Int64, size:Int64) {}

	public function copyTextureRegion(dst:TextureCopyLocation, dstX:Int, dstY:Int, dstZ:Int, src:TextureCopyLocation, srcBox:Box) {}

	public function setGraphicsRootSignature(sign:RootSignature) {}

	public function setGraphicsRoot32BitConstants(index:Int, numValues:Int, data:hl.Bytes, dstOffset:Int) {}

	public function setGraphicsRootConstantBufferView(index:Int, address:Address) {}

	public function setGraphicsRootDescriptorTable(index:Int, address:Address) {}

	public function setGraphicsRootShaderResourceView(index:Int, address:Address) {}

	public function setGraphicsRootUnorderedAccessView(index:Int, address:Address) {}

	public function iaSetPrimitiveTopology(top:Dx12PrimitiveTopology) {}

	public function iaSetVertexBuffers(startSlot:Int, numViews:Int, views:VertexBufferView /* hl.CArray */) {}

	public function iaSetIndexBuffer(view:IndexBufferView) {}

	public function drawInstanced(vertexCountPerInstance:Int, instanceCount:Int, startVertexLocation:Int, startInstanceLocation:Int) {}

	public function drawIndexedInstanced(indexCountPerInstance:Int, instanceCount:Int, startIndexLocation:Int, baseVertexLocation:Int, startInstanceLocation:Int) {}

	public function executeIndirect(sign:CommandSignature, maxCommandCount:Int, args:Dx12Resource, argsOffset:Int64, count:Dx12Resource, countOffset:Int64) {}

	public function omSetRenderTargets(count:Int, handles:hl.BytesAccess<Address>, flag:Bool32, depthStencils:hl.BytesAccess<Address>) {}

	public function omSetStencilRef(value:Int) {}

	public function rsSetViewports(count:Int, viewports:Viewport) {}

	public function rsSetScissorRects(count:Int, rects:Rect) {}

	#if heaps_debug_events
	@:hlNative("limen", "d3d12_command_list_pix_begin_event")
	public function pixBeginEvent(color:haxe.Int64, formatString:hl.Bytes) {}

	@:hlNative("limen", "d3d12_command_list_pix_end_event")
	public function pixEndEvent() {}
	#end

	public function beginQuery(heap:QueryHeap, type:QueryType, index:Int) {}

	public function endQuery(heap:QueryHeap, type:QueryType, index:Int) {}

	public function resolveQueryData(heap:QueryHeap, type:QueryType, index:Int, count:Int, dest:Dx12Resource, offset:Int64) {}

	public function setPredication(res:Dx12Resource, offset:Int64, op:PredicationOp) {}

	public function setComputeRootSignature(sign:RootSignature) {}

	public function setComputeRoot32BitConstants(index:Int, numValues:Int, data:hl.Bytes, dstOffset:Int) {}

	public function setComputeRootConstantBufferView(index:Int, address:Address) {}

	public function setComputeRootDescriptorTable(index:Int, address:Address) {}

	public function setComputeRootShaderResourceView(index:Int, address:Address) {}

	public function setComputeRootUnorderedAccessView(index:Int, address:Address) {}

	public function dispatch(x:Int, y:Int, z:Int) {}

	static function create(type:CommandListType, alloc:CommandAllocator, state:PipelineState):Dx12Resource {
		return null;
	}
}

enum abstract CommandListType(Int) {
	public final DIRECT = 0;
	public final BUNDLE = 1;
	public final COMPUTE = 2;
	public final COPY = 3;
	public final VIDEO_DECODE = 4;
	public final VIDEO_PROCESS = 5;
	public final VIDEO_ENCODE = 6;
}

@:hlNative("limen", "d3d12_command_queue_")
abstract CommandQueue(Dx12Resource) {
	public function new(type) {
		this = create(type);
	}

	public function executeCommandList(commandList:CommandList) {}

	public function executeCommandLists(commandLists:hl.CArray<CommandList>, count:Int) {}

	public function signal(fence:Fence, value:Int64) {}

	public function wait(fence:Fence, value:Int64) {}

	public function present(vsync:Bool) {}

	public function suspend() {}

	public function resume() {}

	@:hlNative("limen", "d3d12_command_queue_get_timestamp_frequency")
	public function getTimestampFrequency():Int64 {
		return 0;
	}

	static function create(type:CommandListType):Dx12Resource {
		return null;
	}
}

@:forward(release)
abstract CommandSignature(Dx12Resource) {}

@:struct class CommandSignatureDesc {
	public var byteStride:Int;
	public var numArgumentDescs:Int;
	public var argumentDescs:hl.CArray<IndirectArgumentDesc>;
	public var nodeMask:Int;

	public function new() {}
}

@:hlNative("limen", "d3d12_fence_")
abstract Fence(Dx12Resource) {
	public function new(value, flags) {
		this = create(value, flags);
	}

	@:hlNative("limen", "d3d12_fence_get_completed_value")
	public function getValue():Int64 {
		return 0;
	}

	public function setEvent(value:Int64, event:WaitEvent) {}

	static function create(value:Int64, flags:FenceFlags):Dx12Resource {
		return null;
	}
}

enum abstract FenceFlags(Int) {
	final NONE = 0;
	final SHARED = 1;
	final SHARED_CROSS_ADAPTER = 2;
	final NON_MONITORED = 4;
}

@:struct class IndexBufferView {
	public var bufferLocation:Address;
	public var sizeInBytes:Int;
	public var format:DxgiFormat;

	public function new() {}
}

@:struct class IndirectArgumentDesc {
	public var type:IndirectArgumentType;
	public var rootParameterIndex:Int;
	public var destOffsetIn32BitValues:Int;
	public var num32BitValuesToSet:Int;
	public var slot(get, set):Int;

	@:noCompletion
	inline function get_slot() {
		return rootParameterIndex;
	}

	@:noCompletion
	inline function set_slot(v) {
		return rootParameterIndex = v;
	}

	public function new() {}
}

enum abstract IndirectArgumentType(Int) {
	final DRAW = 0;
	final DRAW_INDEXED = 1;
	final DISPATCH = 2;
	final VERTEX_BUFFER_VIEW = 3;
	final INDEX_BUFFER_VIEW = 4;
	final CONSTANT = 5;
	final CONSTANT_BUFFER_VIEW = 6;
	final SHADER_RESOURCE_VIEW = 7;
	final UNORDERED_ACCESS_VIEW = 8;
	final DISPATCH_RAYS = 9;
	final DISPATCH_MESH = 10;
}

enum abstract PredicationOp(Int) {
	final EQUAL_ZERO = 0;
	final NOT_EQUAL_ZERO = 1;
}

@:struct class VertexBufferView {
	public var bufferLocation:Address;
	public var sizeInBytes:Int;
	public var strideInBytes:Int;

	public function new() {}
}

@:hlNative("limen", "d3d12_waitevent_")
abstract WaitEvent(hl.Abstract<"dx_event">) {
	public function new(state) {
		this = cast create(state);
	}

	public function wait(time:Int):Bool {
		return false;
	}

	static function create(state:Bool):WaitEvent {
		return null;
	}
}
