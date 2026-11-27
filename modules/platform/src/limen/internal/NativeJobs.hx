package limen.internal;

@:noDoc
@:noCompletion
@:allow(hxd.Pixels)
@:allow(h2d.SpriteBatch)
@:allow(hxd.System)
@:allow(h3d.scene.World)
class NativeJobs {
	static final workers = readWorkers();

	static function readWorkers():Int {
		final setting = Sys.getEnv("NMB_JOB_WORKERS");
		final value = setting == null ? null : Std.parseInt(setting);
		return value != null && value >= 0 && value <= 63 ? value : -1;
	}

	@:hlNative("limen", "stop_native_jobs")
	static function stop():Void {}

	@:hlNative("limen", "cull_world_boxes")
	static function cullWorldBoxes(bytes:hl.Bytes, length:Int, count:Int, checkNearFar:Bool, workers:Int):Bool {
		return false;
	}

	@:hlNative("limen", "world_cull_kernels")
	static function worldCullKernels():Int { return 1; }

	@:hlNative("limen", "cull_world_boxes_soa")
	static function cullWorldBoxesSoa(bytes:hl.Bytes, length:Int, count:Int, checkNearFar:Bool,
		workers:Int, implementation:Int):Bool {
		return false;
	}

	@:hlNative("limen", "build_sprite_geometry")
	static function buildSpriteGeometry(buffer:hl.Bytes, size:Int, count:Int, workers:Int):Void {
		throw "Limen was built without native sprite geometry";
	}

	@:hlNative("limen", "decode_dxt_jobs")
	static function decodeDxt(input:hl.Bytes, length:Int, offset:Int, output:hl.Bytes, outputLength:Int,
		width:Int, height:Int, format:Int, workers:Int):Bool {
		return false;
	}
}
