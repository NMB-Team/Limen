package limen.d3d11;

enum abstract DriverFlags(Int) {
	final None = 0;
	final SingleThread = 1;
	final DebugLayer = 2;
	final SwitchToRef = 4;
	final PreventInternalThreadingOptimizations = 8;
	final BgraSupport = 32;
	final Debuggable = 64;
	final PreventAlteringLayerSettingsFromRegistry = 128;
	final DisableGpuTimeout = 256;
	final VideoSupport = 2048;

	@:op(a | b)
	static function or(a:DriverFlags, b:DriverFlags):DriverFlags;
}
