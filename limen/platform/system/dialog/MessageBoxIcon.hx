package limen.platform.system.dialog;

/**
	Selects the icon and message category used by MessageBox.show().

	The icon's appearance depends on the platform's native dialog implementation.
**/
enum abstract MessageBoxIcon(Int) {
	/**
		Shows a message without requesting a specific icon.
		This is the default for MessageBox.show().
	**/
	final None = 0;

	/**
		Shows an error icon to indicate that an operation has failed.
	**/
	final Error = 0x10;

	/**
		Shows a warning icon to draw attention to a potential problem.
	**/
	final Warning = 0x20;

	/**
		Shows an information icon for a notice or general information.
	**/
	final Information = 0x40;
}
