import haxe.Int64;
import limen.platform.Platform;
import limen.platform.event.Event;
import limen.platform.event.EventType;
import limen.platform.input.touch.Touch;
import limen.platform.input.touch.TouchDeviceType;
import limen.platform.input.pen.Pen;
import limen.platform.input.pen.PenDeviceType;
import limen.platform.input.pen.PenAxis;
import limen.platform.input.pen.PenInputFlags;

@:hlNative("limen")
private class InputEventsTestBindings {
	public static function testQueueInputEvents():Bool {
		return false;
	}
}

class InputEventsTest {
	static function main():Void {
		Platform.init(None);
		if (Touch.available().length != 0)
			throw "Dummy video driver should have no touch devices";
		final device = new Touch(Int64.make(0x12345678, 0x9abcdef0));
		if (device.type != TouchDeviceType.Invalid || device.name != "")
			throw "Invalid touch device query failed";
		var rejected = false;
		try {
			device.fingers();
		} catch (_:Dynamic) {
			rejected = true;
		}
		if (!rejected)
			throw "Invalid finger query should fail";
		if (Pen.deviceType(0) != PenDeviceType.Invalid)
			throw "Invalid pen device query failed";
		final event = new Event();
		while (Platform.pollEvent(event)) {}
		if (!InputEventsTestBindings.testQueueInputEvents())
			throw "Failed to queue input events";
		if (!Platform.pollEvent(event) || event.type != EventType.TouchMove)
			throw "Touch event was not delivered";
		if (event.touchId != Int64.make(0xf1234567, 0x89abcdef) || event.fingerId != Int64.make(0x12345678, 0x9abcdef0))
			throw "Touch IDs lost precision across the native boundary";
		if (event.windowId != 7 || event.touchX != 0.125 || event.touchY != 0.875 || event.touchDX != -0.0625 || event.touchDY != 0.03125 || event.pressure != 0.5)
			throw "Touch fields do not match the native layout";
		if (!Platform.pollEvent(event) || event.type != EventType.PenAxis)
			throw "Pen axis event was not delivered";
		if (event.windowId != 8 || event.penId != 0xf1234567 || event.penX != 12.25 || event.penY != 34.5 || event.penAxis != PenAxis.TiltX || event.penValue != -45.5)
			throw "Pen fields do not match the native layout";
		if (!event.penState.has(PenInputFlags.Down | PenInputFlags.EraserTip | PenInputFlags.InProximity) || event.penState.has(PenInputFlags.Button1))
			throw "Pen input flags lost bits across the native boundary";
		Platform.quit();
	}
}
