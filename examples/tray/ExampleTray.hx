package;

import haxe.io.Bytes;

import limen.platform.Platform;
import limen.platform.Surface;
import limen.platform.event.Event;
import limen.platform.system.tray.Tray;

class ExampleTray {
	static function main() {
		Platform.init(None);

		try {
			final pixels = Bytes.alloc(32 * 32 * 4);
			for (index in 0...32 * 32) {
				pixels.set(index * 4, 0xD0);
				pixels.set(index * 4 + 1, 0x90);
				pixels.set(index * 4 + 2, 0x30);
				pixels.set(index * 4 + 3, 0xFF);
			}

			var icon = Surface.fromBGRA(pixels.getData(), 32, 32);
			final tray = Tray.create(icon, "LIMEN Tray example");
			icon.destroy();

			var running = true;
			final menu = tray.createMenu();
			menu.add("Open", () -> trace("Open selected"));
			menu.addCheck("Enabled", true, value -> trace('Enabled: $value'));
			menu.addSubmenu("More").add("About", () -> trace("LIMEN Tray example"));
			menu.addSeparator();
			menu.add("Quit", () -> running = false);

			final event = new Event();
			while (running) {
				while (Platform.pollEvent(event))
					if (event.type == Quit)
						running = false;

				Platform.delay(16);
			}
			tray.destroy();
		} catch (error:Dynamic) {
			Platform.quit();
			throw error;
		}

		Platform.quit();
	}
}
