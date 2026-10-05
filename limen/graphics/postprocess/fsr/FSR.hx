package limen.graphics.postprocess.fsr;

import limen.graphics.GraphicsDriver;
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
}
