package limen.graphics.renderer.d3d11.internal;

import limen.graphics.renderer.d3d11.DX11Core.Dx11DriverInitFlags;
import limen.graphics.renderer.d3d11.DX11Core.FeatureLevel;
import limen.graphics.renderer.d3d11.DX11Core.Format;
import limen.graphics.renderer.d3d11.DX11Core.PresentFlags;
import limen.graphics.renderer.d3d11.resource.Resources.Resource;
import limen.platform.window.Window;

typedef Dx11DriverInstance = hl.Abstract<"dx_driver">;

@:hlNative("limen", "d3d11_")
class D3D11Bindings {
	public static var fullScreen(get, set):Bool;
	public static var minimumFeatureLevel = FeatureLevel.Level9_1;

	/**
		Setup an error handler instead of getting String exceptions:
		The first parameter is the DirectX error code
		The second parameter is the removed reason code if the first is DXGI_ERROR_DEVICE_REMOVED
		The third parameter is the line in directx.cpp sources where was triggered the error.
		Allocation methods will return null if an error handler is setup and does not raise exception.
	**/
	public static function setErrorHandler(f:Int -> Int -> Int -> Void) {}

	public static function create(win:Window, format:Format, flags:Dx11DriverInitFlags = None, ?minimumFeatureLevel:FeatureLevel) {
		return dxCreate(win.nativeHandle, format, flags, minimumFeatureLevel ?? D3D11Bindings.minimumFeatureLevel);
	}

	@:hlNative("limen", "d3d11_create_sdl")
	static function dxCreate(win:hl.Abstract<"limen_window">, format:Format, flags:Dx11DriverInitFlags, minimumFeatureLevel:FeatureLevel):Dx11DriverInstance {
		return null;
	}

	public static function disposeDriver(driver:Dx11DriverInstance) {}

	public static function resize(width:Int, height:Int, format:Format):Bool {
		return false;
	}

	public static function getBackBuffer():Resource {
		return null;
	}

	public static function present(intervals:Int, flags:PresentFlags) {}

	public static function getDeviceName() {
		return @:privateAccess String.fromUCS2(dxGetDeviceName());
	}

	@:hlNative("limen", "d3d11_get_device_name")
	static function dxGetDeviceName():hl.Bytes {
		return null;
	}

	public static function getSupportedVersion():Float {
		return 0.;
	}

	public static function debugPrint(v:Dynamic) {
		dxDebugPrint(@:privateAccess Std.string(v).bytes);
	}

	@:hlNative("limen", "d3d11_debug_print")
	static function dxDebugPrint(str:hl.Bytes) {}

	static function get_fullScreen()
		return getFullscreenState();

	static function set_fullScreen(b) {
		if (!setFullscreenState(b))
			return false;
		return b;
	}

	static function getFullscreenState() {
		return false;
	}

	static function setFullscreenState(b:Bool) {
		return false;
	}
}
