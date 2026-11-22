package limen.graphics.postprocess.dlss.resource;

enum abstract DLSSBufferType(Int) {
	final DEPTH = 0;
	final MOTIONVECTORS = 1;
	final COLORIN = 2;
	final COLOROUT = 3;
	final HUDLESSCOLOR = 4;
	final UICOLORANDALPHA = 5;
	final UIALPHA = 6;
	final BACKBUFFER = 7;
}
