import hashlib
import pathlib
import re
import stat
import sys

PLATFORMS = ("windows-x64", "windows-x64-mingw", "linux-x64", "linux-arm64", "macos-x64", "macos-arm64")

def main():
	source, platform, commit, output = sys.argv[1:]
	if platform not in PLATFORMS or not re.fullmatch(r"[0-9a-f]{40}", commit):
		raise ValueError("invalid release platform or commit")
	source = pathlib.Path(source)
	records = []
	for file in sorted(source.rglob("*")):
		mode = file.lstat().st_mode
		if stat.S_ISLNK(mode) or not (stat.S_ISDIR(mode) or stat.S_ISREG(mode)):
			raise ValueError(f"unsupported release entry: {file}")
		if stat.S_ISDIR(mode):
			continue
		path = file.relative_to(source).as_posix()
		if (len(path) > 512 or any(part in ("", ".", "..") for part in path.split("/"))
				or any(ord(ch) < 32 or ord(ch) > 126 or ch in '\\:<>"|?*' for ch in path)
				or path.startswith((".hl-", ".limen-"))):
			raise ValueError(f"unsafe release path: {path}")
		with file.open("rb") as stream:
			digest = hashlib.file_digest(stream, "sha256").hexdigest()
		flags = "executable" if mode & 0o111 else "-"
		records.append(f"{digest}\t{file.stat().st_size}\t{flags}\t{path}\n")
	if not (source / "limen.hdll").is_file():
		raise ValueError("release has no limen.hdll")
	pathlib.Path(output).write_text(
		f"format\t1\nplatform\t{platform}\ncommit\t{commit}\n\n" + "".join(records),
		encoding="utf-8", newline="\n",
	)

if __name__ == "__main__":
	main()
