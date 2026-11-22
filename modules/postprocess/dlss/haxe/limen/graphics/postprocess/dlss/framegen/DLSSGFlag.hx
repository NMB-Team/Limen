package limen.graphics.postprocess.dlss.framegen;

enum abstract DLSSGFlag(Int) to Int {
	final SHOW_ONLY_INTERPOLATED_FRAME = 1;
	final DYNAMIC_RESOLUTION_ENABLED = 2;
	final REQUEST_VRAM_ESTIMATE = 4;
	final RETAIN_RESOURCES_WHEN_OFF = 8;
	final ENABLE_FULLSCREEN_MENU_DETECTION = 16;
}
