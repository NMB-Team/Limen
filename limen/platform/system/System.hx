package limen.platform.system;

import limen.platform.internal.SDLBindings;

/**
	System information. Read power and theme properties on the main thread.
**/
class System {
	public static var powerState(get, never):PowerState;

	/**
		Battery percentage from 0 to 100, or null when unavailable.
	**/
	public static var batteryPercent(get, never):Null<Int>;

	/**
		Current theme after Platform.init(), or Unknown when unavailable.
	**/
	public static var theme(get, never):SystemTheme;

	/**
		Platform name, or "Unknown" when unavailable.
	**/
	public static var platform(get, never):String;

	@:noCompletion
	static function get_powerState():PowerState {
		return switch (SDLBindings.getPowerState()) {
			case PowerState.OnBattery: OnBattery;
			case PowerState.NoBattery: NoBattery;
			case PowerState.Charging: Charging;
			case PowerState.Charged: Charged;
			default: Unknown;
		}
	}

	@:noCompletion
	static function get_batteryPercent():Null<Int> {
		final percent = SDLBindings.getBatteryPercent();
		return percent < 0 || percent > 100 ? null : percent;
	}

	@:noCompletion
	static function get_theme():SystemTheme {
		return switch (SDLBindings.getSystemTheme()) {
			case SystemTheme.Light: Light;
			case SystemTheme.Dark: Dark;
			default: Unknown;
		}
	}

	@:noCompletion
	static function get_platform():String {
		final value = SDLBindings.getPlatform();
		return value == null ? "Unknown" : @:privateAccess String.fromUTF8(value);
	}
}
