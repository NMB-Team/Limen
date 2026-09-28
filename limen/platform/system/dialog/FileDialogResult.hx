package limen.platform.system.dialog;

enum FileDialogResult {
	Selected(paths:Array<String>, selectedFilter:Null<Int>);
	Cancelled;
	Failed(message:String);
}
