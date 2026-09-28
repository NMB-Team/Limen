package;

import limen.graphics.GraphicsDriver;
import limen.graphics.renderer.opengl.OpenGL;
import limen.graphics.renderer.opengl.shader.Shaders.Program;
import limen.graphics.renderer.opengl.shader.Shaders.Shader;
import limen.graphics.renderer.opengl.command.Commands;
import limen.graphics.renderer.opengl.shader.Shaders;
import limen.graphics.renderer.opengl.vertex.VertexArrays;
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

		final context = OpenGL.create(window, {
			minimumMajor: 3,
			minimumMinor: 3,
			flags: OpenGL.DOUBLE_BUFFER | OpenGL.CORE_PROFILE,
			presentMode: Immediate
		});

		final path = Sys.getCwd() + "/shaders/";
		final vertexSource = sys.io.File.getContent(path + "fullscreen.vert");
		final fragmentSource = sys.io.File.getContent(path + "demo.frag");

		final program = createProgram(vertexSource, fragmentSource);
		final vao = VertexArrays.createVertexArray();

		VertexArrays.bindVertexArray(vao);
		Shaders.useProgram(program);

		final timeUniform = Shaders.getUniformLocation(program, "uTime");
		final resolutionUniform = Shaders.getUniformLocation(program, "uResolution");
		final mouseUniform = Shaders.getUniformLocation(program, "uMouse");

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

			Commands.viewport(0, 0, width, height);

			Commands.clearColor(0.02, 0.025, 0.05, 1.0);
			Commands.clear(Commands.COLOR_BUFFER_BIT);

			Shaders.useProgram(program);

			Shaders.uniform1f(timeUniform, Platform.getTime());
			Shaders.uniform2f(resolutionUniform, width, height);

			// SDL mouse coordinates start at the top-left, while OpenGL starts at the bottom-left
			Shaders.uniform2f(mouseUniform, mouseX, height - mouseY);
			Commands.drawArrays(Commands.TRIANGLES, 0, 3);

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

		VertexArrays.deleteVertexArray(vao);
		Shaders.deleteProgram(program);

		context.destroy();
		window.destroy();

		Platform.quit();
	}

	static function createProgram(vertexSource:String, fragmentSource:String):Program {
		final vertex = compileShader(Shaders.VERTEX_SHADER, vertexSource);
		final fragment = compileShader(Shaders.FRAGMENT_SHADER, fragmentSource);

		final program = Shaders.createProgram();

		Shaders.attachShader(program, vertex);
		Shaders.attachShader(program, fragment);
		Shaders.linkProgram(program);

		if (Shaders.getProgramParameter(program, Shaders.LINK_STATUS) != 1)
			throw 'Failed to link shader:\n${Shaders.getProgramInfoLog(program)}';

		Shaders.deleteShader(vertex);
		Shaders.deleteShader(fragment);

		return program;
	}

	static function compileShader(type:Int, source:String):Shader {
		final shader = Shaders.createShader(type);

		Shaders.shaderSource(shader, source);
		Shaders.compileShader(shader);

		if (Shaders.getShaderParameter(shader, Shaders.COMPILE_STATUS) != 1)
			throw 'Failed to compile shader:\n${Shaders.getShaderInfoLog(shader)}';

		return shader;
	}
}
