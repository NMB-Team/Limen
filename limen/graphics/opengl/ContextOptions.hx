package limen.graphics.opengl;

typedef ContextOptions = {
	var ?minimumMajor:Int;
	var ?minimumMinor:Int;
	var ?maximumMajor:Int;
	var ?maximumMinor:Int;
	var ?depthBits:Int;
	var ?stencilBits:Int;
	var ?samples:Int;
	var ?flags:Int;
	var ?vsync:Bool;
}
