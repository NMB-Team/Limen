package limen.graphics.renderer.d3d11.shader;

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

@:hlNative("limen", "d3d11_")
class ShaderCompiler {
	public static function compile(data:String, source:String, entryPoint:String, target:String, flags:ShaderFlags):haxe.io.Bytes @:privateAccess {
		final bytes = haxe.io.Bytes.ofString(data);
		var isError = false, size = 0;
		final out = dxCompileShader(bytes.getData(), bytes.length, source.toUtf8(), entryPoint.toUtf8(), target.toUtf8(), flags, isError, size);
		if (isError)
			throw String.fromUTF8(out);
		return out.toBytes(size);
	}

	@:hlNative("limen", "d3d11_compile_shader")
	static function dxCompileShader(data:hl.Bytes, size:Int, source:hl.Bytes, entry:hl.Bytes, target:hl.Bytes, flags:ShaderFlags, error:hl.Ref<Bool>, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}

	public static function disassemble(data:haxe.io.Bytes, flags:DisassembleFlags, ?comments:String):String {
		var size = 0;
		final out = dxDisassembleShader(data, data.length, flags, comments == null ? null : @:privateAccess comments.toUtf8(), size);
		if (out == null)
			throw "Could not disassemble shader";
		return @:privateAccess String.fromUTF8(out);
	}

	@:hlNative("limen", "d3d11_disassemble_shader")
	static function dxDisassembleShader(data:hl.Bytes, size:Int, flags:DisassembleFlags, comments:hl.Bytes, outSize:hl.Ref<Int>):hl.Bytes {
		return null;
	}
}
