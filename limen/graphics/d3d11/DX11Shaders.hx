package limen.graphics.d3d11;

import limen.graphics.d3d11.DX11Core.Format;
import limen.graphics.d3d11.DX11Core.Pointer;
import limen.graphics.d3d11.internal.D3D11Bindings;

import haxe.Int64;

#if (!gfx_dx12 || gfx_dx11)
enum abstract DisassembleFlags(Int) {
	final None = 0;
	final EnableColorCode = 1;
	final EnableDefaultValuePrints = 2;
	final EnableInstructionNumbering = 4;
	final EnableInsructionCycle = 8;
	final DisableDebugInfo = 0x10;
	final EnableInstructionOffset = 0x20;
	final InstructionOnly = 0x40;
	final PrintHexLiterals = 0x80;

	@:op(a | b)
	static function or(a:DisassembleFlags, b:DisassembleFlags):DisassembleFlags;
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract Layout(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract LayoutClassification(Int) {
	final PerVertexData = 0;
	final PerInstanceData = 1;
}
#end

#if (!gfx_dx12 || gfx_dx11)
@:keep
class LayoutElement {
	public var semanticName:hl.Bytes;
	public var semanticIndex:Int;
	public var format:Format;
	public var inputSlot:Int;
	public var alignedByteOffset:Int;
	public var inputSlotClass:LayoutClassification;
	public var instanceDataStepRate:Int;

	public function new() {}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract PrimitiveTopology(Int) {
	final Undefined = 0;
	final PointList = 1;
	final LineList = 2;
	final LineStrip = 3;
	final TriangleList = 4;
	final TriangleStrip = 5;
	final LineListAdj = 10;
	final TriangleListAdj = 12;
	final TriangleStripAdj = 13;

	static inline function controlPointPatchList(count:Int):PrimitiveTopology {
		return cast(count + 32);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
abstract Shader(Pointer) {
	public inline function release() {
		D3D11Bindings.releasePointer(this);
	}
}
#end

#if (!gfx_dx12 || gfx_dx11)
enum abstract ShaderFlags(Int) {
	final None = 0;
	final Debug = 0x1;
	final SkipValidation = 0x2;
	final SkipOptimization = 0x4;
	final PackMatrixRowMajor = 0x8;
	final PackMatrixColumnMajor = 0x10;
	final PartialPrecision = 0x20;
	final ForceVSSoftwareNoOpt = 0x40;
	final ForcePSSoftwareNoOpt = 0x80;
	final NoPreshader = 0x100;
	final AvoidFlowControl = 0x200;
	final PreferFlowControl = 0x400;
	final EnableStrictness = 0x800;
	final EnableBackwardsCompatibility = 0x1000;
	final IEEEStrictness = 0x2000;
	final OptimizationLevel0 = 0x4000;
	final OptimizationLevel1 = 0; // default
	final OptimizationLevel2 = 0x4000 | 0x8000;
	final OptimizationLevel3 = 0x8000;
	final WarningsAreErrors = 0x40000;
	final ResourcesMayAlias = 0x80000;
	final EnableUnboundedDescriptorTables = 0x100000;
	final AllResourcesBound = 0x200000;

	@:op(a | b)
	static function or(a:ShaderFlags, b:ShaderFlags):ShaderFlags;
}
#end
