package limen.graphics.postprocess.dlss.resource;

enum abstract DLSSResourceLifecycle(Int) {
	final ONLY_VALID_NOW = 0;
	final VALID_UNTIL_PRESENT = 1;
	final VALID_UNTIL_EVALUATE = 2;
}
