private class TestEvent {
	public static var latest:TestEvent;
	public var stopped = false;
	public var call:Void->Void;
	public function new(call:Void->Void) this.call = call;
	public static function add(call:Void->Void):TestEvent return latest = new TestEvent(call);
	public function stop():Void stopped = true;
}

private class TestGL {
	public var polls = 0;
	public var cancels = 0;
	public var status = 0;
	public function new() {}
	public function startBufferReadback(context:Dynamic, buffer:Dynamic, offset:Int, size:Int):Dynamic return 1;
	public function pollBufferReadback(request:Dynamic, data:Dynamic, offset:Int):Int {
		polls++;
		return status;
	}
	public function cancelBufferReadback(request:Dynamic):Void cancels++;
}

@:build(OpenGLReadbackBuild.build("limen/graphics/renderer/opengl/OpenGL.hx", ["cancelReadbacks", "makeCurrent", "destroy"]))
private class TestContext {
	public var readbackCancels:Array<Void->Void> = [];
	public var failed = false;
	public var handle:Dynamic = 1;
	public var window = { nativeHandle: 1 };
	public function new() {}
}

private class OpenGLBindings {
	public static var succeeds = true;
	public static var destroys = 0;
	public static function makeCurrent(window:Dynamic, handle:Dynamic):Bool return succeeds;
	public static function destroyContext(handle:Dynamic):Void destroys++;
}

private class Platform {
	public static function getError():String return "injected failure";
}

private class TestBase {
	public function dispose():Void {}
}

private class TestEngine {
	public static var current:{ driver:Dynamic };
	public static function getCurrent():{ driver:Dynamic } return current;
}

@:build(OpenGLReadbackBuild.build("h3d/impl/driver/opengl/OpenGLDriver.hx", ["readBufferBytesAsync", "dispose", "get_hasMultiIndirectCount", "set_hasMultiIndirectCount"]))
private class TestDriver extends TestBase {
	public var context = new TestContext();
	public var gl = new TestGL();
	public var readbackCancels:Array<Void->Void> = [];
	public var supportsIndirectCount = false;
	public function new() {}
	public function readBufferBytes(b:Dynamic, start:Int, count:Int, bytes:haxe.io.Bytes, offset:Int):Void {}
}

class OpenGLReadbackTest {
	static function check(value:Bool, label:String):Void {
		if (!value) throw label;
	}

	static function main():Void {
		final modern = new TestDriver();
		final legacy = new TestDriver();
		modern.supportsIndirectCount = true;

		TestEngine.current = { driver: modern };
		check(modern.get_hasMultiIndirectCount(), "modern indirect-count capability");
		TestEngine.current = { driver: legacy };
		check(!legacy.get_hasMultiIndirectCount(), "legacy indirect-count capability");
		legacy.set_hasMultiIndirectCount(true);
		legacy.set_hasMultiIndirectCount(false);
		TestEngine.current = { driver: modern };
		check(modern.get_hasMultiIndirectCount(), "indirect-count changes remain per driver");
		TestEngine.current = null;
		check(!modern.get_hasMultiIndirectCount(), "no current driver capability");
		Sys.println("Passed per-driver indirect-count capabilities");

		for (scenario in ["success", "makeCurrent failure", "poll failure", "driver shutdown", "context shutdown", "cancelled event"]) {
			OpenGLBindings.succeeds = true;
			final driver = new TestDriver();
			var callbacks = 0;
			driver.readBufferBytesAsync({ format: { strideBytes: 4 }, vertices: 4, vbuf: 1 }, 0, 4, haxe.io.Bytes.alloc(16), 0, () -> callbacks++);
			final event = TestEvent.latest;
			event.call();
			check(!event.stopped && driver.gl.polls == 1, scenario + ": pending request");

			switch (scenario) {
				case "success": driver.gl.status = 1;
				case "makeCurrent failure": OpenGLBindings.succeeds = false;
				case "poll failure": driver.gl.status = -1;
				case "driver shutdown": driver.dispose(); driver.dispose();
				case "context shutdown": driver.context.destroy(); driver.context.destroy();
				case "cancelled event": driver.readbackCancels[0]();
			}
			var threw = false;
			try event.call() catch (_:Dynamic) threw = true;
			check(threw == (scenario == "makeCurrent failure" || scenario == "poll failure"), scenario + ": error propagation");
			check(event.stopped && driver.gl.cancels == 1, scenario + ": cleanup exactly once");
			check(driver.readbackCancels.length == 0 && driver.context.readbackCancels.length == 0, scenario + ": registrations removed");
			check(callbacks == (scenario == "success" ? 1 : 0), scenario + ": callback count");
			final polls = driver.gl.polls;
			event.call();
			check(driver.gl.polls == polls && driver.gl.cancels == 1, scenario + ": stale event ignored");
			Sys.println("Passed " + scenario);
		}
	}
}
