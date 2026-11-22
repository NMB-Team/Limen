package limenbuild;

#if macro
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.io.File;

class Workspace {
	public static function addClassPaths():Void {
		final source = Context.resolvePath("limenbuild/Workspace.hx");
		final root = Path.join([Path.directory(source), "../../.."]);
		final workspace = Path.join([root, "workspace.hxml"]);

		for (line in File.getContent(workspace).split("\n")) {
			final argument = StringTools.trim(line);
			if (StringTools.startsWith(argument, "-cp "))
				Compiler.addClassPath(Path.join([root, argument.substr(4)]));
		}
	}
}
#end
