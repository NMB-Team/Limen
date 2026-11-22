package limen.platform.system.dialog;

import limen.platform.internal.SDLBindings;

class FileDialog {
	public static function openFile(callback:FileDialogResult -> Void, ?options:FileDialogOptions):Void {
		final filters = prepareFilters(options?.filters);
		SDLBindings.showOpenFileDialog(resultCallback(callback), options?.parent?.nativeHandle, filters.names, filters.patterns, utf8(options?.defaultLocation), options?.allowMultiple == true);
	}

	public static function openFolder(callback:FileDialogResult -> Void, ?options:FileDialogOptions):Void {
		SDLBindings.showOpenFolderDialog(resultCallback(callback), options?.parent?.nativeHandle, utf8(options?.defaultLocation), options?.allowMultiple == true);
	}

	public static function saveFile(callback:FileDialogResult -> Void, ?options:FileDialogOptions):Void {
		final filters = prepareFilters(options?.filters);
		SDLBindings.showSaveFileDialog(resultCallback(callback), options?.parent?.nativeHandle, filters.names, filters.patterns, utf8(options?.defaultLocation));
	}

	static function resultCallback(callback:FileDialogResult -> Void):Int -> hl.NativeArray<hl.Bytes> -> hl.Bytes -> Int -> Void {
		return (status, nativePaths, nativeError, selectedFilter) -> {
			if (status == 1) {
				final paths = [for (path in nativePaths) @:privateAccess String.fromUTF8(path)];
				callback(Selected(paths, selectedFilter < 0 ? null : selectedFilter));
			} else if (status == 0)
				callback(Cancelled);
			else
				callback(Failed(nativeError == null ? "Unknown SDL file dialog error" : @:privateAccess String.fromUTF8(nativeError)));
		};
	}

	static function prepareFilters(filters:Array<FileDialogFilter>):NativeFilters {
		if (filters == null || filters.length == 0)
			return {names: null, patterns: null};

		final names = new hl.NativeArray<hl.Bytes>(filters.length);
		final patterns = new hl.NativeArray<hl.Bytes>(filters.length);
		for (index in 0...filters.length) {
			names[index] = @:privateAccess filters[index].name.toUtf8();
			patterns[index] = @:privateAccess filters[index].pattern.toUtf8();
		}
		return {names: names, patterns: patterns};
	}

	static inline function utf8(value:String):hl.Bytes {
		return value == null ? null : @:privateAccess value.toUtf8();
	}
}

private typedef NativeFilters = {
	names:hl.NativeArray<hl.Bytes>,
	patterns:hl.NativeArray<hl.Bytes>
}
