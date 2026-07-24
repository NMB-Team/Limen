package limen.graphics.opengl;

typedef ContextOptions = {
	@:optional var minimumMajor:Int;
	@:optional var minimumMinor:Int;
	@:optional var maximumMajor:Int;
	@:optional var maximumMinor:Int;
	@:optional var depthBits:Int;
	@:optional var stencilBits:Int;
	@:optional var samples:Int;
	@:optional var flags:Int;
	@:optional var vsync:Bool;
}
