import limen.platform.window.Window;
import limen.platform.window.WindowFlags;
import limen.platform.window.WindowFlags.*;
import haxe.Int64;

@:hlNative("limen")
private class WindowFlagsTestBindings {
	public static function testLastWindowFlags():hl.I64 {
		return 0;
	}
}

class WindowFlagsTest {
	static function main():Void {
		final flags:WindowFlags = SDL_WINDOW_NOT_FOCUSABLE;
		final expected = Int64.make(0, 0x80000000);
		if ((flags : Int64) != expected)
			throw 'SDL_WINDOW_NOT_FOCUSABLE is ${(flags : Int64)} instead of $expected before native';
		final window = Window.create({
			title: "Window flags test",
			width: 64,
			height: 64,
			flags: flags,
			resizable: false
		});
		final received = WindowFlagsTestBindings.testLastWindowFlags();
		final expectedNative:hl.I64 = (1 : hl.I64) << 31;
		if (received != expectedNative)
			throw 'SDL_WINDOW_NOT_FOCUSABLE reached native as $received instead of $expectedNative';
		window.destroy();
	}
}
