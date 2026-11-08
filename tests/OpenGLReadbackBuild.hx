import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;

class OpenGLReadbackBuild {
	public static macro function build(path:String, names:Array<String>):Array<Field> {
		final fields = Context.getBuildFields();
		final source = File.getContent(Context.resolvePath(path));
		// exercise the production methods with context and GL failures injected
		for (name in names) {
			final pattern = new EReg("(?:override )?function " + name + "\\(", "");
			if (!pattern.match(source)) Context.fatalError("Missing method " + name, Context.currentPos());
			final start = pattern.matchedPos().pos;
			final bodyStart = source.indexOf("{", start);
			var end = bodyStart + 1;
			var depth = 1;
			while (depth > 0) {
				switch (source.charAt(end++)) {
					case "{": depth++;
					case "}": depth--;
					default:
				}
			}
			var method = source.substring(start, end);
			for (directive in ["#if (hl && limen)", "#end"])
				method = StringTools.replace(method, directive, "");
			method = StringTools.replace(method, "override function", "function");
			method = StringTools.replace(method, "b:h3d.Buffer", "b:Dynamic");
			method = StringTools.replace(method, "haxe.MainLoop.MainEvent", "TestEvent");
			method = StringTools.replace(method, "haxe.MainLoop.add", "TestEvent.add");
			method = StringTools.replace(method, "h3d.Engine.getCurrent", "TestEngine.getCurrent");
			method = StringTools.replace(method, "OpenGLDriver", "TestDriver");
			final expression = Context.parse("function" + method.substr(method.indexOf("(", method.indexOf("function"))), Context.currentPos());
			switch (expression.expr) {
				case EFunction(_, fn):
					fields.push({ name: name, access: name == "dispose" ? [APublic, AOverride] : [APublic], kind: FFun(fn), pos: Context.currentPos() });
				default: Context.fatalError("Expected method " + name, Context.currentPos());
			}
		}
		return fields;
	}
}
