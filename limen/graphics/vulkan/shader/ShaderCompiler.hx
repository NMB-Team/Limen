package limen.graphics.vulkan.shader;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.internal.VulkanBindings.ShaderKind;
import limen.graphics.vulkan.internal.VulkanBindings.VkShaderCompiler;

enum abstract ShaderTargetVulkanVersion(Int) to Int {
	final Vulkan10 = 10;
	final Vulkan11 = 11;
	final Vulkan12 = 12;
	final Vulkan13 = 13;
}

enum abstract ShaderTargetSpirvVersion(Int) to Int {
	final Spirv10 = 10;
	final Spirv11 = 11;
	final Spirv12 = 12;
	final Spirv13 = 13;
	final Spirv14 = 14;
	final Spirv15 = 15;
	final Spirv16 = 16;
}

enum abstract ShaderOptimizationMode(Int) to Int {
	final None = 0;
	final Size = 1;
	final Performance = 2;
}

enum abstract ShaderCompileStatus(Int) from Int to Int {
	final InternalError = -1;
	final Success = 0;
	final InvalidStage = 1;
	final CompilationError = 2;
	final InternalCompilerError = 3;
	final NullResultObject = 4;
	final InvalidAssembly = 5;
	final ValidationError = 6;
	final TransformationError = 7;
	final ConfigurationError = 8;
}

class ShaderDefine {
	public final name:String;
	public final value:Null<String>;

	public function new(name:String, ?value:String) {
		this.name = name;
		this.value = value;
	}
}

class ShaderCompileRequest {
	public final source:String;
	public final sourceName:String;
	public final entryPoint:String;
	public final shaderStage:ShaderKind;
	public final targetVulkanVersion:ShaderTargetVulkanVersion;
	public final targetSpirvVersion:ShaderTargetSpirvVersion;
	public final optimizationMode:ShaderOptimizationMode;
	public final debugInfo:Bool;
	public final warningsAsErrors:Bool;
	public final defines:Array<ShaderDefine>;

	public function new(source:String, sourceName:String, entryPoint:String, shaderStage:ShaderKind, targetVulkanVersion:ShaderTargetVulkanVersion = Vulkan13, targetSpirvVersion:ShaderTargetSpirvVersion = Spirv16,
			optimizationMode:ShaderOptimizationMode = None, debugInfo:Bool = true, warningsAsErrors:Bool = true, ?defines:Array<ShaderDefine>) {
		this.source = source;
		this.sourceName = sourceName;
		this.entryPoint = entryPoint;
		this.shaderStage = shaderStage;
		this.targetVulkanVersion = targetVulkanVersion;
		this.targetSpirvVersion = targetSpirvVersion;
		this.optimizationMode = optimizationMode;
		this.debugInfo = debugInfo;
		this.warningsAsErrors = warningsAsErrors;
		this.defines = defines == null ? [] : defines.copy();
	}
}

class ShaderCompileResult {
	public final status:ShaderCompileStatus;
	public final spirv:Null<haxe.io.Bytes>;
	public final warnings:Int;
	public final errors:Int;
	public final diagnostics:String;

	public var succeeded(get, never):Bool;

	public function new(status, spirv, warnings, errors, diagnostics) {
		this.status = status;
		this.spirv = spirv;
		this.warnings = warnings;
		this.errors = errors;
		this.diagnostics = diagnostics;
	}

	inline function get_succeeded() {
		return status == Success && spirv != null;
	}
}

class ShaderCompiler {
	var handle:VkShaderCompiler;

	public function new() {
		handle = VulkanBindings.shaderCompilerCreate();
		if (handle == null)
			throw "Failed to initialize the Vulkan shader compiler service; shaderc is unavailable";
	}

	public function compile(request:ShaderCompileRequest):ShaderCompileResult {
		if (handle == null)
			throw "Vulkan shader compiler service is disposed";
		if (request.source.length == 0)
			throw "Shader source must not be empty";
		if (request.sourceName.length == 0)
			throw "Shader source name must not be empty";
		if (request.entryPoint.length == 0)
			throw "Shader entry point must not be empty";

		final nativeDefines = new hl.NativeArray<hl.Bytes>(request.defines.length);
		for (index in 0...request.defines.length) {
			final define = request.defines[index];
			if (define.name.length == 0 || define.name.indexOf("=") >= 0)
				throw 'Invalid shader define name "${define.name}"';
			final encoded = define.value == null ? define.name : define.name + "=" + define.value;
			nativeDefines[index] = @:privateAccess encoded.toUtf8();
		}

		var responseSize = 0;
		final nativeResponse = VulkanBindings.shaderCompile(handle, @:privateAccess request.source.toUtf8(), @:privateAccess request.sourceName.toUtf8(), @:privateAccess request.entryPoint.toUtf8(), request.shaderStage, request.targetVulkanVersion,
			request.targetSpirvVersion,
			request.optimizationMode, request.debugInfo, request.warningsAsErrors, nativeDefines, responseSize);
		if (nativeResponse == null || responseSize < 20)
			return new ShaderCompileResult(InternalError, null, 0, 1, "Native shader compiler returned an invalid result");
		final response = @:privateAccess new haxe.io.Bytes(nativeResponse, responseSize);
		final status:ShaderCompileStatus = nativeResponse.getI32(0);
		final warnings = nativeResponse.getI32(4);
		final errors = nativeResponse.getI32(8);
		final bytecodeSize = nativeResponse.getI32(12);
		final diagnosticsSize = nativeResponse.getI32(16);
		if (bytecodeSize < 0 || diagnosticsSize < 0 || 20 + bytecodeSize + diagnosticsSize != responseSize)
			return new ShaderCompileResult(InternalError, null, 0, 1, "Native shader compiler returned a malformed result");
		final bytecode = bytecodeSize == 0 ? null : response.sub(20, bytecodeSize);
		final diagnostics = diagnosticsSize == 0 ? "" : response.getString(20 + bytecodeSize, diagnosticsSize);
		return new ShaderCompileResult(status, bytecode, warnings, errors, diagnostics);
	}

	public function dispose() {
		if (handle == null)
			return;
		VulkanBindings.shaderCompilerDestroy(handle);
		handle = null;
	}
}
