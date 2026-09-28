package limen.platform.system.dialog;

typedef FileDialogOptions = {
	?filters:Array<FileDialogFilter>,
	?defaultLocation:String,
	?parent:limen.platform.window.Window,
	?allowMultiple:Bool
}
