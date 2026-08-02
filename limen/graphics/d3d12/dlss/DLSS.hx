package limen.graphics.d3d12.dlss;

import limen.graphics.GraphicsDriver;
import limen.graphics.d3d12.command.Commands.CommandList;
import limen.graphics.d3d12.internal.D3D12Bindings.Adapter;
import limen.graphics.d3d12.internal.D3D12Bindings.Device;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.d3d12.resource.Resources.ResourceState;
import limen.platform.Platform;
import limen.platform.internal.SdlBindings;

typedef DLSSFrameToken = hl.Abstract<"dlss_frametoken">;

enum abstract DLSSResult(Int) {
	final Ok = 0;
	final ErrorIO = 1;
	final ErrorDriverOutOfDate = 2;
	final ErrorOSOutOfDate = 3;
	final ErrorOSDisabledHWS = 4;
	final ErrorDeviceNotCreated = 5;
	final ErrorNoSupportedAdapterFound = 6;
	final ErrorAdapterNotSupported = 7;
	final ErrorNoPlugins = 8;
	final ErrorVulkanAPI = 9;
	final ErrorDXGIAPI = 10;
	final ErrorD3DAPI = 11;
	final ErrorNRDAPI = 12;
	final ErrorNVAPI = 13;
	final ErrorReflexAPI = 14;
	final ErrorNGXFailed = 15;
	final ErrorJSONParsing = 16;
	final ErrorMissingProxy = 17;
	final ErrorMissingResourceState = 18;
	final ErrorInvalidIntegration = 19;
	final ErrorMissingInputParameter = 20;
	final ErrorNotInitialized = 21;
	final ErrorComputeFailed = 22;
	final ErrorInitNotCalled = 23;
	final ErrorExceptionHandler = 24;
	final ErrorInvalidParameter = 25;
	final ErrorMissingConstants = 26;
	final ErrorDuplicatedConstants = 27;
	final ErrorMissingOrInvalidAPI = 28;
	final ErrorCommonConstantsMissing = 29;
	final ErrorUnsupportedInterface = 30;
	final ErrorFeatureMissing = 31;
	final ErrorFeatureNotSupported = 32;
	final ErrorFeatureMissingHooks = 33;
	final ErrorFeatureFailedToLoad = 34;
	final ErrorFeatureWrongPriority = 35;
	final ErrorFeatureMissingDependency = 36;
	final ErrorFeatureManagerInvalidState = 37;
	final ErrorInvalidState = 38;
	final WarnOutOfVRAM = 39;
}

enum abstract DLSSFeature(Int) {
	final DLSS = 0;
	final FRAMEGEN = 1;
}

enum abstract DLSSPreset(Int) {
	final PRESET_DEFAULT = 0;
	final PRESET_A = 1;
	final PRESET_B = 2;
	final PRESET_C = 3;
	final PRESET_D = 4;
	final PRESET_E = 5;
	final PRESET_F = 6;
	final PRESET_G = 7;
	final PRESET_H = 8;
	final PRESET_I = 9;
	final PRESET_J = 10;
	final PRESET_K = 11;
	final PRESET_L = 12;
	final PRESET_M = 13;
}

enum abstract DLSSMode(Int) {
	final OFF = 0;
	final MAXPERFORMANCE = 1;
	final BALANCED = 2;
	final MAXQUALITY = 3;
	final ULTRAPERFORMANCE = 4;
	final ULTRAQUALITY = 5;
	final DLAA = 6;
}

@:struct class DLSSOptions {
	public var mode:DLSSMode;
	public var outputWidth:Int;
	public var outputHeight:Int;
	public var preset:DLSSPreset;
	public var colorBufferHDR:Bool;
	public var autoExposure:Bool;

	public function new() {}
}

@:struct class DLSSOptimalSettings {
	public var optimalRenderWidth:Int;
	public var optimalRenderHeight:Int;
	public var optimalSharpness:Float;

	public function new() {}
}

enum abstract DLSSBufferType(Int) {
	final DEPTH = 0;
	final MOTIONVECTORS = 1;
	final COLORIN = 2;
	final COLOROUT = 3;
}

@:struct class DLSSResource {
	public var res:Dx12Resource;
	public var width:Int;
	public var height:Int;
	public var type:DLSSBufferType;
	public var state:ResourceState;

	public function new() {}
}

@:struct class DLSSVector {
	public var x:Single;
	public var y:Single;
	public var z:Single;

	public function new() {}
}

@:struct class DLSSMatrix {
	public var _11:Single;
	public var _12:Single;
	public var _13:Single;
	public var _14:Single;
	public var _21:Single;
	public var _22:Single;
	public var _23:Single;
	public var _24:Single;
	public var _31:Single;
	public var _32:Single;
	public var _33:Single;
	public var _34:Single;
	public var _41:Single;
	public var _42:Single;
	public var _43:Single;
	public var _44:Single;

	public function new() {}
}

@:struct class DLSSConstants {
	public var cameraViewToClip:DLSSMatrix;
	public var clipToCameraView:DLSSMatrix;
	public var clipToLensClip:DLSSMatrix;
	public var clipToPrevClip:DLSSMatrix;
	public var prevClipToClip:DLSSMatrix;
	public var jitterOffsetX:Single;
	public var jitterOffsetY:Single;
	public var mvecScaleX:Single;
	public var mvecScaleY:Single;
	public var cameraPinholeOffsetX:Single;
	public var cameraPinholeOffsetY:Single;
	public var cameraPos:DLSSVector;
	public var cameraUp:DLSSVector;
	public var cameraRight:DLSSVector;
	public var cameraFwd:DLSSVector;
	public var cameraNear:Single;
	public var cameraFar:Single;
	public var cameraFOV:Single;
	public var cameraAspectRatio:Single;
	public var motionVectorsInvalidValue:Single;
	public var depthInverted:Bool;
	public var cameraMotionIncluded:Bool;
	public var motionVectors3D:Bool;
	public var reset:Bool;
	public var orthographicProjection:Bool;
	public var motionVectorsDilated:Bool;
	public var motionVectorsJittered:Bool;
	public var minRelativeLinearDepthObjectSeparation:Single;

	public function new() {}
}

@:hlNative("?limen_dlss")
class DLSS {
	public static function isAvailable():Bool {
		return Platform.graphicsDriver == GraphicsDriver.D3D12 && SdlBindings.isDlssAvailable();
	}

	public static function init(showConsole:Bool):Int {
		return 0;
	}

	public static function shutdown():Int {
		return 0;
	}

	public static function setDevice(device:Device):Int {
		return 0;
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

	public static function setTagForFrame(frameToken:DLSSFrameToken, resources:hl.CArray<DLSSResource>, count:Int, commandList:CommandList):Int {
		return 0;
	}

	public static function setOptions(options:DLSSOptions):Int {
		return 0;
	}

	public static function setConstants(frameToken:DLSSFrameToken, constants:DLSSConstants):Int {
		return 0;
	}

	public static function evaluateFeature(frameToken:DLSSFrameToken, commandList:CommandList, feature:DLSSFeature):Int {
		return 0;
	}
}
