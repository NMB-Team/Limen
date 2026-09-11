package;

import limen.platform.Platform;
import limen.platform.event.Event;
import limen.platform.event.EventType;
import limen.platform.system.FileDialog;
import limen.platform.window.Window;

class ExampleFileDialog {
	static function main() {
		Platform.init(None);

		final window = Window.create({title: "LIMEN File Dialog", width: 640, height: 360});
		var running = true;

		FileDialog.openFile(result -> {
			trace(result);
			running = false;
		}, {
			parent: window,
			allowMultiple: true,
			filters: [
				{name: "Images", pattern: "png;jpg;jpeg"},
				{name: "Text files", pattern: "txt;md"}
			]
		});

		final event = new Event();
		while (running) {
			while (Platform.pollEvent(event))
				if (event.type == EventType.Quit)
					running = false;
			Platform.delay(8);
		}

		window.destroy();
		Platform.quit();
	}
}
