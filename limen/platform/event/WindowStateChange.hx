package limen.platform.event;

enum abstract WindowStateChange(Int) {
	final Show = 0;
	final Hide = 1;
	final Expose = 2;
	final Move = 3;
	final Resize = 4;
	final Minimize = 5;
	final Maximize = 6;
	final Restore = 7;
	final Enter = 8;
	final Leave = 9;
	final Focus = 10;
	final Blur = 11;
	final Close = 12;
	final PixelResize = 13;
}
