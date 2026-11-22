package limen.system.dialog;

typedef FileDialogOptions = {
	?filters:Array<FileDialogFilter>,
	?defaultLocation:String,
	?parent:limen.Window,
	?allowMultiple:Bool
}
