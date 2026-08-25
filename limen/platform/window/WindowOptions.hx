package limen.platform.window;

typedef WindowOptions = {
	var title:String;
	var width:Int;
	var height:Int;
	var ?x:Int;
	var ?y:Int;
	var ?flags:WindowFlags;
	var ?resizable:Bool;
	var ?visible:Bool;
}
