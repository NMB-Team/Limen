package limen.d3d11;

import limen.d3d11.Types.Format;
import limen.d3d11.internal.D3D11Bindings;
import limen.d3d11.internal.D3D11Bindings.Dx11DriverInstance;
import limen.d3d11.Types.FeatureLevel;
import limen.d3d11.Types.PresentFlags;
import limen.Window;

class D3D11 {
	var driver:Dx11DriverInstance;

	public static function create(window:Window, format:Format, flags:DriverFlags = None, ?minimumFeatureLevel:FeatureLevel):D3D11 {
		final driver = D3D11Bindings.create(window, format, flags, minimumFeatureLevel);
		if (driver == null)
			throw "Failed to create D3D11 driver";
		return new D3D11(driver);
	}

	private function new(driver:Dx11DriverInstance) {
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
