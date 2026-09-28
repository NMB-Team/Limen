package;

import limen.graphics.renderer.opengl.OpenGL;
import limen.graphics.renderer.opengl.command.Commands;
import limen.graphics.renderer.opengl.format.Formats;
import limen.graphics.renderer.opengl.resource.Textures;
import limen.graphics.renderer.opengl.shader.Shaders;
import limen.graphics.renderer.opengl.shader.Shaders.Shader;
import limen.graphics.renderer.opengl.vertex.VertexArrays;
import limen.platform.Platform;
import limen.platform.event.Event;
import limen.platform.event.EventType;
import limen.platform.event.WindowStateChange;
import limen.platform.input.pen.PenAxis;
import limen.platform.input.pen.PenInputFlags;
import limen.platform.window.Window;
import limen.platform.window.WindowFlags;

private typedef PointerState = {x:Float, y:Float, pressure:Float, down:Bool}

class ExampleTouchPen {
	static inline final WIDTH = 960;
	static inline final HEIGHT = 640;
	static final pixels = new hl.Bytes(WIDTH * HEIGHT);
	static var dirty = true;
	static var input = "Draw with a pen or finger";
	static var pressure = 0.0;
	static var titleDirty = true;

	static function main() {
		Platform.init(OpenGL);

		final window = Window.create({
			title: "LIMEN Pressure Paint | Space/C: clear | Esc: quit",
			width: WIDTH,
			height: HEIGHT,
			flags: WindowFlags.SDL_WINDOW_OPENGL,
			resizable: true
		});

		final context = OpenGL.create(window, {minimumMajor: 3, minimumMinor: 3, flags: OpenGL.DOUBLE_BUFFER | OpenGL.COMPATIBILITY_PROFILE});
		final shaderHeader = Platform.isMobile ? "#version 300 es\nprecision highp float;\n" : "#version 330 core\n";
		final vertex = compileShader(Shaders.VERTEX_SHADER, shaderHeader
			+ '
			out vec2 uv;
			void main() {
				vec2 p = vec2((gl_VertexID << 1) & 2, gl_VertexID & 2);
				uv = vec2(p.x, 1.0 - p.y);
				gl_Position = vec4(p * 2.0 - 1.0, 0.0, 1.0);
			}
		');
		final fragment = compileShader(Shaders.FRAGMENT_SHADER, shaderHeader
			+ '
			in vec2 uv;
			uniform sampler2D canvas;
			out vec4 color;
			void main() {
				color = vec4(vec3(texture(canvas, uv).r), 1.0);
			}
		');

		final program = Shaders.createProgram();
		Shaders.attachShader(program, vertex);
		Shaders.attachShader(program, fragment);
		Shaders.linkProgram(program);
		if (Shaders.getProgramParameter(program, Shaders.LINK_STATUS) != 1)
			throw 'Failed to link shader:\n${Shaders.getProgramInfoLog(program)}';
		Shaders.deleteShader(vertex);
		Shaders.deleteShader(fragment);
		Shaders.useProgram(program);
		Shaders.uniform1i(Shaders.getUniformLocation(program, "canvas"), 0);

		final vao = VertexArrays.createVertexArray();
		VertexArrays.bindVertexArray(vao);

		final texture = Textures.createTexture();
		Textures.activeTexture(Textures.TEXTURE0);
		Textures.bindTexture(Textures.TEXTURE_2D, texture);
		Textures.texParameteri(Textures.TEXTURE_2D, Textures.TEXTURE_MIN_FILTER, Textures.LINEAR);
		Textures.texParameteri(Textures.TEXTURE_2D, Textures.TEXTURE_MAG_FILTER, Textures.LINEAR);
		Textures.texParameteri(Textures.TEXTURE_2D, Textures.TEXTURE_WRAP_S, Textures.CLAMP_TO_EDGE);
		Textures.texParameteri(Textures.TEXTURE_2D, Textures.TEXTURE_WRAP_T, Textures.CLAMP_TO_EDGE);

		clear(); // clear to prevent drawings after start

		Textures.texImage2D(Textures.TEXTURE_2D, 0, Formats.R8, WIDTH, HEIGHT, 0, Formats.RED, Formats.UNSIGNED_BYTE, pixels);
		dirty = false;

		final fingers:Map<String, PointerState> = [];
		final pens:Map<Int, PointerState> = [];
		final event = new Event();

		var running = true;
		while (running) {
			while (Platform.pollEvent(event)) {
				if (event.windowId != 0 && event.windowId != window.id)
					continue;
				switch (event.type) {
					case EventType.Quit:
						running = false;
					case EventType.WindowState:
						if (event.state == WindowStateChange.Close)
							running = false;
						if (event.state == WindowStateChange.Blur) {
							fingers.clear();
							pens.clear();
						}
					case EventType.KeyDown if (!event.keyRepeat):
						switch (event.scanCode) {
							case 6, 44: clear();
							case 41: running = false;
							default:
						}
					case EventType.TouchDown, EventType.TouchMove, EventType.TouchUp, EventType.TouchCanceled:
						final key = '${event.touchId}:${event.fingerId}';
						final x = event.touchX * WIDTH;
						final y = event.touchY * HEIGHT;
						var finger = fingers.get(key);
						if (event.type == EventType.TouchDown) {
							finger = {
								x: x,
								y: y,
								pressure: event.pressure,
								down: true
							};
							fingers.set(key, finger);
						}
						if (finger != null && event.type != EventType.TouchCanceled)
							stroke(finger, x, y, event.type == EventType.TouchUp ? finger.pressure : event.pressure);
						if (event.type == EventType.TouchUp || event.type == EventType.TouchCanceled)
							fingers.remove(key);
						showPressure("Touch", event.pressure);
					case EventType.PenDown, EventType.PenMove, EventType.PenUp, EventType.PenAxis:
						if (event.type == EventType.PenAxis && event.penAxis != PenAxis.Pressure)
							continue;
						final x = event.penX * WIDTH / window.width;
						final y = event.penY * HEIGHT / window.height;
						var pen = pens.get(event.penId);
						if (pen == null) {
							pen = {
								x: x,
								y: y,
								pressure: 0.0,
								down: false
							};
							pens.set(event.penId, pen);
						}
						final p = event.type == EventType.PenAxis ? event.penValue : pen.pressure;
						final down = event.type != EventType.PenUp && event.penState.has(PenInputFlags.Down);
						if (!pen.down) {
							pen.x = x;
							pen.y = y;
							pen.pressure = p;
						}
						if (down || (pen.down && event.type == EventType.PenUp))
							stroke(pen, x, y, p);
						pen.pressure = event.type == EventType.PenUp ? 0.0 : p;
						pen.down = down;
						showPressure("Pen", pen.pressure);
					case EventType.PenProximityOut:
						pens.remove(event.penId);
						showPressure("Pen", 0.0);
					default:
				}
			}
			if (!running)
				break;
			if (titleDirty) {
				window.title = 'LIMEN Pressure Paint | $input | Pressure: ${Math.round(pressure * 100)}% | Brush: ${Math.round(2 + pressure * 30)} px | Space/C: clear | Esc: quit';
				titleDirty = false;
			}
			if (dirty) {
				Textures.texSubImage2D(Textures.TEXTURE_2D, 0, 0, 0, WIDTH, HEIGHT, Formats.RED, Formats.UNSIGNED_BYTE, pixels);
				dirty = false;
			}
			Commands.viewport(0, 0, window.pixelWidth, window.pixelHeight);
			Commands.drawArrays(Commands.TRIANGLES, 0, 3);
			context.present();
			Platform.delay(8);
		}

		Textures.deleteTexture(texture);
		VertexArrays.deleteVertexArray(vao);
		Shaders.deleteProgram(program);
		context.destroy();
		window.destroy();
		Platform.quit();
	}

	static function clear() {
		for (i in 0...WIDTH * HEIGHT)
			pixels[i] = 255;
		dirty = true;
	}

	static function showPressure(source:String, value:Float) {
		input = source;
		pressure = Math.max(0, Math.min(1, value));
		titleDirty = true;
	}

	static function stroke(pointer:PointerState, x:Float, y:Float, value:Float) {
		final p = Math.max(0, Math.min(1, value));
		final dx = x - pointer.x;
		final dy = y - pointer.y;
		final steps = Std.int(Math.max(1, Math.ceil(Math.sqrt(dx * dx + dy * dy))));

		for (i in 0...steps + 1) {
			final t = i / steps;
			final radius = 1 + (pointer.pressure + (p - pointer.pressure) * t) * 15;
			final cx = pointer.x + dx * t;
			final cy = pointer.y + dy * t;

			final left = Std.int(Math.max(0, Math.floor(cx - radius)));
			final right = Std.int(Math.min(WIDTH - 1, Math.ceil(cx + radius)));
			final top = Std.int(Math.max(0, Math.floor(cy - radius)));
			final bottom = Std.int(Math.min(HEIGHT - 1, Math.ceil(cy + radius)));

			for (py in top...bottom + 1) {
				for (px in left...right + 1) {
					final ox = px + 0.5 - cx;
					final oy = py + 0.5 - cy;
					if (ox * ox + oy * oy <= radius * radius)
						pixels[py * WIDTH + px] = 0;
				}
			}
		}

		pointer.x = x;
		pointer.y = y;

		pointer.pressure = p;
		dirty = true;
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
