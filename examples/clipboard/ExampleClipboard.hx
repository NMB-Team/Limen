package;

import haxe.io.Bytes;

import limen.platform.Platform;
import limen.platform.system.Clipboard;

class ExampleClipboard {
	static function main() {
		Platform.init(None);

		try {
			final mimeType = "application/x-limen-clipboard-example";
			final original = Bytes.ofHex("00017f80feff004c494d454e");
			if (!Clipboard.setData(mimeType, original))
				throw "Could not set clipboard data";
			if (!Clipboard.hasData(mimeType))
				throw "Clipboard data is unavailable";

			final result = Clipboard.getData(mimeType);
			if (result == null || result.compare(original) != 0)
				throw "Clipboard data did not round-trip";
			if (!Clipboard.mimeTypes().contains(mimeType))
				throw "Clipboard MIME type is missing";

			trace("Binary clipboard round-trip passed");
		} catch (error:Dynamic) {
			Platform.quit();
			throw error;
		}

		Platform.quit();
	}
}
