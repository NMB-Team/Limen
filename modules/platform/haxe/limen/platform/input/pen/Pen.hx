package limen.platform.input.pen;

import limen.platform.internal.SDLBindings;

/**
	Pens are identified by Event.penId when SDL reports proximity or input.
**/
class Pen {
	public static inline function deviceType(id:Int):PenDeviceType {
		return SDLBindings.getPenDeviceType(id);
	}
}
