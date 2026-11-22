package limen.graphics.postprocess.fsr;

enum abstract FSRDebugLevel(Int) to Int {
	final SILENCE = 0;
	final ERRORS = 1;
	final WARNINGS = 2;
	final VERBOSE = 0xfffffff;
}
