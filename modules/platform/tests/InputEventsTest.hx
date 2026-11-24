import haxe.Int64;
import haxe.atomic.AtomicInt;
import limen.Platform;
import limen.Event;
import limen.EventType;
import limen.Window;
import limen.input.Touch;
import limen.input.TouchDeviceType;
import limen.input.Pen;
import limen.input.PenDeviceType;
import limen.input.PenAxis as Axis;
import limen.input.PenInputFlags;
import sys.thread.Thread;

@:hlNative("limen")
private class InputEventsTestBindings {
	public static function testQueueInputEvents():Bool {
		return false;
	}

	public static function testPushMotion(window:Int, count:Int, start:Int):Int {
		return 0;
	}

	public static function testPushText(window:Int):Bool {
		return false;
	}

	public static function testHotplug():Int {
		return 0;
	}
}

class InputEventsTest {
	static function main():Void {
		Platform.init(None);

		if (Platform.videoBackend == Dummy && Touch.available().length != 0)
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
		if (event.windowId != 8 || event.penId != 0xf1234567 || event.penX != 12.25 || event.penY != 34.5 || event.penAxis != Axis.TiltX || event.penValue != -45.5)
			throw "Pen fields do not match the native layout";
		if (!event.penState.has(PenInputFlags.Down | PenInputFlags.EraserTip | PenInputFlags.InProximity) || event.penState.has(PenInputFlags.Button1))
			throw "Pen input flags lost bits across the native boundary";

		checkQueue(event);
	}

	static function checkQueue(event:Event):Void {
		final first = Window.create({title: "First event test window", width: 64, height: 64, visible: false});
		final second = Window.create({title: "Second event test window", width: 64, height: 64, visible: false});
		final firstId = first.id;
		final secondId = second.id;
		while (Platform.pollEvent(event)) {}

		final burst = 9000;
		if (InputEventsTestBindings.testPushMotion(firstId, burst, 0) != burst)
			throw "Could not enqueue overflow workload";
		var seen = 0;
		while (Platform.pollEvent(event)) {
			if (event.type != MouseMove || event.windowId != firstId)
				continue;
			if (event.mouseX != seen++ || event.mouseXRel != -1 || event.mouseYRel != 2 || event.timestamp == 0)
				throw "Overflow changed motion order, fractional conversion or timestamp";
		}
		if (seen != burst)
			throw "Overflow lost motion events";

		final watched:Array<Event> = [];
		final watch = (value:Event) -> {
			if (value.type == TextInput || value.type == DropText)
				watched.push(value);
		};
		Platform.addEventWatchListener(watch);
		if (!InputEventsTestBindings.testPushText(secondId) || !Platform.isTextInputShown() || Platform.isTextInputShown())
			throw "IME composition signal was lost or did not reset";
		Platform.removeEventWatchListener(watch);
		if (watched.length != 2)
			throw "Event Watch lost text or drop events";

		var input:hl.Bytes = null;
		var drop:hl.Bytes = null;
		var textTimestamp:Int64 = 0;
		var dropTimestamp:Int64 = 0;
		while (Platform.pollEvent(event)) {
			if (event.windowId != secondId)
				continue;
			switch (event.type) {
				case TextInput:
					input = event.inputChar;
					textTimestamp = event.timestamp;
				case DropText:
					drop = event.dropFile;
					dropTimestamp = event.timestamp;
				default:
			}
		}
		hl.Gc.major();
		if (input == null || drop == null || (@:privateAccess String.fromUCS2(input)) != "café" ||
			(@:privateAccess String.fromUTF8(drop)) != "café")
			throw "Polling did not preserve text and drop payload lifetimes";
		if (watched[0].inputChar == input || watched[1].dropFile == drop ||
			textTimestamp == 0 || dropTimestamp < textTimestamp ||
			watched[0].timestamp != textTimestamp || watched[1].timestamp != dropTimestamp ||
			(@:privateAccess String.fromUCS2(watched[0].inputChar)) != "café" ||
			(@:privateAccess String.fromUTF8(watched[1].dropFile)) != "café")
			throw "Event Watch did not retain independent text and drop payloads";

		final controller = InputEventsTestBindings.testHotplug();
		if (controller == 0)
			throw "Could not attach and detach virtual controller";
		var hotplug:Array<EventType> = [];
		while (Platform.pollEvent(event)) {
			if (event.reference == controller)
				hotplug.push(event.type);
		}
		if (hotplug.indexOf(JoystickAdded) < 0 || hotplug.indexOf(JoystickAdded) >= hotplug.indexOf(JoystickRemoved) ||
			hotplug.indexOf(GamepadAdded) < 0 || hotplug.indexOf(GamepadAdded) >= hotplug.indexOf(GamepadRemoved))
			throw "Controller hotplug was lost or reordered";

		checkConcurrent(event, firstId, secondId);
		checkListenerErrors(event, firstId);
		checkReentrancy(event, firstId);

		Platform.setMouseMotionCoalescing(true);
		if (InputEventsTestBindings.testPushMotion(firstId, 2, 10) != 2 ||
			InputEventsTestBindings.testPushMotion(secondId, 2, 20) != 2)
			throw "Could not queue coalescing workload";
		if (!Platform.pollEvent(event) || event.windowId != firstId || event.mouseX != 11 ||
			event.mouseXRel != -2 || event.mouseYRel != 4)
			throw "Coalescing changed first window motion";
		if (!Platform.pollEvent(event) || event.windowId != secondId || event.mouseX != 21)
			throw "Coalescing crossed a window boundary";

		final pendingFailure = (value:Event) -> {
			if (value.type == DropText && value.windowId == secondId)
				throw new haxe.Exception("pending at shutdown");
		};
		Platform.addEventWatchListener(pendingFailure);
		if (!InputEventsTestBindings.testPushText(secondId))
			throw "Could not leave pending text for shutdown";
		Platform.removeEventWatchListener(pendingFailure);
		first.destroy();
		second.destroy();
		Platform.quit();
		Platform.init(None);
		while (Platform.pollEvent(event)) {
			if (event.type == TextInput || event.type == DropText)
				throw "Shutdown leaked events into the next session";
		}
		Platform.quit();
	}

	static function checkListenerErrors(event:Event, window:Int):Void {
		final exception = new haxe.Exception("original exception");
		final failures:Array<Dynamic> = ["listener error", null, exception];
		final listeners:Array<Event -> Void> = [];
		for (failure in failures) {
			final listener = (value:Event) -> {
				if (value.type == MouseMove && value.windowId == window)
					throw failure;
			};
			listeners.push(listener);
			Platform.addEventWatchListener(listener);
		}
		var called = false;
		final last = (value:Event) -> {
			if (value.type == MouseMove && value.windowId == window)
				called = true;
		};
		Platform.addEventWatchListener(last);

		if (InputEventsTestBindings.testPushMotion(window, 1, 20) != 1 || !called)
			throw new haxe.Exception("A failing listener interrupted watch delivery");
		for (listener in listeners)
			Platform.removeEventWatchListener(listener);
		Platform.removeEventWatchListener(last);

		for (failure in failures) {
			var caught = false;
			try {
				Platform.pollEvent(event);
			} catch (error:Dynamic) {
				if (error != failure)
					throw new haxe.Exception("Listener exception identity or FIFO order changed");
				caught = true;
			}
			if (!caught)
				throw new haxe.Exception("A listener exception was suppressed");
		}
		if (!Platform.pollEvent(event) || event.windowId != window || event.mouseX != 20)
			throw new haxe.Exception("Listener exceptions lost the deferred event");
		while (Platform.pollEvent(event)) {}
	}

	static function checkReentrancy(event:Event, window:Int):Void {
		final nested = new Event();
		var nestedCalls = 0;
		final next = (value:Event) -> {
			if (value.type == MouseMove && value.windowId == window && value.mouseX == 31)
				nestedCalls++;
		};
		var first:Event -> Void = null;
		first = (value:Event) -> {
			if (value.type != MouseMove || value.windowId != window || value.mouseX != 30)
				return;

			Platform.removeEventWatchListener(first);
			Platform.addEventWatchListener(next);
			if (InputEventsTestBindings.testPushMotion(window, 1, 31) != 1 || nestedCalls != 1)
				throw new haxe.Exception("Nested dispatch did not use the updated listener snapshot");
			if (!Platform.pollEvent(nested) || nested.mouseX != 30 || nested.timestamp != value.timestamp)
				throw new haxe.Exception("Nested polling reordered the outer event or changed its timestamp");

			Platform.quit();
		};
		Platform.addEventWatchListener(first);
		if (InputEventsTestBindings.testPushMotion(window, 1, 30) != 1)
			throw new haxe.Exception("Could not queue the reentrancy workload");
		Platform.removeEventWatchListener(next);

		var rejected = false;
		try {
			Platform.pollEvent(event);
		} catch (error:haxe.Exception) {
			if (error.message.indexOf("Cannot shut down LIMEN from an Event Watch listener") == -1)
				throw error;
			rejected = true;
		}
		if (!rejected || !Platform.pollEvent(event) || event.windowId != window ||
			event.mouseX != 31 || event.timestamp < nested.timestamp)
			throw new haxe.Exception("Reentrant shutdown damaged the pending queue");
		while (Platform.pollEvent(event)) {}
	}

	static function checkConcurrent(event:Event, first:Int, second:Int):Void {
		final count = 1400;
		final main = Thread.current();
		final watched = new AtomicInt(0);
		final onProducer = (value:Event) -> {
			if (value.type != MouseMove || (value.windowId != first && value.windowId != second))
				return;
			if (Thread.current() == main)
				throw "Event Watch ran on the consumer";
			watched.add(1);
			value.mouseX = -1;
		};
		Platform.addEventWatchListener(onProducer);
		for (id in [first, second]) {
			Thread.create(() -> main.sendMessage(InputEventsTestBindings.testPushMotion(id, count, 0)));
		}

		var firstCount = 0;
		var secondCount = 0;
		var firstTimestamp:Int64 = 0;
		var secondTimestamp:Int64 = 0;
		final deadline = Sys.time() + 10;
		while (firstCount + secondCount < count * 2 && Sys.time() < deadline) {
			if (!Platform.pollEvent(event)) {
				Sys.sleep(0.001);
				continue;
			}
			if (event.type != MouseMove)
				continue;
			if (event.windowId == first) {
				if (event.mouseX != firstCount++ || event.timestamp == 0 || event.timestamp < firstTimestamp)
					throw new haxe.Exception("First producer's event was reordered or overwritten");
				firstTimestamp = event.timestamp;
			}
			if (event.windowId == second) {
				if (event.mouseX != secondCount++ || event.timestamp == 0 || event.timestamp < secondTimestamp)
					throw new haxe.Exception("Second producer's event was reordered or overwritten");
				secondTimestamp = event.timestamp;
			}
		}
		for (_ in 0...2) {
			if (Thread.readMessage(true) != count)
				throw "A concurrent producer could not push all events";
		}
		Platform.removeEventWatchListener(onProducer);
		if (firstCount != count || secondCount != count || watched.load() != count * 2)
			throw "Concurrent polling or Event Watch lost events";
	}
}
