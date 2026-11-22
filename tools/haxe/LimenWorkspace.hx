package tools.haxe;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.io.File;

class LimenWorkspace {
	public static function configure():Void {
		final source = Context.resolvePath("tools/haxe/LimenWorkspace.hx");
		final root = Path.directory(Path.directory(Path.directory(source)));
		final workspace = Path.join([root, "workspace.hxml"]);

		for (line in File.getContent(workspace).split("\n")) {
			final argument = StringTools.trim(line);
			if (StringTools.startsWith(argument, "-cp "))
				Compiler.addClassPath(Path.join([root, argument.substr(4)]));
		}
	}
}
#end
