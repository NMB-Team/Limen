package limen.system.dialog;

enum FileDialogResult {
	Selected(paths:Array<String>, selectedFilter:Null<Int>);
	Cancelled;
	Failed(message:String);
}
