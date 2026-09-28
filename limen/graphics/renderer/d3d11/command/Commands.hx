package limen.graphics.renderer.d3d11.command;

import limen.graphics.renderer.d3d11.DX11Core.PrimitiveTopology;
import limen.graphics.renderer.d3d11.descriptor.ResourceViews.DepthStencilView;
import limen.graphics.renderer.d3d11.descriptor.ResourceViews.RenderTargetView;
import limen.graphics.renderer.d3d11.descriptor.ResourceViews.ShaderResourceView;
import limen.graphics.renderer.d3d11.pipeline.InputLayout.Layout;
import limen.graphics.renderer.d3d11.pipeline.Pipeline.BlendState;
import limen.graphics.renderer.d3d11.pipeline.Pipeline.DepthStencilState;
import limen.graphics.renderer.d3d11.pipeline.Pipeline.RasterState;
import limen.graphics.renderer.d3d11.pipeline.Pipeline.SamplerState;
import limen.graphics.renderer.d3d11.resource.Resources.Resource;
import limen.graphics.renderer.d3d11.shader.Shaders.Shader;

@:hlNative("limen", "d3d11_")
class Commands {
	public static function omSetRenderTargets(count:Int, arr:hl.Ref<RenderTargetView>, ?depth:DepthStencilView) {}

	public static function rsSetState(r:RasterState) {}

	public static function rsSetViewports(count:Int, bytes:hl.BytesAccess<hl.F32>) {}

	public static function rsSetScissorRects(count:Int, rects:hl.BytesAccess<Int>) {}

	public static function clearColor(rt:RenderTargetView, r:Float, g:Float, b:Float, a:Float) {}

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

	public static function omSetDepthStencilState(state:DepthStencilState, ref:Int):Void {}

	public static function clearDepthStencilView(view:DepthStencilView, depth:Null<Float>, stencil:Null<Int>) {}

	public static function omSetBlendState(state:BlendState, factors:hl.BytesAccess<hl.F32>, sampleMask:Int) {}

	public static function psSetSamplers(start:Int, count:Int, arr:hl.Ref<SamplerState>) {}

	public static function vsSetSamplers(start:Int, count:Int, arr:hl.Ref<SamplerState>) {}

	public static function psSetShaderResources(start:Int, count:Int, arr:hl.Ref<ShaderResourceView>) {}

	public static function vsSetShaderResources(start:Int, count:Int, arr:hl.Ref<ShaderResourceView>) {}

	public static function generateMips(res:ShaderResourceView) {}
}
