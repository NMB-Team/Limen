package limen.graphics.postprocess.fsr.upscaling;

enum abstract FSRCreateFlag(Int) to Int {
	final HIGH_DYNAMIC_RANGE = 1;
	final DISPLAY_RESOLUTION_MOTION_VECTORS = 2;
	final MOTION_VECTORS_JITTER_CANCELLATION = 4;
	final DEPTH_INVERTED = 8;
	final DEPTH_INFINITE = 16;
	final AUTO_EXPOSURE = 32;
	final DYNAMIC_RESOLUTION = 64;
	final DEBUG_CHECKING = 128;
	final NON_LINEAR_COLORSPACE = 256;
	final DEBUG_VISUALIZATION = 512;
}
