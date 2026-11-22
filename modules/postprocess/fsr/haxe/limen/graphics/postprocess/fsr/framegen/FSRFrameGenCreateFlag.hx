package limen.graphics.postprocess.fsr.framegen;

enum abstract FSRFrameGenCreateFlag(Int) to Int {
	public final ASYNC_WORKLOAD_SUPPORT = 1;
	public final DISPLAY_RESOLUTION_MOTION_VECTORS = 2;
	public final MOTION_VECTORS_JITTER_CANCELLATION = 4;
	public final DEPTH_INVERTED = 8;
	public final DEPTH_INFINITE = 16;
	public final HIGH_DYNAMIC_RANGE = 32;
	public final DEBUG_CHECKING = 64;
}
