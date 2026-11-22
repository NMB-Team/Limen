package limen.platform.system;

import limen.platform.internal.SDLBindings;

class Paths {
	/**
		Application data directory with a trailing separator, or null when unavailable.
	**/
	public static function base():Null<String> {
		final path = SDLBindings.getBasePath();
		return path == null ? null : @:privateAccess String.fromUTF8(path);
	}

	/**
		Current working directory with a trailing separator, or null when unavailable.
	**/
	public static function currentDirectory():Null<String> {
		final path = SDLBindings.getCurrentDirectory();
		return path == null ? null : @:privateAccess String.fromUTF8(path);
	}

	public static function preference(organization:String, application:String):String {
		final path = @:privateAccess SDLBindings.getPrefPath(organization.toUtf8(), application.toUtf8());
		return path == null ? null : @:privateAccess String.fromUTF8(path);
	}
}
