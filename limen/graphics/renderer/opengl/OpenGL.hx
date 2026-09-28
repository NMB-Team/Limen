package limen.graphics.renderer.opengl;

import limen.graphics.renderer.opengl.internal.OpenGLBindings;
import limen.graphics.renderer.opengl.device.Capabilities;
import limen.graphics.renderer.opengl.shader.Shaders;
import limen.graphics.renderer.opengl.internal.OpenGLBindings.ContextHandle;
import limen.platform.Platform;
import limen.platform.window.Window;
import limen.graphics.PresentMode;

private typedef GLVersion = {major:Int, minor:Int}

class OpenGL {
	public static inline final DOUBLE_BUFFER = 1 << 0;
	public static inline final CORE_PROFILE = 1 << 1;
	public static inline final COMPATIBILITY_PROFILE = 1 << 2;
	public static inline final ES_PROFILE = 1 << 3;

	public var presentMode(default, null):Null<PresentMode>;
	public var requestedPresentMode(default, null):PresentMode = VSync;

	private var presentModeAttempted:Bool = false;

	final window:Window;
	var handle:ContextHandle;

	private function new(window:Window, handle:ContextHandle) {
		this.window = window;
		this.handle = handle;
	}

	public static function create(window:Window, ?options:ContextOptions):OpenGL {
		final flags = options?.flags ?? DOUBLE_BUFFER;
		final isES = Platform.isMobile || (flags & ES_PROFILE) != 0;
		final resolvedFlags = isES ? flags | ES_PROFILE : flags;
		final minimumMajor = options?.minimumMajor ?? 2;
		final minimumMinor = options?.minimumMinor ?? (isES ? 0 : 1);
		final maximumMajor = options?.maximumMajor ?? 4;
		final maximumMinor = options?.maximumMinor ?? 6;

		final versions = versionsInRange(minimumMajor, minimumMinor, maximumMajor, maximumMinor, isES);

		final depth = options?.depthBits ?? 24;
		final stencil = options?.stencilBits ?? 8;
		final samples = options?.samples ?? 1;

		final attempts:Array<String> = [];

		for (version in versions) {
			final requested = 'OpenGL ${version.major}.${version.minor}' + ' depth=$depth' + ' stencil=$stencil' + ' samples=$samples';

			if (!OpenGLBindings.configureContext(version.major, version.minor, depth, stencil, resolvedFlags, samples)) {
				final error = Platform.getError();
				attempts.push('$requested\n  configuration failed: ${(error == null || error.length == 0 ? "Unknown SDL error" : error)}');
				continue;
			}

			final handle = OpenGLBindings.createContext(window.nativeHandle);
			if (handle == null) {
				final error = Platform.getError();
				attempts.push('$requested\n  configuration failed: ${(error == null || error.length == 0 ? "Unknown SDL error" : error)}');
				continue;
			}

			OpenGLBindings.makeCurrent(window.nativeHandle, handle);

			final info = OpenGLBindings.getContextInfo();
			final actual = if (info == null) {
				final error = Platform.getError();
				error == null
				|| error.length == 0 ? "Unavailable" : 'Unavailable: $error';
			} else {
				@:privateAccess String.fromUTF8(info);
			}

			if (OpenGLBindings.init() && validate()) {
				final context = new OpenGL(window, handle);
				context.setPresentMode(options?.presentMode ?? VSync);
				return context;
			}

			attempts.push('$requested\n  actual: $actual\n  OpenGL initialization/validation failed');

			OpenGLBindings.destroyContext(handle);
		}

		final device = Platform.getDevices()[0] ?? "Unknown";
		final message = [
			'Unable to create an OpenGL context for $device.',
			'Required OpenGL range: $minimumMajor.$minimumMinor - $maximumMajor.$maximumMinor',
			'Requested depth=$depth stencil=$stencil samples=$samples',
			"",
			"Attempts:",
			attempts.join("\n\n")
		].join("\n");
		onError(message);

		return null;
	}

	public function setPresentMode(mode:PresentMode):Bool {
		if (presentModeAttempted && requestedPresentMode == mode)
			return presentMode == mode;

		makeCurrent();
		requestedPresentMode = mode;
		presentModeAttempted = true;

		if (OpenGLBindings.setSwapInterval(mode)) {
			presentMode = mode;
			return true;
		}

		if (mode == Adaptive)
			if (OpenGLBindings.setSwapInterval(VSync)) {
				presentMode = VSync;
				return false;
			}

		return false;
	}

	public static dynamic function onError(message:String):Void {
		throw message;
	}

	public function makeCurrent():Void {
		OpenGLBindings.makeCurrent(window.nativeHandle, handle);
	}

	public function present():Void {
		if (handle == null)
			return;

		OpenGLBindings.swapWindow(window.nativeHandle);
	}

	public function destroy():Void {
		if (handle == null)
			return;
		OpenGLBindings.destroyContext(handle);
		handle = null;
	}

	static function versionsInRange(minimumMajor:Int, minimumMinor:Int, maximumMajor:Int, maximumMinor:Int, es:Bool):Array<GLVersion> {
		final minimum = minimumMajor * 10 + minimumMinor;
		final maximum = maximumMajor * 10 + maximumMinor;
		if (minimum > maximum)
			throw "Minimum OpenGL version cannot be higher than maximum OpenGL version";

		final supported = {
			es ? [
				{major: 3, minor: 2},
				{major: 3, minor: 1},
				{major: 3, minor: 0},
				{major: 2, minor: 0}
			] : [
				{major: 4, minor: 6}, {major: 4, minor: 5}, {major: 4, minor: 4}, {major: 4, minor: 3},
				{major: 4, minor: 2}, {major: 4, minor: 1}, {major: 4, minor: 0}, {major: 3, minor: 3},
				{major: 3, minor: 2}, {major: 3, minor: 1}, {major: 3, minor: 0}, {major: 2, minor: 1}
			];
		}

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
			final shadingLanguageVersion:String = Capabilities.getString(Capabilities.SHADING_LANGUAGE_VERSION);
			final glVersion:String = Capabilities.getString(Capabilities.VERSION);
			final isOpenGLES = glVersion != null && glVersion.indexOf("ES") >= 0;

			var shaderVersion = isOpenGLES ? 100 : 120;
			if (versionPattern.match(shadingLanguageVersion))
				shaderVersion = Math.round(Std.parseFloat(versionPattern.matched(0)) * 100);

			final versionDirective = "#version " + shaderVersion + (isOpenGLES && shaderVersion >= 300 ? " es" : "");
			final vertex = Shaders.createShader(Shaders.VERTEX_SHADER);
			Shaders.shaderSource(vertex, [versionDirective, "void main() { gl_Position = vec4(1.0); }"].join("\n"));
			Shaders.compileShader(vertex);
			if (Shaders.getShaderParameter(vertex, Shaders.COMPILE_STATUS) != 1)
				return false;

			final fragment = Shaders.createShader(Shaders.FRAGMENT_SHADER);
			final fragmentSource = if (isOpenGLES && shaderVersion < 300) {
				"
					precision lowp float;
					void main() {
						gl_FragColor = vec4(1.0);
					}
				";
			} else if (!isOpenGLES && shaderVersion < 130) {
				"
					void main() {
						gl_FragColor = vec4(1.0);
					}
				";
			} else {
				"
					out vec4 color;
					void main() {
						color = vec4(1.0);
					}
				";
			}

			Shaders.shaderSource(fragment, [versionDirective, fragmentSource].join("\n"));
			Shaders.compileShader(fragment);
			if (Shaders.getShaderParameter(fragment, Shaders.COMPILE_STATUS) != 1)
				return false;

			final program = Shaders.createProgram();
			Shaders.attachShader(program, vertex);
			Shaders.attachShader(program, fragment);
			Shaders.linkProgram(program);

			final valid = Shaders.getProgramParameter(program, Shaders.LINK_STATUS) == 1;
			Shaders.deleteShader(vertex);
			Shaders.deleteShader(fragment);
			Shaders.deleteProgram(program);
			return valid;
		} catch (_:Dynamic) {
			return false;
		}
	}
}
