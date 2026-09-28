package limen.platform.system;

/**
	Describes the operating system's current color theme, reported by System.theme.

	Read the theme after Platform.init(). Applications can use it to choose
	matching interface colors; it does not change the application's appearance
	automatically.
**/
enum abstract SystemTheme(Int) from Int to Int {
	/**
		The system theme is unavailable or could not be determined.
	**/
	final Unknown = 0;

	/**
		The system uses a light color theme.
	**/
	final Light = 1;

	/**
		The system uses a dark color theme.
	**/
	final Dark = 2;
}
