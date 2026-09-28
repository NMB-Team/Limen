package limen.platform.system;

/**
	Describes the current power supply and battery charging state,
	as reported by System.powerState.

	System.batteryPercent provides the remaining battery percentage separately
	when available. Both values depend on information reported by the platform.
**/
enum abstract PowerState(Int) from Int to Int {
	/**
		The power state is unavailable or an error occurred while querying it.
	**/
	final Unknown = 0;

	/**
		The device is running on battery power without an external power supply.
	**/
	final OnBattery = 1;

	/**
		The device is connected to an external power supply and has no battery available.
	**/
	final NoBattery = 2;

	/**
		The device is connected to an external power supply and its battery is charging.
	**/
	final Charging = 3;

	/**
		The device is connected to an external power supply and its battery is fully charged.
	**/
	final Charged = 4;
}
