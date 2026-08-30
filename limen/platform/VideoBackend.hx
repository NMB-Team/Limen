package limen.platform;

enum abstract VideoBackend(Int) from Int to Int {
	final Unknown = 0;

	final Windows = 1;
	final X11 = 2;
	final Wayland = 3;
	final Cocoa = 4;

	final Android = 5;

	final KMSDRM = 6;

	final Offscreen = 7;
	final Dummy = 8;

	public function toString():String {
		return switch (this) {
			case Unknown: "Unknown";

			case Windows: "Windows";
			case X11: "X11";
			case Wayland: "Wayland";
			case Cocoa: "Cocoa";

			case Android: "Android";

			case KMSDRM: "KMSDRM";

			case Offscreen: "Offscreen";
			case Dummy: "Dummy";

			default: 'Unknown($this)';
		}
	}
}
