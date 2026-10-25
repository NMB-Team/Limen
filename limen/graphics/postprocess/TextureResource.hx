package limen.graphics.postprocess;

@:struct
class TextureResource {
	public var native:NativeHandle;
	public var memory:NativeHandle;
	public var view:NativeHandle;
	public var state:Int;
	public var width:Int;
	public var height:Int;
	public var format:Int;
	public var mipLevels:Int = 1;
	public var arrayLayers:Int = 1;
	public var usage:Int = 0;
	public var flags:Int = 0;

	public function new(native:NativeHandle, state:Int, width:Int = 0, height:Int = 0, format:Int = 0) {
		this.native = native;
		this.state = state;
		this.width = width;
		this.height = height;
		this.format = format;
	}
}
