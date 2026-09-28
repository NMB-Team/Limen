package limen.graphics.postprocess.dlss;

import limen.graphics.GraphicsDriver;
import limen.graphics.renderer.d3d12.command.Commands.CommandList;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Adapter;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Device;
import limen.graphics.renderer.d3d12.internal.D3D12Bindings.Factory;
import limen.graphics.postprocess.dlss.frame.DLSSConstants;
import limen.graphics.postprocess.dlss.frame.DLSSFrameToken;
import limen.graphics.postprocess.dlss.framegen.DLSSGOptions;
import limen.graphics.postprocess.dlss.framegen.DLSSGStateInfo;
import limen.graphics.postprocess.dlss.pcl.PCLHotKey;
import limen.graphics.postprocess.dlss.pcl.PCLMarker;
import limen.graphics.postprocess.dlss.reflex.ReflexFrameReport;
import limen.graphics.postprocess.dlss.reflex.ReflexModeNative;
import limen.graphics.postprocess.dlss.reflex.ReflexStateInfo;
import limen.graphics.postprocess.dlss.resource.DLSSResource;
import limen.graphics.postprocess.dlss.upscaling.DLSSOptimalSettings;
import limen.graphics.postprocess.dlss.upscaling.DLSSOptions;
import limen.platform.Platform;
import limen.platform.internal.SdlBindings;

@:hlNative("limen", "dlss_")
class DLSS {
	public static inline final REFLEX_FRAME_REPORT_COUNT = 64;

	public static function isAvailable():Bool {
		return Platform.graphicsDriver == GraphicsDriver.D3D12 && SdlBindings.isDlssAvailable();
	}

	public static function init(showConsole:Bool, features:hl.NativeArray<Int>, checkSignature:Bool):Int {
		return 0;
	}

	public static function shutdown():Int {
		return 0;
	}

	public static function setDevice(device:Device):Int {
		return 0;
	}

	public static function upgradeDevice(nativeDevice:Device):Device {
		return null;
	}

	public static function upgradeFactory(nativeFactory:Factory):Factory {
		return null;
	}

	public static function isFeatureSupported(adapter:Adapter, feature:DLSSFeature):Int {
		return 0;
	}

	public static function getOptimalSettings(options:DLSSOptions, outOptimalSettings:DLSSOptimalSettings):Int {
		return 0;
	}

	public static function getNewFrameToken(frameIndex:Int):DLSSFrameToken {
		return null;
	}

	public static function pclInitStats():Int {
		return 0;
	}

	public static function pclSetMarker(frameToken:DLSSFrameToken, marker:PCLMarker):Int {
		return 0;
	}

	public static function pclPollPing(frameToken:DLSSFrameToken):Bool {
		return false;
	}

	public static function reflexSetOptions(mode:ReflexModeNative, frameLimitUs:Int, useMarkersToOptimize:Bool, virtualKey:PCLHotKey, threadId:Int):Int {
		return 0;
	}

	public static function reflexSleep(frameToken:DLSSFrameToken):Int {
		return 0;
	}

	public static function reflexGetState(outState:ReflexStateInfo):Int {
		return 0;
	}

	public static function reflexGetFrameReport(index:Int, outReport:ReflexFrameReport):Int {
		return 0;
	}

	public static function setTagForFrame(frameToken:DLSSFrameToken, resources:hl.CArray<DLSSResource>, count:Int, commandList:CommandList):Int {
		return 0;
	}

	public static function setOptions(options:DLSSOptions):Int {
		return 0;
	}

	public static function setConstants(frameToken:DLSSFrameToken, constants:DLSSConstants):Int {
		return 0;
	}

	public static function dlssgSetOptions(options:DLSSGOptions):Int {
		return 0;
	}

	public static function dlssgGetState(outState:DLSSGStateInfo):Int {
		return 0;
	}

	public static function setFeatureLoaded(feature:DLSSFeature, loaded:Bool):Int {
		return 0;
	}

	public static function freeResources(feature:DLSSFeature):Int {
		return 0;
	}

	public static function evaluateFeature(frameToken:DLSSFrameToken, commandList:CommandList, feature:DLSSFeature):Int {
		return 0;
	}
}
