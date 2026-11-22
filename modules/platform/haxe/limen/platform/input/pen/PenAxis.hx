package limen.platform.input.pen;

/**
	Axes reported by PenAxis events.
	Devices may report only a subset.
**/
enum abstract PenAxis(Int) from Int to Int {
	/**
		Normalized tip pressure, 0..1.
	**/
	final Pressure = 0;

	/**
		Horizontal tilt in degrees, -90..90.
	**/
	final TiltX = 1;

	/**
		Vertical tilt in degrees, -90..90.
	**/
	final TiltY = 2;

	/**
		Normalized distance from the surface, 0..1.
	**/
	final Distance = 3;

	/**
		Barrel rotation in degrees, -180..179.9.
	**/
	final Rotation = 4;

	/**
		Normalized slider position, 0..1.
	**/
	final Slider = 5;

	/**
		Pressure from squeezing the pen barrel.
	**/
	final TangentialPressure = 6;
}
