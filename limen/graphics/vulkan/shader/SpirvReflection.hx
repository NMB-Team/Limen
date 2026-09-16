package limen.graphics.vulkan.shader;

import limen.graphics.vulkan.internal.VulkanBindings;
import limen.graphics.vulkan.shader.ShaderCompiler.ShaderTargetVulkanVersion;

class SpirvValidationResult {
	public final status:Int;
	public final diagnostics:String;
	public var valid(get, never):Bool;

	public function new(status:Int, diagnostics:String) {
		this.status = status;
		this.diagnostics = diagnostics;
	}

	inline function get_valid() {
		return status == 0;
	}
}

class SpirvValidator {
	public static function validate(spirv:haxe.io.Bytes, targetVulkanVersion:ShaderTargetVulkanVersion = Vulkan13):SpirvValidationResult {
		var status = -1;
		final diagnostics = VulkanBindings.spirvValidate(@:privateAccess spirv.b, spirv.length, targetVulkanVersion, status);
		return new SpirvValidationResult(status, diagnostics == null ? "" : @:privateAccess String.fromUTF8(diagnostics));
	}
}

class SpirvLocalSize {
	public final x:Int;
	public final y:Int;
	public final z:Int;

	public function new(value:Dynamic) {
		x = integer(value, "x");
		y = integer(value, "y");
		z = integer(value, "z");
	}

	static inline function integer(value:Dynamic, field:String):Int {
		return Std.int(Reflect.field(value, field));
	}
}

class SpirvNumericTraits {
	public final scalarWidth:Int;
	public final signedness:Int;
	public final vectorComponents:Int;
	public final matrixColumns:Int;
	public final matrixRows:Int;
	public final matrixStride:Int;
	public final arrayDimensions:Array<Int>;
	public final arrayStride:Int;

	public function new(value:Dynamic) {
		scalarWidth = integer(value, "scalarWidth");
		signedness = integer(value, "signedness");
		vectorComponents = integer(value, "vectorComponents");
		matrixColumns = integer(value, "matrixColumns");
		matrixRows = integer(value, "matrixRows");
		matrixStride = integer(value, "matrixStride");
		arrayDimensions = integers(Reflect.field(value, "arrayDimensions"));
		arrayStride = integer(value, "arrayStride");
	}

	static inline function integer(value:Dynamic, field:String):Int {
		return Std.int(Reflect.field(value, field));
	}

	static function integers(values:Array<Dynamic>):Array<Int> {
		return [for (value in values) Std.int(value)];
	}
}

class SpirvBlockVariable {
	public final name:String;
	public final offset:Int;
	public final absoluteOffset:Int;
	public final size:Int;
	public final paddedSize:Int;
	public final decorationFlags:Int;
	public final typeName:Null<String>;
	public final numeric:SpirvNumericTraits;
	public final members:Array<SpirvBlockVariable>;

	public function new(value:Dynamic) {
		name = string(value, "name");
		offset = integer(value, "offset");
		absoluteOffset = integer(value, "absoluteOffset");
		size = integer(value, "size");
		paddedSize = integer(value, "paddedSize");
		decorationFlags = integer(value, "decorationFlags");
		typeName = Reflect.field(value, "typeName");
		numeric = new SpirvNumericTraits(value);
		members = [
			for (member in (Reflect.field(value, "members") : Array<Dynamic>)) new SpirvBlockVariable(member)
		];
	}

	static inline function integer(value:Dynamic, field:String):Int {
		return Std.int(Reflect.field(value, field));
	}

	static function string(value:Dynamic, field:String):String {
		final result:Dynamic = Reflect.field(value, field);
		return result == null ? "" : result;
	}
}

class SpirvDescriptorBinding {
	public final name:String;
	public final set:Int;
	public final binding:Int;
	public final descriptorType:Int;
	public final count:Int;
	public final resourceType:Int;
	public final accessed:Bool;
	public final imageDimension:Int;
	public final imageArrayed:Bool;
	public final imageMultisampled:Bool;
	public final imageSampled:Int;
	public final imageFormat:Int;
	public final arrayDimensions:Array<Int>;
	public final block:SpirvBlockVariable;

	public function new(value:Dynamic) {
		final reflectedName:Dynamic = Reflect.field(value, "name");
		name = reflectedName == null ? "" : reflectedName;
		set = integer(value, "set");
		binding = integer(value, "binding");
		descriptorType = integer(value, "descriptorType");
		count = integer(value, "count");
		resourceType = integer(value, "resourceType");
		accessed = integer(value, "accessed") != 0;
		imageDimension = integer(value, "imageDimension");
		imageArrayed = integer(value, "imageArrayed") != 0;
		imageMultisampled = integer(value, "imageMultisampled") != 0;
		imageSampled = integer(value, "imageSampled");
		imageFormat = integer(value, "imageFormat");
		arrayDimensions = [
			for (dimension in (Reflect.field(value, "arrayDimensions") : Array<Dynamic>)) Std.int(dimension)
		];
		block = new SpirvBlockVariable(Reflect.field(value, "block"));
	}

	static inline function integer(value:Dynamic, field:String):Int {
		return Std.int(Reflect.field(value, field));
	}
}

class SpirvDescriptorSet {
	public final set:Int;
	public final bindings:Array<SpirvDescriptorBinding>;

	public function new(value:Dynamic) {
		set = Std.int(Reflect.field(value, "set"));
		bindings = [
			for (binding in (Reflect.field(value, "bindings") : Array<Dynamic>)) new SpirvDescriptorBinding(binding)
		];
	}
}

class SpirvInterfaceVariable {
	public final name:String;
	public final semantic:String;
	public final location:Int;
	public final component:Int;
	public final builtIn:Int;
	public final format:Int;
	public final decorationFlags:Int;
	public final typeName:Null<String>;
	public final numeric:SpirvNumericTraits;

	public function new(value:Dynamic) {
		name = string(value, "name");
		semantic = string(value, "semantic");
		location = integer(value, "location");
		component = integer(value, "component");
		builtIn = integer(value, "builtIn");
		format = integer(value, "format");
		decorationFlags = integer(value, "decorationFlags");
		typeName = Reflect.field(value, "typeName");
		numeric = new SpirvNumericTraits(value);
	}

	static inline function integer(value:Dynamic, field:String):Int {
		return Std.int(Reflect.field(value, field));
	}

	static function string(value:Dynamic, field:String):String {
		final result:Dynamic = Reflect.field(value, field);
		return result == null ? "" : result;
	}
}

class SpirvReflection {
	public final entryPoint:String;
	public final shaderStage:Int;
	public final localSize:SpirvLocalSize;
	public final descriptorSets:Array<SpirvDescriptorSet>;
	public final pushConstantBlocks:Array<SpirvBlockVariable>;
	public final inputs:Array<SpirvInterfaceVariable>;
	public final outputs:Array<SpirvInterfaceVariable>;

	public function new(value:Dynamic) {
		entryPoint = Reflect.field(value, "entryPoint");
		shaderStage = Std.int(Reflect.field(value, "shaderStage"));
		localSize = new SpirvLocalSize(Reflect.field(value, "localSize"));
		descriptorSets = [
			for (set in (Reflect.field(value, "descriptorSets") : Array<Dynamic>)) new SpirvDescriptorSet(set)
		];
		pushConstantBlocks = [
			for (block in (Reflect.field(value, "pushConstantBlocks") : Array<Dynamic>)) new SpirvBlockVariable(block)
		];
		inputs = [
			for (input in (Reflect.field(value, "inputs") : Array<Dynamic>)) new SpirvInterfaceVariable(input)
		];
		outputs = [
			for (output in (Reflect.field(value, "outputs") : Array<Dynamic>)) new SpirvInterfaceVariable(output)
		];
	}

	public static function reflect(spirv:haxe.io.Bytes, targetVulkanVersion:ShaderTargetVulkanVersion = Vulkan13):SpirvReflection {
		final validation = SpirvValidator.validate(spirv, targetVulkanVersion);
		if (!validation.valid)
			throw 'SPIR-V validation failed (${validation.status}): ${validation.diagnostics}';
		var status = -1;
		final json = VulkanBindings.spirvReflect(@:privateAccess spirv.b, spirv.length, status);
		final text = json == null ? "" : @:privateAccess String.fromUTF8(json);
		if (status != 0)
			throw 'SPIR-V reflection failed ($status): $text';
		return new SpirvReflection(haxe.Json.parse(text));
	}
}
