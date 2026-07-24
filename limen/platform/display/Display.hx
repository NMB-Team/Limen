package limen.platform.display;

import limen.platform.internal.SdlBindings;

abstract DisplayId(Int) from Int to Int {}

typedef DisplayInfo = {
	var id:DisplayId;
	var name:String;
	var x:Int;
	var y:Int;
	var width:Int;
	var height:Int;
}

class Display {
	public static function all():Array<DisplayInfo> {
		final displays = SdlBindings.getDisplays();
		if (displays == null)
			return [];
		return [
			for (display in displays)
				@:privateAccess
				{
					id: display.handle,
					name: String.fromUTF8(display.name),
					x: display.left,
					y: display.top,
					width: Std.int(display.right - display.left),
					height: Std.int(display.bottom - display.top)
				}
		];
	}

	public static function modes(display:DisplayId):Array<DisplayMode> {
		final modes = SdlBindings.getDisplayModes(display);
		return modes == null ? [] : [for (mode in modes) mode];
	}

	public static function currentMode(display:DisplayId, desktop:Bool = false):Null<DisplayMode> {
		return SdlBindings.getCurrentDisplayMode(display, desktop);
	}
}
