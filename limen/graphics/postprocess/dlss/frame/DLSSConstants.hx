package limen.graphics.postprocess.dlss.frame;

@:struct
class DLSSConstants {
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
