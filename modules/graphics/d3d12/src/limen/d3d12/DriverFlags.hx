package limen.d3d12;

enum abstract DriverFlags(Int) {
	final None = 0;
	final DebugLayer = 1;
	final GpuBasedValidation = 2;
	final BreakOnError = 4;
	final Dred = 8;

	@:op(a | b)
	static function or(a:DriverFlags, b:DriverFlags):DriverFlags;
}
