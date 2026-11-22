package limen.platform.input.pen;

/**
	A combination of pen input states reported in Event.penState.

	Several flags can be set at once. Use has() to check individual flags or
	combine flags with `|` to check that all of them are present.
	A pen can be in proximity and report movement without touching the surface.
**/
enum abstract PenInputFlags(Int) from Int to Int {
	/**
		No pen input flags are set.
	**/
	final None = 0;

	/**
		The pen tip is pressed against the surface.
	**/
	final Down = 1 << 0;

	/**
		The pen's first button is pressed.
	**/
	final Button1 = 1 << 1;

	/**
		The pen's second button is pressed.
	**/
	final Button2 = 1 << 2;

	/**
		The pen's third button is pressed.
	**/
	final Button3 = 1 << 3;

	/**
		The pen's fourth button is pressed.
	**/
	final Button4 = 1 << 4;

	/**
		The pen's fifth button is pressed.
	**/
	final Button5 = 1 << 5;

	/**
		The eraser tip is being used instead of the drawing tip.

		This identifies the active tip; Down indicates whether it touches the surface.
	**/
	final EraserTip = 1 << 30;

	/**
		The pen is close enough to the device to be detected, including while hovering.
	**/
	final InProximity = 1 << 31;

	@:op(A | B) static function or(a:PenInputFlags, b:PenInputFlags):PenInputFlags;

	/**
		Returns whether every bit in flag is set in this state.

		Passing None always returns true. Compare the state with None to check
		whether no flags are set.
	**/
	public inline function has(flag:PenInputFlags):Bool {
		return (this & flag) == flag;
	}
}
