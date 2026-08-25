package limen.graphics.d3d11;

import limen.graphics.d3d11.DX11Core.Format;
import limen.graphics.d3d11.internal.D3D11Bindings;
import limen.graphics.d3d11.internal.D3D11Bindings.Dx11DriverInitFlags;
import limen.graphics.d3d11.internal.D3D11Bindings.Dx11DriverInstance;
import limen.graphics.d3d11.internal.D3D11Bindings.FeatureLevel;
import limen.graphics.d3d11.internal.D3D11Bindings.PresentFlags;
import limen.platform.window.Window;

class D3D11 {
	var driver:Dx11DriverInstance;

	public static function create(window:Window, format:Format, flags:Dx11DriverInitFlags = None, ?minimumFeatureLevel:FeatureLevel):D3D11 {
		final driver = D3D11Bindings.create(window, format, flags, minimumFeatureLevel);
		if (driver == null)
			throw "Failed to create D3D11 driver";
		return new D3D11(driver);
	}

	function new(driver:Dx11DriverInstance) {
		this.driver = driver;
	}

	public inline function resize(width:Int, height:Int, format:Format):Bool {
		return D3D11Bindings.resize(width, height, format);
	}

	public inline function present(intervals:Int, flags:PresentFlags):Void {
		D3D11Bindings.present(intervals, flags);
	}

	public function destroy():Void {
		if (driver == null)
			return;
		D3D11Bindings.disposeDriver(driver);
		driver = null;
	}
}
