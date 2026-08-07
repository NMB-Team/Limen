package limen.graphics.d3d12.internal;

import limen.graphics.d3d12.command.Commands.CommandList;
import limen.graphics.d3d12.command.Commands.CommandSignature;
import limen.graphics.d3d12.command.Commands.CommandSignatureDesc;
import limen.graphics.d3d12.command.Commands.Fence;
import limen.graphics.d3d12.DX12Core.Address;
import limen.graphics.d3d12.DX12Core.ClearValue;
import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.descriptor.ResourceViews.ConstantBufferViewDesc;
import limen.graphics.d3d12.descriptor.ResourceViews.DepthStencilViewDesc;
import limen.graphics.d3d12.descriptor.DescriptorHeap.DescriptorHeapType;
import limen.graphics.d3d12.descriptor.ResourceViews.Dx12ShaderResourceViewDesc;
import limen.graphics.d3d12.descriptor.ResourceViews.RenderTargetViewDesc;
import limen.graphics.d3d12.descriptor.ResourceViews.UnorderedAccessViewDesc;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.d3d12.resource.Resources.GpuResource;
import limen.graphics.d3d12.resource.Resources.HeapFlag;
import limen.graphics.d3d12.resource.Resources.HeapProperties;
import limen.graphics.d3d12.resource.Resources.HeapType;
import limen.graphics.d3d12.resource.Resources.PlacedSubresourceFootprint;
import limen.graphics.d3d12.resource.Resources.ResourceDesc;
import limen.graphics.d3d12.resource.Resources.ResourceState;
import limen.graphics.d3d12.resource.Resources.SubResourceData;
import limen.graphics.d3d12.pipeline.Pipeline.ComputePipelineState;
import limen.graphics.d3d12.pipeline.Pipeline.ComputePipelineStateDesc;
import limen.graphics.d3d12.pipeline.Pipeline.Dx12SamplerDesc;
import limen.graphics.d3d12.pipeline.Pipeline.GraphicsPipelineState;
import limen.graphics.d3d12.pipeline.Pipeline.GraphicsPipelineStateDesc;
import limen.graphics.d3d12.pipeline.RootSignature.RootSignature;
import limen.graphics.d3d12.pipeline.RootSignature.RootSignatureDesc;
import limen.graphics.d3d12.query.Queries.QueryHeap;
import limen.graphics.d3d12.query.Queries.QueryHeapDesc;

import haxe.Int64;

import limen.platform.Window;

abstract CompilerHandle(hl.Abstract<"dx_compiler">) {}
typedef Adapter = hl.Abstract<"dx_adapter">;
typedef Factory = hl.Abstract<"dx_factory">;

enum abstract Constant(Int) to Int {
	public final TEXTURE_DATA_PITCH_ALIGNMENT = 0;
	public final TEXTURE_DATA_PLACEMENT_ALIGNMENT = 1;
	public final DESCRIPTOR_RANGE_OFFSET_APPEND = 2;
	public final RESOURCE_BARRIER_ALL_SUBRESOURCES = 3;
}

typedef Device = hl.Abstract<"dx_device">;

@:hlNative("?limen_d3d12")
class D3D12Bindings {
	@:hlNative("?limen_d3d12", "compiler_create")
	public static function compilerCreate():CompilerHandle {
		return null;
	}

	@:hlNative("?limen_d3d12", "compiler_compile")
	public static function compilerCompile(compiler:CompilerHandle, source:hl.Bytes, profile:hl.Bytes, args:hl.NativeArray<hl.Bytes>, output:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public static function create(win:Window, flags:Dx12DriverInitFlags, ?deviceName:String) {
		return dxCreate(@:privateAccess win.win, flags, deviceName == null ? null : @:privateAccess deviceName.bytes);
	}

	public static function disposeDriver(driver:Dx12DriverInstance):Void {}

	public static function createCommandQueue() {}

	public static function getDevice():Device {
		return null;
	}

	public static function getFactory():Factory {
		return null;
	}

	public static function getAdapter():Adapter {
		return null;
	}

	public static function setDevice(device:Device) {}

	public static function setFactory(factory:Factory) {}

	public static function flushMessages() {}

	public static function suppressDebugMessages(filter:InfoQueueFilter):Void {}

	public static function getDescriptorHandleIncrementSize(type:DescriptorHeapType):Int {
		return 0;
	}

	public static function createGraphicsPipelineState(desc:GraphicsPipelineStateDesc):GraphicsPipelineState {
		return null;
	}

	public static function createComputePipelineState(desc:ComputePipelineStateDesc):ComputePipelineState {
		return null;
	}

	public static function serializeRootSignature(desc:RootSignatureDesc, version:Int, size:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public static function getBackBuffer(index:Int):GpuResource {
		return null;
	}

	public static function getCurrentBackBufferIndex():Int {
		return 0;
	}

	public static function createRenderTargetView(buffer:Dx12Resource, desc:RenderTargetViewDesc, target:Address) {}

	public static function createDepthStencilView(buffer:Dx12Resource, desc:DepthStencilViewDesc, target:Address) {}

	public static function createConstantBufferView(desc:ConstantBufferViewDesc, target:Address) {}

	public static function createUnorderedAccessView(res:Dx12Resource, counter:Dx12Resource, desc:UnorderedAccessViewDesc, target:Address) {}

	public static function createShaderResourceView(resource:Dx12Resource, desc:Dx12ShaderResourceViewDesc, target:Address) {}

	public static function createQueryHeap(desc:QueryHeapDesc):QueryHeap {
		return null;
	}

	public static function getCopyableFootprints(srcDesc:ResourceDesc, firstSubResource:Int, numSubResources:Int, baseOffset:Int64, layouts:PlacedSubresourceFootprint, numRows:hl.BytesAccess<Int>, rowSizeInBytes:hl.BytesAccess<Int64>,
		totalBytes:hl.BytesAccess<Int64>):Void {}

	public static function createSampler(desc:Dx12SamplerDesc, target:Address) {}

	public static function createCommittedResource(heapProperties:HeapProperties, heapFlags:haxe.EnumFlags<HeapFlag>, desc:ResourceDesc, initialState:ResourceState, clearValue:ClearValue):GpuResource {
		return null;
	}

	public static function createCommandSignature(desc:CommandSignatureDesc, root:RootSignature):CommandSignature {
		return null;
	}

	public static function resize(width:Int, height:Int, bufferCount:Int, format:DxgiFormat) {}

	public static function updateSubResource(commandList:CommandList, dst:GpuResource, src:GpuResource, srcOffset:Int64, first:Int, count:Int, data:SubResourceData):Bool {
		return false;
	}

	public static function signal(fence:Fence, value:Int64) {}

	public static function wait(fence:Fence, value:Int64) {}

	public static function present(vsync:Bool) {}

	public static function suspend() {}

	public static function resume() {}

	public static function setGpuCrashHandler(handler:(name:hl.Bytes, bytes:hl.Bytes, size:Int, lastFile:Bool) -> Void) {}

	public static function getConstant(index:Int):Int {
		return 0;
	}

	public static function copyDescriptorsSimple(numDescriptors:Int, dstCpuAddress:Address, srcCpuAddress:Address, heapType:DescriptorHeapType) {}

	public static function checkFeatureSupport(feature:Dx12Feature, data:hl.Bytes, dataSize:Int) {}

	public static function getDeviceName() {
		return @:privateAccess String.fromUCS2(dxGetDeviceName());
	}

	public static function listDevices() {
		final arr = dxListDevices();
		final out = [];
		for (i in 0...arr.length) {
			if (arr[i] == null)
				break;
			out.push(@:privateAccess String.fromUCS2(arr[i]));
		}
		return out;
	}

	@:hlNative("?limen_d3d12", "get_timestamp_frequency")
	public static function getTimestampFrequency():Int64 {
		return 0;
	}

	@:hlNative("?limen_d3d12", "list_devices")
	static function dxListDevices():hl.NativeArray<hl.Bytes> {
		return null;
	}

	@:hlNative("?limen_d3d12", "get_device_name")
	static function dxGetDeviceName():hl.Bytes {
		return null;
	}

	@:hlNative("?limen_d3d12", "get_driver_version")
	public static function getDriverVersion():Int64 {
		return 0;
	}

	@:hlNative("?limen_d3d12", "query_video_memory_info")
	public static function queryVideoMemoryInfo(group:Int, infos:QueryVideoMemoryInfo):Void {}

	@:hlNative("?limen_d3d12", "create_sdl")
	static function dxCreate(win:hl.Abstract<"limen_window">, flags:Dx12DriverInitFlags, deviceName:hl.Bytes):Dx12DriverInstance {
		return null;
	}
}

enum Dx12DriverInitFlag {
	DEBUG;
	GPU_BASED_VALIDATION;
	BREAK_ON_ERROR;
}

typedef Dx12DriverInitFlags = haxe.EnumFlags<Dx12DriverInitFlag>;
typedef Dx12DriverInstance = hl.Abstract<"dx_driver">;

enum abstract Dx12Feature(Int) {
	final D3D12_OPTIONS = 0;
	final ARCHITECTURE = 1;
	final FEATURE_LEVELS = 2;
	final FORMAT_SUPPORT = 3;
	final MULTISAMPLE_QUALITY_LEVELS = 4;
	final FORMAT_INFO = 5;
	final GPU_VIRTUAL_ADDRESS_SUPPORT = 6;
	final SHADER_MODEL = 7;
	final D3D12_OPTIONS1 = 8;
	final PROTECTED_RESOURCE_SESSION_SUPPORT = 10;
	final ROOT_SIGNATURE = 12;
	final ARCHITECTURE1 = 16;
	final D3D12_OPTIONS2 = 18;
	final SHADER_CACHE = 19;
	final COMMAND_QUEUE_PRIORITY = 20;
	final D3D12_OPTIONS3 = 21;
	final EXISTING_HEAPS = 22;
	final D3D12_OPTIONS4 = 23;
	final SERIALIZATION = 24;
	final CROSS_NODE = 25;
	final D3D12_OPTIONS5 = 27;
	final DISPLAYABLE;
	final D3D12_OPTIONS6 = 30;
	final QUERY_META_COMMAND = 31;
	final D3D12_OPTIONS7 = 32;
	final PROTECTED_RESOURCE_SESSION_TYPE_COUNT = 33;
	final PROTECTED_RESOURCE_SESSION_TYPES = 34;
	final D3D12_OPTIONS8 = 36;
	final D3D12_OPTIONS9 = 37;
	final D3D12_OPTIONS10;
	final D3D12_OPTIONS11;
	final D3D12_OPTIONS12;
	final D3D12_OPTIONS13;
	final D3D12_OPTIONS14;
	final D3D12_OPTIONS15;
	final D3D12_OPTIONS16;
	final D3D12_OPTIONS17;
	final D3D12_OPTIONS18;
	final D3D12_OPTIONS19;
	final D3D12_OPTIONS20;
	final PREDICATION;
	final PLACED_RESOURCE_SUPPORT_INFO;
	final HARDWARE_COPY;
	final D3D12_OPTIONS21;
	final APPLICATION_SPECIFIC_DRIVER_STATE;
	final BYTECODE_BYPASS_HASH_SUPPORTED;
	final SHADER_CACHE_ABI_SUPPORT;
}

@:struct class InfoQueueFilter {
	@:packed
	public var allowList(default, null):InfoQueueFilterDesc;
	@:packed
	public var denyList(default, null):InfoQueueFilterDesc;

	public function new() {}
}

@:struct class InfoQueueFilterDesc {
	public var numCategories:Int;
	public var categoryList:hl.Bytes;
	public var numSeverities:Int;
	public var severityList:hl.Bytes;
	public var numIDs:Int;
	public var idList:hl.Bytes;

	public function new() {}
}

@:struct class QueryVideoMemoryInfo {
	public var budget:Int64;
	public var currentUsage:Int64;
	public var availableForReservation:Int64;
	public var currentReservation:Int64;

	public function new() {}
}
