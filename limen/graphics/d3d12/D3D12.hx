package limen.graphics.d3d12;

import limen.graphics.d3d12.DX12Core.DxgiFormat;
import limen.graphics.d3d12.internal.D3D12Bindings;
import limen.graphics.d3d12.internal.D3D12Bindings.Dx12DriverInitFlags;
import limen.graphics.d3d12.internal.D3D12Bindings.Dx12DriverInstance;
import limen.platform.Window;

class D3D12 {
	var driver:Dx12DriverInstance;

	public static function create(window:Window, flags:Dx12DriverInitFlags, ?deviceName:String):D3D12 {
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

	public inline function resize(width:Int, height:Int, bufferCount:Int, format:DxgiFormat):Void {
		D3D12Bindings.resize(width, height, bufferCount, format);
	}

	public inline function present(vsync:Bool):Void {
		D3D12Bindings.present(vsync);
	}

	public inline function suspend():Void {
		D3D12Bindings.suspend();
	}

	public inline function resume():Void {
		D3D12Bindings.resume();
	}

	public function destroy():Void {
		if (driver == null)
			return;
		D3D12Bindings.disposeDriver(driver);
		driver = null;
	}
}
