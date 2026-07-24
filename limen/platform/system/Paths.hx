package limen.platform.system;

import limen.platform.internal.SdlBindings;

class Paths {
	public static function preference(organization:String, application:String):String {
		final path = @:privateAccess SdlBindings.getPrefPath(organization.toUtf8(), application.toUtf8());
		return path == null ? null : @:privateAccess String.fromUTF8(path);
	}
}
