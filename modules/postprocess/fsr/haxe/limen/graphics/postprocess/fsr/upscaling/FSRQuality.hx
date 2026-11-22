package limen.graphics.postprocess.fsr.upscaling;

enum abstract FSRQuality(Int) to Int {
	final NATIVE_AA = 0;
	final QUALITY = 1;
	final BALANCED = 2;
	final PERFORMANCE = 3;
	final ULTRA_PERFORMANCE = 4;
}
