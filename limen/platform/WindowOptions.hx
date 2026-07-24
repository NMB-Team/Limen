package limen.platform;

typedef WindowOptions = {
	var title:String;
	var width:Int;
	var height:Int;
	@:optional var x:Int;
	@:optional var y:Int;
	@:optional var flags:Int;
	@:optional var resizable:Bool;
	@:optional var visible:Bool;
}
