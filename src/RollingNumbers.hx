import math.Utils;

class StringUtils {
	public static function commify(number: Float, precision: Float = 0.0001): String {
		var int_part = Math.floor(number);
		var dec_part = Utils.round(number - int_part, precision);
		var suffix = "";
		if (dec_part > 0) {
			suffix = Std.string(dec_part).substr(1);
		}
		var r = "" + int_part;
		var i = r.length - 3;
		while (i > 0) {
			r = r.substr(0, i) + "," + r.substr(i);
			i -= 3;
		}
		return r + suffix;
	}
}

abstract RollingNumbers({
	progress: Float,
	time: Float,
	duration: Float,
	start: Float,
	finish: Float,
	interp: Float->Float->Float->Float
}) {
	public function new(start: Float, finish: Float, duration: Float) {
		this = {
			start: start,
			finish: finish,
			duration: duration,
			progress: 0.0,
			time: 0.0,
			interp: Utils.lerp
		}
	}

	public function reset(?start, ?finish) {
		if (start != null) {
			this.start = start;
		}
		if (finish != finish) {
			this.finish = finish;
		}
		this.progress = 0.0;
		this.time = 0.0;
	}

	public function update(dt: Float) {
		this.time += dt;
		if (this.time >= this.duration) {
			this.time = this.duration;
		}
		if (this.duration > 0.0) {
			this.progress = this.time / this.duration;
		}
	}

	public var value(get, never): Float;
	@:to
	function get_value() {
		return this.interp(this.start, this.finish, this.progress);
	}

	@:to
	public function toString() {
		var self: RollingNumbers = cast this;
		return StringUtils.commify(self.value, 1);
	}
}
