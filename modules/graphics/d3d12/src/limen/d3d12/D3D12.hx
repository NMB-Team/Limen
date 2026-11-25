package limen.d3d12;

import limen.d3d12.Types.DxgiFormat;
import limen.d3d12.internal.D3D12Bindings.Dx12Feature;
import limen.d3d12.command.Commands.CommandQueue;
import limen.d3d12.internal.D3D12Bindings;
import limen.d3d12.internal.D3D12Bindings.Dx12DriverInstance;
import limen.Window;

class D3D12 {
	var driver:Dx12DriverInstance;

	public static function create(window:Window, flags:DriverFlags = None, ?deviceName:String):D3D12 {
		final driver = D3D12Bindings.create(window, flags, deviceName);
		if (driver == null)
			throw "Failed to create D3D12 driver";
		return new D3D12(driver);
	}

	public static function setGpuCrashHandler(handler:(name:hl.Bytes, bytes:hl.Bytes, size:Int, lastFile:Bool) -> Void):Void {
		D3D12Bindings.setGpuCrashHandler(handler);
	}

	function new(driver:Dx12DriverInstance) {
		this.driver = driver;
	}

	public inline function resize(directQueue:CommandQueue, width:Int, height:Int, bufferCount:Int, format:DxgiFormat):Void {
		D3D12Bindings.resize(directQueue, width, height, bufferCount, format);
	}

	public inline function checkFeatureSupport(feature:Dx12Feature, data:hl.Bytes, dataSize:Int):Bool {
		return D3D12Bindings.checkFeatureSupport(feature, data, dataSize);
	}

	public function destroy():Void {
		if (driver == null)
			return;
		D3D12Bindings.disposeDriver(driver);
		driver = null;
	}
}
