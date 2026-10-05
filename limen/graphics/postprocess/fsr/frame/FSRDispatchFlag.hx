package limen.graphics.postprocess.fsr.frame;

enum abstract FSRDispatchFlag(Int) to Int {
	final DRAW_DEBUG_VIEW = 1;
	final NON_LINEAR_COLOR_SRGB = 2;
	final NON_LINEAR_COLOR_PQ = 4;
}
