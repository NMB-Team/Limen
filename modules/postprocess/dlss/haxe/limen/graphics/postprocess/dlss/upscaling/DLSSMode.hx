package limen.graphics.postprocess.dlss.upscaling;

enum abstract DLSSMode(Int) {
	final OFF = 0;
	final MAXPERFORMANCE = 1;
	final BALANCED = 2;
	final MAXQUALITY = 3;
	final ULTRAPERFORMANCE = 4;
	final ULTRAQUALITY = 5;
	final DLAA = 6;
}
