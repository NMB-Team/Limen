package limen.graphics.postprocess.fsr.framegen;

enum abstract FSRFrameGenFlag(Int) to Int {
	public final DRAW_DEBUG_TEAR_LINES = 1;
	public final DRAW_DEBUG_RESET_INDICATORS = 2;
	public final DRAW_DEBUG_VIEW = 4;
	public final NO_SWAPCHAIN_CONTEXT_NOTIFY = 8;
	public final DRAW_DEBUG_PACING_LINES = 16;
}
