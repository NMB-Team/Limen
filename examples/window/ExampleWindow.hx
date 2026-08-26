package;

import limen.platform.Platform;
import limen.platform.window.Window;
import limen.platform.display.Display;
import limen.platform.event.Event;
import limen.platform.event.EventType;
import limen.platform.event.WindowStateChange;

class ExampleWindow {
	static function main() {
		// limen can be used without graphics API and working just with one hdll. that's cool
		Platform.init(None);

		Sys.println("LIMEN Window example");
		Sys.println('Keyboard layout: ${Platform.detectKeyboardLayout()}');

		// show detected displays
		for (display in Display.all()) {
			Sys.println('Display "${display.name}": ${display.width}x${display.height} at ${display.x},${display.y}');
		}

		// create a regular resizable window
		final window = Window.create({
			title: "LIMEN Example",
			width: 800,
			height: 500,
			resizable: true
		});

		window.setMinSize(320, 240);

		// supported platforms may use a native dark title bar, but sdl adapt it by system prefer
		window.setDarkMode(true);

		final event = new Event();
		var running = true;

		while (running) {
			while (Platform.pollEvent(event)) {
				switch (event.type) {
					case EventType.Quit:
						running = false;

					case EventType.WindowState:
						switch (event.state) {
							case WindowStateChange.Close:
								running = false;

							case WindowStateChange.Resize:
								Sys.println('Window resized: ${window.width}x${window.height}');

							default:
						}

					case EventType.MouseMove:
						// make mouse input immediately visible without needing a renderer
						window.title = 'LIMEN Example | mouse ${event.mouseX}, ${event.mouseY}';

					case EventType.MouseDown:
						Sys.println('Mouse button ${event.button} at ${event.mouseX}, ${event.mouseY}');

					case EventType.MouseWheel:
						Sys.println('Mouse wheel: ${event.wheelDelta}');

					case EventType.KeyDown:
						Sys.println('Key down: keyCode=${event.keyCode}, scanCode=${event.scanCode}');

					case EventType.KeyUp:
						Sys.println('Key up: keyCode=${event.keyCode}');

					default:
				}
			}

			// don't busy-loop at 100% CPU
			Platform.delay(8);
		}

		window.destroy();
		Platform.quit();

		Sys.println("Bye bye!");
	}
}
