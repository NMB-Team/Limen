package limen.graphics.postprocess.dlss.pcl;

enum abstract PCLMarker(Int) {
	final SIMULATION_START = 0;
	final SIMULATION_END = 1;
	final RENDER_SUBMIT_START = 2;
	final RENDER_SUBMIT_END = 3;
	final PRESENT_START = 4;
	final PRESENT_END = 5;
	final TRIGGER_FLASH = 7;
	final PCLATENCY_PING = 8;
	final CONTROLLER_INPUT_SAMPLE = 13;
	final DELTA_T_CALCULATION = 14;
}
