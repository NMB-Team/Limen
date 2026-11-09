package limen.platform;

import limen.platform.internal.SDLBindings;
import limen.platform.internal.types.SurfacePtr;

abstract Surface(SurfacePtr) {
	public inline function free() {
		destroy();
	}

	public inline function destroy() {
		SDLBindings.freeSurface(this);
		this = null;
	}

	public function addAlternateImage(image:Surface):Void {
		if (!SDLBindings.surfaceAddAlternate(this, cast image))
			throw "Failed to add alternate surface image";
	}

	public static function fromICO(bytes:haxe.io.Bytes):Surface {
		if (bytes.length < 6 || bytes.getUInt16(0) != 0 || bytes.getUInt16(2) != 1)
			throw "Invalid ICO header";

		var count = bytes.getUInt16(4);
		var directoryEnd = 6 + count * 16;
		if (count == 0 || directoryEnd > bytes.length)
			throw "Invalid ICO directory";

		var result:Surface = cast null;
		try {
			for (i in 0...count) {
				var entry = 6 + i * 16;
				var size = bytes.getInt32(entry + 8);
				var offset = bytes.getInt32(entry + 12);
				var width = bytes.get(entry) == 0 ? 256 : bytes.get(entry);
				var height = bytes.get(entry + 1) == 0 ? 256 : bytes.get(entry + 1);

				if (offset < directoryEnd || size < 4 || offset > bytes.length - size)
					throw "Invalid ICO image range";

				var frame = bytes.sub(offset, size);
				var pixels:hl.Bytes;
				var redMask:Int;
				var blueMask:Int;

				if (frame.getInt32(0) == 0x474E5089) {
					var png = new format.png.Reader(new haxe.io.BytesInput(frame)).read();
					var header = format.png.Tools.getHeader(png);
					if (header.width <= 0 || header.height <= 0 || header.width > 16384 || header.height > 16384)
						throw "Invalid ICO PNG dimensions";

					width = header.width;
					height = header.height;

					pixels = format.png.Tools.extract32(png).getData();
					redMask = 0xFF0000;
					blueMask = 0xFF;
				} else {
					if (size < 40 || frame.getInt32(0) != 40 || frame.getInt32(4) != width
						|| frame.getInt32(8) != height * 2 || frame.getUInt16(12) != 1 || frame.getInt32(16) != 0)
						throw "Unsupported ICO bitmap header";

					var bits = frame.getUInt16(14);
					if (bits != 1 && bits != 4 && bits != 8 && bits != 24 && bits != 32)
						throw "Unsupported ICO bitmap depth";

					var colors = frame.getInt32(32);
					if (colors < 0 || colors > 256)
						throw "Invalid ICO palette";
					if (colors == 0 && bits <= 8)
						colors = 1 << bits;

					var colorSize = ((width * bits + 31) >> 5) * 4 * height;
					var maskSize = ((width + 31) >> 5) * 4 * height;
					if (40 + colors * 4 + colorSize + maskSize > size)
						throw "Truncated ICO bitmap";

					// the format reader expects image data directly after the directory
					var single = haxe.io.Bytes.alloc(22 + size);
					single.setUInt16(2, 1);
					single.setUInt16(4, 1);
					single.blit(6, bytes, entry, 16);
					single.setInt32(18, 22);
					single.blit(22, frame, 0, size);

					var ico = new format.ico.Reader(new haxe.io.BytesInput(single)).read();
					pixels = switch (ico.datas[0]) {
						case DIB(bitmap): format.ico.Tools.extract(bitmap);
						case PNG(_): throw "Invalid ICO bitmap";
					};
					redMask = 0xFF;
					blueMask = 0xFF0000;
				}

				var image = from(pixels, width, height, 32, width * 4, redMask, 0xFF00, blueMask, 0xFF000000);
				if (image == null)
					throw "Failed to create ICO surface";

				try {
					if (result == null) {
						// alternate images and the returned surface must own their pixel storage
						result = cast SDLBindings.surfaceDuplicate(cast image);
						if (result == null)
							throw "Failed to copy ICO surface";
					} else {
						result.addAlternateImage(image);
					}
				} catch (error:Dynamic) {
					image.free();
					throw error;
				}
				image.free();
			}
		} catch (error:Dynamic) {
			if (result != null)
				result.free();
			throw error;
		}

		return result;
	}

	public static function fromBGRA(pixels, width, height) {
		return from(pixels, width, height, 32, width * 4, 0xFF0000, 0xFF00, 0xFF, 0xFF000000);
	}

	public static function from(pixels:hl.Bytes, width:Int, height:Int, depth:Int, pitch:Int, rmask:Int, gmask:Int, bmask:Int, amask:Int):Surface {
		return cast SDLBindings.surfaceFrom(pixels, width, height, depth, pitch, rmask, gmask, bmask, amask);
	}
}
