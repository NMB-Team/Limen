package limen.graphics.postprocess.fsr;

enum abstract FSRResult(Int) from Int to Int {
	public final InvalidState = -3;
	public final NotCreated = -2;
	final NotLoaded = -1;
	final Ok = 0;
	final Error = 1;
	final ErrorUnknownDescType = 2;
	final ErrorRuntimeError = 3;
	final NoProvider = 4;
	final ErrorMemory = 5;
	final ErrorParameter = 6;
	final ProviderNoSupportNewDescType = 7;
}
