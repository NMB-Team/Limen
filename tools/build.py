#!/usr/bin/env python3
import argparse
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path

MODULES = ("opengl", "vulkan", "d3d11", "d3d12", "fsr", "dlss")


def resolve_modules(selection):
	requested = {name.strip().lower() for name in selection.split(",")}
	unknown = requested.difference((*MODULES, "platform"))
	if unknown:
		valid = ", ".join(("platform", *MODULES))
		raise ValueError(f"unknown module(s): {', '.join(repr(name) for name in sorted(unknown))}. Choose from {valid}")

	requested.discard("platform")
	resolved = requested.copy()
	if "fsr" in resolved and resolved.isdisjoint(("d3d12", "vulkan")):
		resolved.add("vulkan")
	if "dlss" in resolved and resolved.isdisjoint(("d3d11", "d3d12", "vulkan")):
		resolved.add("vulkan")

	added = resolved - requested
	if added:
		print(f"Added backend dependencies: {', '.join(sorted(added))}", flush=True)
	return resolved


def installed_paths(manifest, output):
	if not manifest.is_file():
		return set()

	output = output.resolve()
	paths = (Path(line) for line in manifest.read_text(encoding="utf-8").splitlines() if line)
	paths = (path.parent.resolve() / path.name for path in paths)
	return {path for path in paths if output in path.parents}


def install_native(root, build, output, config, modules):
	manifest = build / "install_manifest.txt"
	previous = installed_paths(manifest, output)
	subprocess.run(["cmake", "--install", str(build), "--config", config, "--prefix", str(output)], cwd=root, check=True)
	current = installed_paths(manifest, output)

	if modules is not None:
		expected = {"limen.hdll", *(f"{name}.limen" for name in modules)}
		actual = {path.name for path in current if path.suffix in (".limen", ".hdll") and path.is_file()}
		if actual != expected:
			raise ValueError(f"expected native files [{', '.join(sorted(expected))}], found [{', '.join(sorted(actual))}]")

	for obsolete in previous - current:
		obsolete.unlink(missing_ok=True)


def run_tests(root, build, config, selection):
	command = ["ctest", "--test-dir", str(build), "-C", config]
	if selection != "all":
		command.extend(["-L", f"^{selection}$"])

	result = subprocess.run([*command, "--show-only=json-v1"], cwd=root, check=True, capture_output=True, text=True)
	if not json.loads(result.stdout)["tests"]:
		raise ValueError(f"no CTest tests registered for {selection}")

	subprocess.run([*command, "--output-on-failure"], cwd=root, check=True)


def main():
	parser = argparse.ArgumentParser(description="Build Limen and open the compiled binaries folder")
	parser.add_argument("--preset", help="CMake configure preset (auto-detected by default)")
	parser.add_argument("--jobs", type=int, help="maximum parallel build jobs")
	parser.add_argument("--config", choices=("Release", "Debug"))
	parser.add_argument("--hashlink-root", type=Path)
	parser.add_argument("--hashlink-library", type=Path)
	parser.add_argument("--no-open", action="store_true")
	parser.add_argument("--modules", help="comma-separated native modules; use platform for limen.hdll alone")
	parser.add_argument("--test", nargs="?", const="all", choices=("all", "platform", "integration", *MODULES),
		help="enable and run CTest, optionally for one module")
	parser.add_argument("cmake_args", nargs=argparse.REMAINDER, help="extra CMake options after --")
	args = parser.parse_args()
	config = args.config or ("Debug" if args.preset and args.preset.endswith("-debug") else "Release")

	root = Path(__file__).resolve().parent.parent
	system = platform.system()
	if system not in ("Windows", "Linux", "Darwin"):
		parser.error("this launcher supports Windows, Linux, and macOS")
	if args.jobs is not None and args.jobs < 1:
		parser.error("--jobs must be positive")

	if system == "Darwin":
		host = "macos-arm64" if platform.machine().lower() in ("arm64", "aarch64") else "macos-x64"
	elif system == "Windows":
		host = "windows-arm64" if platform.machine().lower() in ("arm64", "aarch64") else "windows-x64"
	else:
		host = "linux"

	preset = args.preset or host + "-" + config.lower()
	selection = args.modules
	if selection is None and args.test not in (None, "all", "integration"):
		selection = args.test

	modules = resolve_modules(selection) if selection is not None else None
	profile = preset
	if modules is not None:
		if args.test in MODULES and args.test not in modules:
			parser.error(f"--test {args.test} requires {args.test} to be enabled")
		profile += "-" + ("-".join(sorted(modules)) or "platform")

	build = root / "build" / "launcher" / profile
	output = root / "build" / "bin" / profile
	configure = ["cmake", "--preset", preset, "-B", str(build), "-DHDLL_DESTINATION=."]
	if modules is not None:
		configure.append(f"-DLIMEN_BUILD_VMA={'ON' if 'vulkan' in modules else 'OFF'}")

	hashlink = args.hashlink_root
	if hashlink is None and not (build / "CMakeCache.txt").exists():
		hashlink = Path(os.environ.get("LIMEN_HASHLINK_ROOT", root.parent / "hashlink-nmb"))
	if hashlink is not None:
		configure.append(f"-DLIMEN_HASHLINK_ROOT={hashlink.resolve()}")
	if args.hashlink_library is not None:
		configure.append(f"-DLIMEN_HASHLINK_LIBRARY={args.hashlink_library.resolve()}")

	extra = args.cmake_args
	configure.extend(extra[1:] if extra[:1] == ["--"] else extra)
	if modules is not None:
		configure.extend(f"-DLIMEN_BUILD_{name.upper()}={'ON' if name in modules else 'OFF'}" for name in MODULES)
	if args.test:
		configure.append("-DLIMEN_BUILD_TESTS=ON")

	subprocess.run(configure, cwd=root, check=True)
	command = ["cmake", "--build", str(build), "--config", config]

	jobs = args.jobs or (1 if system == "Windows" else min(8, os.cpu_count() or 1))
	command.extend(["--parallel", str(jobs)])
	subprocess.run(command, cwd=root, check=True)
	if args.test:
		run_tests(root, build, config, args.test)

	install_native(root, build, output, config, modules)
	print(f"Binaries: {output}", flush=True)

	if not args.no_open:
		if system == "Windows":
			os.startfile(output)
		elif system == "Darwin":
			subprocess.run(["open", str(output)], check=True)
		elif shutil.which("xdg-open") and (os.environ.get("DISPLAY") or os.environ.get("WAYLAND_DISPLAY")):
			subprocess.run(["xdg-open", str(output)], check=True)

if __name__ == "__main__":
	try:
		main()
	except subprocess.CalledProcessError as error:
		sys.exit(error.returncode)
	except (OSError, ValueError) as error:
		sys.exit(f"error: {error}")
