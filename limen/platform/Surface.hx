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

	public static function fromBGRA(pixels, width, height) {
		return from(pixels, width, height, 32, width * 4, 0xFF0000, 0xFF00, 0xFF, 0xFF000000);
	}

	public static function from(pixels:hl.Bytes, width:Int, height:Int, depth:Int, pitch:Int, rmask:Int, gmask:Int, bmask:Int, amask:Int):Surface {
		return cast SDLBindings.surfaceFrom(pixels, width, height, depth, pitch, rmask, gmask, bmask, amask);
	}
}
