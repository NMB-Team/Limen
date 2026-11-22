#!/usr/bin/env python3
import argparse
import tempfile
import zipfile
from pathlib import Path


def collect_sources(root):
	files = {name.casefold(): (name, root / name) for name in ("haxelib.json", "LICENSE", "README.md")}
	directories = {}
	source_roots = set()

	for classpath in sorted((root / "modules").rglob("haxe")):
		for source in sorted(classpath.rglob("*")):
			relative = source.relative_to(classpath)
			name = relative.as_posix()
			key = name.casefold()

			if source.is_dir():
				existing = directories.setdefault(key, name)
				if existing != name or key in files:
					raise ValueError(f"Conflicting package directory: {source.relative_to(root)}")
				continue

			if source.suffix == ".hx":
				source_roots.add(classpath.relative_to(root).as_posix())
			elif not source.name.startswith("LICENSE"):
				continue

			if key in files:
				_, previous = files[key]
				raise ValueError(f"Duplicate package path {name}: {previous.relative_to(root)} and {source.relative_to(root)}")
			if key in directories:
				raise ValueError(f"Package file conflicts with a directory: {source.relative_to(root)}")

			files[key] = (name, source)

	workspace = (root / "workspace.hxml").read_text(encoding="utf-8").splitlines()
	classpaths = [line[4:] for line in map(str.strip, workspace) if line.startswith("-cp ")]
	if sorted(classpaths) != sorted(source_roots):
		expected = ", ".join(sorted(source_roots))
		raise ValueError(f"workspace.hxml must list each Haxe source root once. Expected: {expected}")

	return sorted(files.values())


def main():
	root = Path(__file__).resolve().parent.parent
	parser = argparse.ArgumentParser(description="Build the Limen Haxelib source archive")
	parser.add_argument("--output", type=Path, default=root / "build" / "haxelib" / "limen.zip")
	output = parser.parse_args().output.resolve()

	try:
		sources = collect_sources(root)
		output.parent.mkdir(parents=True, exist_ok=True)

		with tempfile.TemporaryDirectory(dir=output.parent) as staging:
			archive_path = Path(staging) / "limen.zip"
			with zipfile.ZipFile(archive_path, "w", zipfile.ZIP_DEFLATED) as archive:
				for name, source in sources:
					archive.write(source, name)

			archive_path.replace(output)
	except (OSError, ValueError) as error:
		parser.exit(1, f"error: {error}\n")

	print(output)


if __name__ == "__main__":
	main()
