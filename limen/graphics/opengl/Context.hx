package limen.graphics.opengl;

import limen.graphics.opengl.internal.OpenGLBindings;
import limen.graphics.opengl.internal.OpenGLBindings.ContextHandle;
import limen.platform.Platform;
import limen.platform.Window;
import haxe.ds.ObjectMap;

private typedef Version = {
	var major:Int;
	var minor:Int;
}

class Context {
	public static inline final DOUBLE_BUFFER = 1 << 0;
	public static inline final CORE_PROFILE = 1 << 1;
	public static inline final COMPATIBILITY_PROFILE = 1 << 2;
	public static inline final ES_PROFILE = 1 << 3;

	public static dynamic function onError(message:String):Void {
		throw message;
	}

	static final contexts = new ObjectMap<Window, Context>();
	static var current:Context;

	public var vsync(default, set):Bool;

	final window:Window;
	var handle:ContextHandle;
	var lastFrame:Float;

	public static function create(window:Window, ?options:ContextOptions):Context {
		final minimumMajor = options?.minimumMajor ?? 2;
		final minimumMinor = options?.minimumMinor ?? 1;
		final maximumMajor = options?.maximumMajor ?? 4;
		final maximumMinor = options?.maximumMinor ?? 6;
		final flags = options?.flags ?? DOUBLE_BUFFER;
		final versions = versionsInRange(minimumMajor, minimumMinor, maximumMajor, maximumMinor, (flags & ES_PROFILE) != 0);
		final depth = options?.depthBits ?? 24;
		final stencil = options?.stencilBits ?? 8;
		final samples = options?.samples ?? 1;

		for (version in versions) {
			OpenGLBindings.configureContext(version.major, version.minor, depth, stencil, flags, samples);
			final handle = OpenGLBindings.createContext(window.nativeHandle);
			if (handle == null)
				continue;
			OpenGLBindings.makeCurrent(window.nativeHandle, handle);
			if (OpenGLBindings.init() && validate()) {
				final context = new Context(window, handle);
				context.vsync = options?.vsync != false;
				return context;
			}
			OpenGLBindings.destroyContext(handle);
		}

		final currentVersion:String = OpenGLBindings.getParameter(OpenGLBindings.VERSION);
		final device = Platform.getDevices()[0] ?? "Unknown";
		final message = 'Unable to create an OpenGL context for $device. Current OpenGL version: ${currentVersion ?? "Unavailable"}. OpenGL $minimumMajor.$minimumMinor+ is required.';
		onError(message);
		return null;
	}

	function new(window:Window, handle:ContextHandle) {
		this.window = window;
		this.handle = handle;
		contexts.set(window, this);
		current = this;
	}

	public function makeCurrent(?target:Window):Void {
		OpenGLBindings.makeCurrent((target ?? window).nativeHandle, handle);
		current = this;
	}

	public function present(?target:Window):Void {
		if (handle == null)
			return;
		if (vsync && Platform.isWindows()) {
			final spent = haxe.Timer.stamp() - lastFrame;
			if (spent < 0.005)
				Sys.sleep(0.005 - spent);
		}
		OpenGLBindings.swapWindow((target ?? window).nativeHandle);
		lastFrame = haxe.Timer.stamp();
	}

	public function destroy():Void {
		if (handle == null)
			return;
		OpenGLBindings.destroyContext(handle);
		handle = null;
		contexts.remove(window);
		if (current == this)
			current = null;
	}

	public static function setWindowCurrent(window:Window):Void {
		final context = contexts.get(window) ?? current;
		if (context == null)
			throw "No OpenGL context is available";
		context.makeCurrent(window);
	}

	public static function presentWindow(window:Window):Void {
		final context = contexts.get(window) ?? current;
		if (context == null)
			throw "No OpenGL context is available";
		context.present(window);
	}

	function set_vsync(enabled:Bool):Bool {
		makeCurrent();
		OpenGLBindings.setVsync(enabled);
		return vsync = enabled;
	}

	static function versionsInRange(minimumMajor:Int, minimumMinor:Int, maximumMajor:Int, maximumMinor:Int, es:Bool):Array<Version> {
		final minimum = minimumMajor * 10 + minimumMinor;
		final maximum = maximumMajor * 10 + maximumMinor;
		if (minimum > maximum)
			throw "Minimum OpenGL version cannot be higher than maximum OpenGL version";
		final supported = es ? [
			{major: 3, minor: 2},
			{major: 3, minor: 1},
			{major: 3, minor: 0},
			{major: 2, minor: 0}
		] : [
			{major: 4, minor: 6}, {major: 4, minor: 5}, {major: 4, minor: 4}, {major: 4, minor: 3},
			{major: 4, minor: 2}, {major: 4, minor: 1}, {major: 4, minor: 0}, {major: 3, minor: 3},
			{major: 3, minor: 2}, {major: 3, minor: 1}, {major: 3, minor: 0}, {major: 2, minor: 1}
			];
		final versions = supported.filter(version -> {
			final value = version.major * 10 + version.minor;
			return value >= minimum && value <= maximum;
		});
		if (versions.length == 0)
			throw "OpenGL version range does not contain a supported context version";
		return versions;
	}

	static function validate():Bool {
		try {
			final versionPattern = ~/[0-9]+\.[0-9]+/;
			final shadingLanguageVersion:String = OpenGLBindings.getParameter(OpenGLBindings.SHADING_LANGUAGE_VERSION);
			final glVersion:String = OpenGLBindings.getParameter(OpenGLBindings.VERSION);
			final isOpenGLES = glVersion != null && glVersion.indexOf("ES") >= 0;
			var shaderVersion = isOpenGLES ? 100 : 120;
			if (versionPattern.match(shadingLanguageVersion))
				shaderVersion = Math.round(Std.parseFloat(versionPattern.matched(0)) * 100);
			final versionDirective = "#version " + shaderVersion + (isOpenGLES && shaderVersion >= 300 ? " es" : "");
			final vertex = OpenGLBindings.createShader(OpenGLBindings.VERTEX_SHADER);
			OpenGLBindings.shaderSource(vertex, [versionDirective, "void main() { gl_Position = vec4(1.0); }"].join("\n"));
			OpenGLBindings.compileShader(vertex);
			if (OpenGLBindings.getShaderParameter(vertex, OpenGLBindings.COMPILE_STATUS) != 1)
				return false;
			final fragment = OpenGLBindings.createShader(OpenGLBindings.FRAGMENT_SHADER);
			final fragmentSource = if (isOpenGLES && shaderVersion < 300) "precision lowp float; void main() { gl_FragColor = vec4(1.0); }"; else if (!isOpenGLES && shaderVersion < 130) "void main() { gl_FragColor = vec4(1.0); }"; else
				"out vec4 color; void main() { color = vec4(1.0); }";
			OpenGLBindings.shaderSource(fragment, [versionDirective, fragmentSource].join("\n"));
			OpenGLBindings.compileShader(fragment);
			if (OpenGLBindings.getShaderParameter(fragment, OpenGLBindings.COMPILE_STATUS) != 1)
				return false;
			final program = OpenGLBindings.createProgram();
			OpenGLBindings.attachShader(program, vertex);
			OpenGLBindings.attachShader(program, fragment);
			OpenGLBindings.linkProgram(program);
			final valid = OpenGLBindings.getProgramParameter(program, OpenGLBindings.LINK_STATUS) == 1;
			OpenGLBindings.deleteShader(vertex);
			OpenGLBindings.deleteShader(fragment);
			OpenGLBindings.deleteProgram(program);
			return valid;
		} catch (_:Dynamic) {
			return false;
		}
	}
}
