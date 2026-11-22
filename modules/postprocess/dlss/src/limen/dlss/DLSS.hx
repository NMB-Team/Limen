package limen.dlss;

import limen.GraphicsDriver;
import limen.vulkan.VulkanRequirements;
import limen.postprocess.PostProcessDevice;
import limen.postprocess.CommandBuffer;
import limen.d3d12.Types.SwapChain;
import limen.d3d12.command.Commands.CommandQueue;
import limen.d3d12.Types.Device;
import limen.d3d12.Types.Factory;
import limen.dlss.frame.DLSSConstants;
import limen.dlss.frame.DLSSFrameToken;
import limen.dlss.framegen.DLSSGOptions;
import limen.dlss.framegen.DLSSGStateInfo;
import limen.dlss.pcl.PCLHotKey;
import limen.dlss.pcl.PCLMarker;
import limen.dlss.reflex.ReflexFrameReport;
import limen.dlss.reflex.ReflexModeNative;
import limen.dlss.reflex.ReflexStateInfo;
import limen.dlss.resource.DLSSResource;
import limen.dlss.upscaling.DLSSOptimalSettings;
import limen.dlss.upscaling.DLSSOptions;
import limen.Platform;
import limen.internal.SDLBindings;

@:hlNative("limen", "dlss_")
class DLSS {
	public static inline final REFLEX_FRAME_REPORT_COUNT = 64;

	public static function isAvailable():Bool {
		return SDLBindings.isDlssAvailable();
	}

	public static function init(showConsole:Bool, features:hl.NativeArray<Int>, checkSignature:Bool, ?backend:GraphicsDriver):Int {
		return initBackend(showConsole, features, checkSignature, backend ?? Platform.graphicsDriver);
	}

	@:hlNative("limen", "dlss_init")
	static function initBackend(showConsole:Bool, features:hl.NativeArray<Int>, checkSignature:Bool, backend:GraphicsDriver):Int {
		return 0;
	}

	public static function getVulkanRequirements(features:hl.NativeArray<Int>, requirements:VulkanRequirements):Int {
		return 0;
	}

	public static function shutdown():Int {
		return 0;
	}

	public static function setDevice(device:PostProcessDevice):Int {
		return 0;
	}

	public static function upgradeDevice(nativeDevice:Device):Device {
		return null;
	}

	public static function upgradeFactory(nativeFactory:Factory):Factory {
		return null;
	}

	public static function isFeatureSupported(device:PostProcessDevice, feature:DLSSFeature):Int {
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

	public static function setTagForFrame(frameToken:DLSSFrameToken, resources:hl.CArray<DLSSResource>, count:Int, commandList:CommandBuffer):Int {
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

	public static function evaluateFeature(frameToken:DLSSFrameToken, commandList:CommandBuffer, feature:DLSSFeature):Int {
		return 0;
	}

	public static function upgradeSwapChain(nativeSwapChain:SwapChain):SwapChain {
		return null;
	}

	public static function getNativeDevice(device:Device):Device {
		return null;
	}

	public static function getNativeFactory(factory:Factory):Factory {
		return null;
	}

	public static function getNativeQueue(queue:CommandQueue):CommandQueue {
		return null;
	}
}
