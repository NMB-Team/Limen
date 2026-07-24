package limen.graphics.d3d12.shader;

import limen.graphics.d3d12.internal.D3D12Bindings;
import limen.graphics.d3d12.internal.D3D12Bindings.CompilerHandle;

@:struct class ShaderBytecode {
	public var shaderBytecode:hl.Bytes;
	public var bytecodeLength:hl.I64;
}

class ShaderCompiler {
	final handle:CompilerHandle;

	public function new() {
		handle = D3D12Bindings.compilerCreate();
		if (handle == null)
			throw "Failed to create D3D12 shader compiler";
	}

	public function compile(source:String, profile:String, args:Array<String>):haxe.io.Bytes {
		var outLength = 0;
		final nativeArgs = new hl.NativeArray(args.length);
		for (i in 0...args.length)
			nativeArgs[i] = @:privateAccess args[i].bytes;
		final bytes = D3D12Bindings.compilerCompile(handle, @:privateAccess source.bytes, @:privateAccess profile.bytes, nativeArgs, outLength);
		return @:privateAccess new haxe.io.Bytes(bytes, outLength);
	}
}

enum abstract ShaderModel(Int) to Int {
	final SHADER_MODEL_NONE;
	final SHADER_MODEL_5_1 = 0x51;
	final SHADER_MODEL_6_0 = 0x60;
	final SHADER_MODEL_6_1 = 0x61;
	final SHADER_MODEL_6_2 = 0x62;
	final SHADER_MODEL_6_3 = 0x63;
	final SHADER_MODEL_6_4 = 0x64;
	final SHADER_MODEL_6_5 = 0x65;
	final SHADER_MODEL_6_6 = 0x66;
	final SHADER_MODEL_6_7 = 0x67;
	final SHADER_MODEL_6_8;
	final SHADER_MODEL_6_9;
	final HIGHEST_SHADER_MODEL;
}

enum abstract ShaderVisibility(Int) {
	final ALL = 0;
	final VERTEX = 1;
	final HULL = 2;
	final DOMAIN = 3;
	final GEOMETRY = 4;
	final PIXEL = 5;
	final AMPLIFICATION = 6;
	final MESH = 7;
}
