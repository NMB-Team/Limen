package limen.graphics.d3d11.internal;

import limen.graphics.d3d11.DX11Core.Format;
import limen.graphics.d3d11.DX11Core.Pointer;
import limen.graphics.d3d11.DX11Core.Resource;
import limen.graphics.d3d11.DX11Core.ResourceAccess;
import limen.graphics.d3d11.DX11Core.ResourceBind;
import limen.graphics.d3d11.DX11Core.ResourceMisc;
import limen.graphics.d3d11.DX11Core.ResourceUsage;
import limen.graphics.d3d11.DX11Resources.RenderTargetDesc;
import limen.graphics.d3d11.DX11Resources.RenderTargetView;
import limen.graphics.d3d11.DX11Resources.ShaderResourceView;
import limen.graphics.d3d11.DX11Resources.ShaderResourceViewDesc;
import limen.graphics.d3d11.DX11Resources.Texture2dDesc;
import limen.graphics.d3d11.DX11Shaders.DisassembleFlags;
import limen.graphics.d3d11.DX11Shaders.Layout;
import limen.graphics.d3d11.DX11Shaders.LayoutElement;
import limen.graphics.d3d11.DX11Shaders.PrimitiveTopology;
import limen.graphics.d3d11.DX11Shaders.Shader;
import limen.graphics.d3d11.DX11Shaders.ShaderFlags;
import limen.graphics.d3d11.DX11States.BlendState;
import limen.graphics.d3d11.DX11States.DepthStencilDesc;
import limen.graphics.d3d11.DX11States.DepthStencilState;
import limen.graphics.d3d11.DX11States.DepthStencilView;
import limen.graphics.d3d11.DX11States.RasterizerDesc;
import limen.graphics.d3d11.DX11States.RasterState;
import limen.graphics.d3d11.DX11States.RenderTargetBlendDesc;
import limen.graphics.d3d11.DX11States.SamplerDesc;
import limen.graphics.d3d11.DX11States.SamplerState;

import haxe.Int64;

import limen.platform.window.Window;

#if (!gfx_dx12 || gfx_dx11)
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
		return dxCreate(@:privateAccess win.win, format, flags, minimumFeatureLevel ?? D3D11Bindings.minimumFeatureLevel);
	}

	public static function disposeDriver(driver:Dx11DriverInstance) {}

	public static function resize(width:Int, height:Int, format:Format):Bool {
		return false;
	}

	public static function getBackBuffer():Resource {
		return null;
	}

	public static function createRenderTargetView(r:Resource, ?desc:RenderTargetDesc):RenderTargetView {
		return dxCreateRenderTargetView(r, desc);
	}

	public static function omSetRenderTargets(count:Int, arr:hl.Ref<RenderTargetView>, ?depth:DepthStencilView) {}

	public static function createRasterizerState(desc:RasterizerDesc):RasterState {
		return dxCreateRasterizerState(desc);
	}

	public static function rsSetState(r:RasterState) {}

	public static function rsSetViewports(count:Int, bytes:hl.BytesAccess<hl.F32>) {}

	public static function rsSetScissorRects(count:Int, rects:hl.BytesAccess<Int>) {}

	public static function clearColor(rt:RenderTargetView, r:Float, g:Float, b:Float, a:Float) {}

	public static function present(intervals:Int, flags:PresentFlags) {}

	public static function getDeviceName() {
		return @:privateAccess String.fromUCS2(dxGetDeviceName());
	}

	public static function getSupportedVersion():Float {
		return 0.;
	}

	public static function compileShader(data:String, source:String, entryPoint:String, target:String, flags:ShaderFlags):haxe.io.Bytes @:privateAccess {
		final isError = false, size = 0;
		final out = dxCompileShader(data.toUtf8(), data.length, source.toUtf8(), entryPoint.toUtf8(), target.toUtf8(), flags, isError, size);
		if (isError)
			throw String.fromUTF8(out);
		#if (haxe_ver < 4)
		throw "Haxe 4.x required";
		#else
		return out.toBytes(size);
		#end
	}

	public static function disassembleShader(data:haxe.io.Bytes, flags:DisassembleFlags, ?comments:String):String {
		var size = 0;
		final out = dxDisassembleShader(data, data.length, flags, comments == null ? null : @:privateAccess comments.toUtf8(), size);
		if (out == null)
			throw "Could not disassemble shader";
		return @:privateAccess String.fromUTF8(out);
	}

	public static function releasePointer(p:Pointer) {}

	public static function createVertexShader(bytes:haxe.io.Bytes) {
		return dxCreateVertexShader(bytes, bytes.length);
	}

	public static function createPixelShader(bytes:haxe.io.Bytes) {
		return dxCreatePixelShader(bytes, bytes.length);
	}

	public static function drawIndexed(indexCount:Int, startIndex:Int, baseVertex:Int):Void {}

	public static function drawIndexedInstanced(indexCountPerInstance:Int, instanceCount:Int, startIndexLocation:Int, baseVertexLocation:Int, startInstanceLocation:Int) {}

	public static function drawIndexedInstancedIndirect(buffer:Resource, offset:Int):Void {}

	public static function vsSetShader(shader:Shader):Void {}

	public static function vsSetConstantBuffers(start:Int, count:Int, buffers:hl.Ref<Resource>):Void {}

	public static function psSetShader(shader:Shader):Void {}

	public static function psSetConstantBuffers(start:Int, count:Int, buffers:hl.Ref<Resource>):Void {}

	public static function iaSetPrimitiveTopology(topology:PrimitiveTopology):Void {}

	public static function iaSetIndexBuffer(buffer:Resource, is32Bits:Bool, offset:Int):Void {}

	public static function iaSetVertexBuffers(start:Int, count:Int, buffers:hl.Ref<Resource>, strides:hl.BytesAccess<Int>, offsets:hl.BytesAccess<Int>):Void {}

	public static function iaSetInputLayout(layout:Layout):Void {}

	public static function createInputLayout(elements:hl.NativeArray<LayoutElement>, shaderBytes:hl.Bytes, shaderSize:Int):Layout {
		return null;
	}

	public static function createBuffer(size:Int, usage:ResourceUsage, bind:ResourceBind, access:ResourceAccess, misc:ResourceMisc, stride:Int, data:hl.Bytes):Resource {
		return null;
	}

	public static function createTexture2d(desc:Texture2dDesc, ?data:hl.Bytes):Resource {
		return dxCreateTexture2d(desc, data);
	}

	public static function createDepthStencilView(texture:Resource, format:Format, readOnly:Bool):DepthStencilView {
		return null;
	}

	public static function omSetDepthStencilState(state:DepthStencilState, ref:Int):Void {}

	public static function clearDepthStencilView(view:DepthStencilView, depth:Null<Float>, stencil:Null<Int>) {}

	public static function createDepthStencilState(desc:DepthStencilDesc):DepthStencilState {
		return dxCreateDepthStencilState(desc);
	}

	public static function createBlendState(alphaToCoverage:Bool, independentBlend:Bool, blendDesc:hl.NativeArray<RenderTargetBlendDesc>, count:Int):BlendState {
		return null;
	}

	public static function omSetBlendState(state:BlendState, factors:hl.BytesAccess<hl.F32>, sampleMask:Int) {}

	public static function createSamplerState(state:SamplerDesc):SamplerState {
		return dxCreateSamplerState(state);
	}

	public static function createShaderResourceView(res:Resource, desc:ShaderResourceViewDesc):ShaderResourceView {
		return dxCreateShaderResourceView(res, desc);
	}

	public static function psSetSamplers(start:Int, count:Int, arr:hl.Ref<SamplerState>) {}

	public static function vsSetSamplers(start:Int, count:Int, arr:hl.Ref<SamplerState>) {}

	public static function psSetShaderResources(start:Int, count:Int, arr:hl.Ref<ShaderResourceView>) {}

	public static function vsSetShaderResources(start:Int, count:Int, arr:hl.Ref<ShaderResourceView>) {}

	public static function generateMips(res:ShaderResourceView) {}

	public static function debugPrint(v:Dynamic) {
		dxDebugPrint(@:privateAccess Std.string(v).bytes);
	}

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

	@:hlNative("limen", "d3d11_create_depth_stencil_state")
	static function dxCreateDepthStencilState(desc:Dynamic):DepthStencilState {
		return null;
	}

	@:hlNative("limen", "d3d11_create_rasterizer_state")
	static function dxCreateRasterizerState(desc:Dynamic):RasterState {
		return null;
	}

	@:hlNative("limen", "d3d11_create_render_target_view")
	static function dxCreateRenderTargetView(r:Resource, desc:Dynamic):RenderTargetView {
		return null;
	}

	@:hlNative("limen", "d3d11_create_sdl")
	static function dxCreate(win:hl.Abstract<"limen_window">, format:Format, flags:Dx11DriverInitFlags, minimumFeatureLevel:FeatureLevel):Dx11DriverInstance {
		return null;
	}

	@:hlNative("limen", "d3d11_get_device_name")
	static function dxGetDeviceName():hl.Bytes {
		return null;
	}

	@:hlNative("limen", "d3d11_compile_shader")
	static function dxCompileShader(data:hl.Bytes, size:Int, source:hl.Bytes, entry:hl.Bytes, target:hl.Bytes, flags:ShaderFlags, error:hl.Ref<Bool>, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	@:hlNative("limen", "d3d11_disassemble_shader")
	static function dxDisassembleShader(data:hl.Bytes, size:Int, flags:DisassembleFlags, comments:hl.Bytes, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	@:hlNative("limen", "d3d11_create_vertex_shader")
	static function dxCreateVertexShader(data:hl.Bytes, size:Int):Shader {
		return null;
	}

	@:hlNative("limen", "d3d11_create_pixel_shader")
	static function dxCreatePixelShader(data:hl.Bytes, size:Int):Shader {
		return null;
	}

	@:hlNative("limen", "d3d11_create_texture_2d")
	static function dxCreateTexture2d(desc:Dynamic, data:hl.Bytes):Resource {
		return null;
	}

	@:hlNative("limen", "d3d11_create_sampler_state")
	static function dxCreateSamplerState(desc:Dynamic):SamplerState {
		return null;
	}

	@:hlNative("limen", "d3d11_create_shader_resource_view")
	static function dxCreateShaderResourceView(res:Resource, desc:Dynamic):ShaderResourceView {
		return null;
	}

	@:hlNative("limen", "d3d11_debug_print")
	static function dxDebugPrint(str:hl.Bytes) {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract Dx11DriverInitFlags(Int) {
	final None = 0;
	final SingleThread = 1;
	final DebugLayer = 2;
	final SwitchToRef = 4;
	final PreventInternalThreadingOptimizations = 8;
	final BgraSupport = 32;
	final Debuggable = 64;
	final PreventAlteringLayerSettingsFromRegistry = 128;
	final DisableGpuTimeout = 256;
	final VideoSupport = 2048;

	@:op(a | b)
	static function or(a:Dx11DriverInitFlags, b:Dx11DriverInitFlags):Dx11DriverInitFlags;
}
#end

#if (!gfx_dx12 || gfx_dx11)
typedef Dx11DriverInstance = hl.Abstract<"dx_driver">;
#end

#if (!gfx_dx12 || gfx_dx11)
abstract DxBool(Int) {
	@:to
	public inline function toBool():Bool {
		return cast this;
	}

	@:from
	static function fromBool(b:Bool):DxBool {
		return cast b;
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract FeatureLevel(Int) to Int {
	final Level9_1 = 0x9100;
	final Level9_2 = 0x9200;
	final Level9_3 = 0x9300;
	final Level10_0 = 0xA000;
	final Level10_1 = 0xA100;
	final Level11_0 = 0xB000;
	final Level11_1 = 0xB100;
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract PresentFlags(Int) {
	final None = 0;
	final Test = 1;
	final DoNotSequence = 2;
	final Restart = 4;
	final DoNotWait = 8;
	final RestrictToOutput = 0x10;
	final StereoPreferRight = 0x20;
	final StereoTemporaryMono = 0x40;
	final UseDuration = 0x100;
	final AllowTearing = 0x200;

	@:op(a | b)
	static function or(a:PresentFlags, b:PresentFlags):PresentFlags;
}
#end
