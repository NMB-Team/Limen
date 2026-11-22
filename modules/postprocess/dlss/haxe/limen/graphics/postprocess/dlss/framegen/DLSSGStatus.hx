package limen.graphics.postprocess.dlss.framegen;

enum abstract DLSSGStatus(Int) from Int {
	final OK = 0;
	final FAIL_RESOLUTION_TOO_LOW = 1;
	final FAIL_REFLEX_NOT_DETECTED_AT_RUNTIME = 2;
	final FAIL_HDR_FORMAT_NOT_SUPPORTED = 4;
	final FAIL_COMMON_CONSTANTS_INVALID = 8;
	final FAIL_GET_CURRENT_BACK_BUFFER_INDEX_NOT_CALLED = 16;
}
