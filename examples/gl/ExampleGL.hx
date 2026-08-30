package;

import limen.graphics.GraphicsDriver;
import limen.graphics.opengl.Context;
import limen.graphics.opengl.OpenGLTypes.Program;
import limen.graphics.opengl.OpenGLTypes.Shader;
import limen.graphics.opengl.internal.OpenGLBindings as GL;
import limen.platform.Platform;
import limen.platform.window.Window;
import limen.platform.window.WindowFlags;
import limen.platform.window.WindowMode;
import limen.platform.event.Event;
import limen.platform.event.EventType;

class ExampleGL {
	static inline final F11_SCANCODE = 68;

	static function main() {
		// 1 - set by default, 2 - list of included, but its not need here
		Platform.init(GraphicsDriver.OpenGL);

		final window = Window.create({
			title: "LIMEN GL Example",
			width: 960,
			height: 540,
			flags: WindowFlags.SDL_WINDOW_OPENGL,
			resizable: true
		});

		final context = Context.create(window, {
			minimumMajor: 3,
			minimumMinor: 3,
			flags: Context.DOUBLE_BUFFER | Context.CORE_PROFILE,
			vsync: false
		});

		final path = Sys.getCwd() + "/shaders/";
		final vertexSource = sys.io.File.getContent(path + "fullscreen.vert");
		final fragmentSource = sys.io.File.getContent(path + "demo.frag");

		final program = createProgram(vertexSource, fragmentSource);
		final vao = GL.createVertexArray();

		GL.bindVertexArray(vao);
		GL.useProgram(program);

		final timeUniform = GL.getUniformLocation(program, "uTime");
		final resolutionUniform = GL.getUniformLocation(program, "uResolution");
		final mouseUniform = GL.getUniformLocation(program, "uMouse");

		final event = new Event();

		var mouseX = window.width * 0.5;
		var mouseY = window.height * 0.5;
		var running = true;

		var frames = 0;
		var fps = 0;

		var fpsTime = Platform.getTime();

		while (running) {
			while (Platform.pollEvent(event)) {
				switch (event.type) {
					case EventType.Quit:
						running = false;

					case EventType.MouseMove:
						mouseX = event.mouseX;
						mouseY = event.mouseY;

					case EventType.KeyDown if (event.scanCode == F11_SCANCODE && !event.keyRepeat):
						window.displayMode = window.displayMode == WindowMode.WindowedFullscreen ? WindowMode.Windowed : WindowMode.WindowedFullscreen;

					default:
				}
			}

			final width = window.width;
			final height = window.height;

			GL.viewport(0, 0, width, height);

			GL.clearColor(0.02, 0.025, 0.05, 1.0);
			GL.clear(GL.COLOR_BUFFER_BIT);

			GL.useProgram(program);

			GL.uniform1f(timeUniform, Platform.getTime());
			GL.uniform2f(resolutionUniform, width, height);

			// SDL mouse coordinates start at the top-left, while OpenGL starts at the bottom-left
			GL.uniform2f(mouseUniform, mouseX, height - mouseY);
			GL.drawArrays(GL.TRIANGLES, 0, 3);

			context.present();

			// fps counter
			frames++;

			final now = Platform.getTime();
			final elapsed = now - fpsTime;

			if (elapsed >= 0.15) {
				fps = Math.round(frames / elapsed);

				frames = 0;
				fpsTime = now;

				window.title = 'LIMEN GL Example | $fps FPS';
			}
		}

		GL.deleteVertexArray(vao);
		GL.deleteProgram(program);

		context.destroy();
		window.destroy();

		Platform.quit();
	}

	static function createProgram(vertexSource:String, fragmentSource:String):Program {
		final vertex = compileShader(GL.VERTEX_SHADER, vertexSource);
		final fragment = compileShader(GL.FRAGMENT_SHADER, fragmentSource);

		final program = GL.createProgram();

		GL.attachShader(program, vertex);
		GL.attachShader(program, fragment);
		GL.linkProgram(program);

		if (GL.getProgramParameter(program, GL.LINK_STATUS) != 1)
			throw 'Failed to link shader:\n${GL.getProgramInfoLog(program)}';

		GL.deleteShader(vertex);
		GL.deleteShader(fragment);

		return program;
	}

	static function compileShader(type:Int, source:String):Shader {
		final shader = GL.createShader(type);

		GL.shaderSource(shader, source);
		GL.compileShader(shader);

		if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) != 1)
			throw 'Failed to compile shader:\n${GL.getShaderInfoLog(shader)}';

		return shader;
	}
}
