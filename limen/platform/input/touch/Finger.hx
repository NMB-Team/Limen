package limen.platform.input.touch;

import haxe.Int64;

/**
	A snapshot of an active finger.
	Coordinates and pressure are normalized to 0..1.
**/
typedef Finger = {id:Int64, x:Float, y:Float, pressure:Float}
