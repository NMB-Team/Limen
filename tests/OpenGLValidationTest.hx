import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class OpenGLValidationTest {
	static function main():Void {
		final args = Sys.args();
		final source = File.getContent(args[0]);
		final validator = args[1];
		final directory = args[2];
		FileSystem.createDirectory(directory);

		final vertexPattern = ~/Shaders.shaderSource\(vertex, \[versionDirective, "([^"]+)"\]/;
		if (!vertexPattern.match(source))
			throw "Could not find the validation vertex shader";
		final vertex = vertexPattern.matched(1);

		final start = source.indexOf("final fragmentSource =");
		final end = source.indexOf("Shaders.shaderSource(fragment,", start);
		final fragments = [];
		final literal = ~/"([^"]*)"/;
		var remaining = source.substring(start, end);
		while (literal.match(remaining)) {
			fragments.push(literal.matched(1));
			remaining = literal.matchedRight();
		}
		if (fragments.length != 3)
			throw "Expected three validation fragment shader templates";

		for (es in [true, false]) {
			final versions = es ? [100, 300, 310, 320] : [120, 130, 140, 150, 330, 400, 410, 420, 430, 440, 450, 460];
			for (version in versions) {
				final directive = "#version " + version + (es && version >= 300 ? " es" : "") + "\n";
				final fragment = fragments[es && version < 300 ? 0 : !es && version < 130 ? 1 : 2];
				final path = directory + "/" + (es ? "es" : "gl") + version;
				File.saveContent(path + ".vert", directive + vertex);
				File.saveContent(path + ".frag", directive + fragment);

				final process = new Process(validator, ["-l", path + ".vert", path + ".frag"]);
				final output = process.stdout.readAll().toString() + process.stderr.readAll().toString();
				final code = process.exitCode();
				process.close();
				if (code != 0)
					throw directive + output;
				Sys.println("Validated " + StringTools.trim(directive) + (es ? " GLES" : " desktop"));
			}
		}
	}
}
