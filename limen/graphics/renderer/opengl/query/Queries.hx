package limen.graphics.renderer.opengl.query;

abstract Query(Null<Int>) {}

@:hlNative("limen", "opengl_gl_")
class Queries {
	public static function createQuery():Query {
		return null;
	}

	public static function deleteQuery(q:Query) {}

	public static function beginQuery(target:Int, q:Query) {}

	public static function endQuery(target:Int) {}

	public static function queryResultAvailable(q:Query) {
		return false;
	}

	public static function queryResult(q:Query):Float {
		return 0.;
	}

	public static function queryCounter(q:Query, target:Int) {}

	public static inline final SAMPLES_PASSED = 0x8914;
	public static inline final TIMESTAMP = 0x8E28;
	public static inline final TIME_ELAPSED = 0x88BF;
}
