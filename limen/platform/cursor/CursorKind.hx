package limen.platform.cursor;

enum abstract CursorKind(Int) {
	final Arrow = 0;
	final IBeam = 1;
	final Wait = 2;
	final CrossHair = 3;
	final WaitArrow = 4;
	final SizeNWSE = 5;
	final SizeNESW = 6;
	final SizeWE = 7;
	final SizeNS = 8;
	final SizeALL = 9;
	final No = 10;
	final Hand = 11;
}
