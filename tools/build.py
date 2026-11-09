#!/usr/bin/env python3
import argparse
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path


def main():
	parser = argparse.ArgumentParser(description="Build Limen and open the compiled binaries folder")
	parser.add_argument("--preset", help="CMake configure preset (auto-detected by default)")
	parser.add_argument("--jobs", type=int, help="maximum parallel build jobs")
	parser.add_argument("--config", choices=("Release", "Debug"))
	parser.add_argument("--hashlink-root", type=Path)
	parser.add_argument("--hashlink-library", type=Path)
	parser.add_argument("--no-open", action="store_true")
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
	build = root / "build" / "launcher" / preset
	output = root / "build" / "bin" / preset
	configure = ["cmake", "--preset", preset, "-B", str(build), "-DHDLL_DESTINATION=."]

	hashlink = args.hashlink_root
	if hashlink is None and not (build / "CMakeCache.txt").exists():
		hashlink = Path(os.environ.get("LIMEN_HASHLINK_ROOT", root.parent / "hashlink-nmb"))
	if hashlink is not None:
		configure.append(f"-DLIMEN_HASHLINK_ROOT={hashlink.resolve()}")
	if args.hashlink_library is not None:
		configure.append(f"-DLIMEN_HASHLINK_LIBRARY={args.hashlink_library.resolve()}")

	extra = args.cmake_args
	configure.extend(extra[1:] if extra[:1] == ["--"] else extra)
	subprocess.run(configure, cwd=root, check=True)
	command = ["cmake", "--build", str(build), "--config", config]

	jobs = args.jobs or (1 if system == "Windows" else min(8, os.cpu_count() or 1))
	command.extend(["--parallel", str(jobs)])
	subprocess.run(command, cwd=root, check=True)
	subprocess.run(["cmake", "--install", str(build), "--config", config, "--prefix", str(output)], cwd=root, check=True)
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
	except OSError as error:
		sys.exit(str(error))
