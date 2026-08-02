package limen.graphics.d3d12.pipeline;

import limen.graphics.d3d12.descriptor.DescriptorHeap.DescriptorRange;
import limen.graphics.d3d12.resource.Resources.Dx12Resource;
import limen.graphics.d3d12.shader.ShaderCompiler.ShaderVisibility;
import limen.graphics.d3d12.pipeline.StreamOutput.StaticSamplerDesc;

@:struct class RootParameter {
	public var parameterType:RootParameterType;

	var __paddingBeforeUnion:Int;
}

@:struct class RootParameterConstants extends RootParameter {
	public var shaderRegister:Int;
	public var registerSpace:Int;
	public var num32BitValues:Int;

	var __unused:Int;

	public var shaderVisibility:ShaderVisibility;

	public function new() {
		parameterType = CONSTANTS;
	}
}

@:struct class RootParameterDescriptor extends RootParameter {
	public var shaderRegister:Int;
	public var registerSpace:Int;

	var __unused:Int;
	var __unused2:Int;

	public var shaderVisibility:ShaderVisibility;

	public function new(t) {
		parameterType = t;
	}
}

@:struct class RootParameterDescriptorTable extends RootParameter {
	public var numDescriptorRanges:Int;
	public var __padding:Int;
	public var descriptorRanges:hl.CArray<DescriptorRange>;
	public var shaderVisibility:ShaderVisibility;

	public function new() {
		parameterType = DESCRIPTOR_TABLE;
	}
}

enum abstract RootParameterType(Int) {
	final DESCRIPTOR_TABLE = 0;
	final CONSTANTS = 1;
	final CBV = 2;
	final SRV = 3;
	final UAV = 4;
}

@:hlNative("?limen_d3d12", "rootsignature_")
abstract RootSignature(Dx12Resource) {
	public function new(bytes:hl.Bytes, len:Int) {
		this = create(bytes, len);
	}

	static function create(bytes:hl.Bytes, len:Int):Dx12Resource {
		return null;
	}
}

@:struct class RootSignatureDesc {
	public var numParameters:Int;
	public var parameters:hl.CArray<RootParameter>;
	public var numStaticSamplers:Int;
	public var staticSamplers:hl.CArray<StaticSamplerDesc>;
	public var flags:haxe.EnumFlags<RootSignatureFlag>;

	public function new() {}
}

enum RootSignatureFlag {
	ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT;
	DENY_VERTEX_SHADER_ROOT_ACCESS;
	DENY_HULL_SHADER_ROOT_ACCESS;
	DENY_DOMAIN_SHADER_ROOT_ACCESS;
	DENY_GEOMETRY_SHADER_ROOT_ACCESS;
	DENY_PIXEL_SHADER_ROOT_ACCESS;
	ALLOW_STREAM_OUTPUT;
	LOCAL_ROOT_SIGNATURE;
	DENY_AMPLIFICATION_SHADER_ROOT_ACCESS;
	DENY_MESH_SHADER_ROOT_ACCESS;
	CBV_SRV_UAV_HEAP_DIRECTLY_INDEXED;
	SAMPLER_HEAP_DIRECTLY_INDEXED;
}
