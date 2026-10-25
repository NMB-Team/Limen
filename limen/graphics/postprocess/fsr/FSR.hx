package limen.graphics.postprocess.fsr;

import limen.graphics.GraphicsDriver;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Factory;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.SwapChain;
import limen.graphics.renderer.d3d12.command.Commands.CommandQueue;
import limen.graphics.renderer.d3d12.DX12Core.DxgiFormat;
import limen.graphics.renderer.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.renderer.d3d12.resource.Resources.ResourceState;
import limen.graphics.postprocess.fsr.framegen.*;
import limen.platform.window.Window;
import limen.platform.internal.types.WinPtr;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Device;
import limen.graphics.renderer.d3d12.command.Commands.CommandList;
import limen.graphics.postprocess.fsr.frame.FSRDispatchParams;
import limen.graphics.postprocess.fsr.upscaling.FSRQuality;
import limen.platform.Platform;
import limen.platform.internal.SDLBindings;

@:hlNative("limen", "fsr_")
class FSR {
	public static function isAvailable():Bool {
		return Platform.graphicsDriver == GraphicsDriver.D3D12 && SDLBindings.isFsrAvailable();
	}

	public static function init(device:Device, debugLevel:FSRDebugLevel):Int {
		return 0;
	}

	public static function shutdown():Int {
		return 0;
	}

	public static function getRenderResolution(device:Device, quality:FSRQuality, displayWidth:Int, displayHeight:Int, renderWidth:hl.Ref<Int>, renderHeight:hl.Ref<Int>):Int {
		return 0;
	}

	public static function createContext(device:Device, flags:Int, maxRenderWidth:Int, maxRenderHeight:Int, maxUpscaleWidth:Int, maxUpscaleHeight:Int, result:hl.Ref<Int>):FSRContext {
		return null;
	}

	public static function destroyContext(context:FSRContext):Int {
		return 0;
	}

	public static function dispatch(context:FSRContext, commandList:CommandList, params:FSRDispatchParams):Int {
		return 0;
	}

	static function getVersionName(context:FSRContext):hl.Bytes {
		return null;
	}

	public static function getVersion(context:FSRContext):String {
		final bytes = getVersionName(context);
		return bytes == null ? null : @:privateAccess String.fromUTF8(bytes);
	}

	public static function getEffectVersionCount(device:Device, effect:FSREffect, count:hl.Ref<Int>):Int {
		return 0;
	}

	static function getEffectVersionName(device:Device, effect:FSREffect, index:Int):hl.Bytes {
		return null;
	}

	public static function getEffectVersion(device:Device, effect:FSREffect, index:Int = 0):String {
		var bytes = getEffectVersionName(device, effect, index);
		return bytes == null ? null : @:privateAccess String.fromUTF8(bytes);
	}

	public static function isEffectAvailable(device:Device, effect:FSREffect):Bool {
		var count = 0;
		return getEffectVersionCount(device, effect, count) == FSRResult.Ok && count > 0;
	}

	@:hlNative("limen", "fsr_create_swap_chain")
	static function createSwapChainNative(window:WinPtr, nativeFactory:Factory, nativeQueue:CommandQueue, width:Int, height:Int, bufferCount:Int, format:DxgiFormat, result:hl.Ref<Int>):SwapChain {
		return null;
	}

	public static function destroySwapChainContext():Int {
		return 0;
	}

	public static function releaseSwapChain(swapChain:SwapChain):Int {
		return 0;
	}

	public static function waitForPresents():Int {
		return 0;
	}

	public static function registerUiResource(resource:Dx12Resource, state:ResourceState, flags:Int):Int {
		return 0;
	}

	public static function setFramePacingTuning(safetyMarginInMs:Single, varianceFactor:Single, allowHybridSpin:Bool, hybridSpinTime:Int, allowWaitForSingleObjectOnFence:Bool):Int {
		return 0;
	}

	public static function querySwapChainMemory(totalBytes:hl.Ref<Float>, aliasableBytes:hl.Ref<Float>):Int {
		return 0;
	}

	public static function createFrameGenContext(device:Device, flags:Int, displayWidth:Int, displayHeight:Int, maxRenderWidth:Int, maxRenderHeight:Int, backBufferFormat:DxgiFormat, hudlessFormat:DxgiFormat, result:hl.Ref<Int>):FSRContext {
		return null;
	}

	public static function configureFrameGen(context:FSRContext, config:FSRFrameGenConfig):Int {
		return 0;
	}

	public static function dispatchFrameGenPrepare(context:FSRContext, commandList:CommandList, params:FSRFrameGenPrepareParams):Int {
		return 0;
	}

	public static function queryFrameGenMemory(context:FSRContext, totalBytes:hl.Ref<Float>, aliasableBytes:hl.Ref<Float>):Int {
		return 0;
	}

	@:hlNative("limen", "fsr_antilag2_init")
	public static function antiLag2Init(device:Device):Int {
		return 0;
	}

	@:hlNative("limen", "fsr_antilag2_deinit")
	public static function antiLag2DeInit():Int {
		return 0;
	}

	@:hlNative("limen", "fsr_antilag2_update")
	public static function antiLag2Update(enable:Bool, maxFps:Int):Int {
		return 0;
	}

	@:hlNative("limen", "fsr_antilag2_present")
	public static function antiLag2Present(swapChain:SwapChain, enabled:Bool):Int {
		return 0;
	}

	public static function createSwapChain(window:Window, nativeFactory:Factory, nativeQueue:CommandQueue, width:Int, height:Int, bufferCount:Int, format:DxgiFormat, result:hl.Ref<Int>):SwapChain {
		return createSwapChainNative(window.nativeHandle, nativeFactory, nativeQueue, width, height, bufferCount, format, result);
	}
}
