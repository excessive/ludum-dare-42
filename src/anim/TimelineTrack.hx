package anim;

import math.Vec3;
import math.Quat;
import math.Utils;

typedef Keyframe<T> = {
	time: Float,
	value: T,
	interp: TweenType,
	?callback: Void->Void,
	?data: Dynamic
}

typedef SampledFrame = {
	position: Vec3,
	rotation: Quat,
	scale: Vec3,
	value: Map<String, Float>,
	callback: Null<Void->Void>,
	data: Dynamic
}

typedef TweenFn = Float->Float;

typedef TimelineSample<T> = {
	mix: Float,
	value: T,
	?callback: Void->Void,
	?data: Dynamic
}

@:forward
@:arrayAccess
abstract TimelineChannel<T>(Array<Keyframe<T>>) {
	public inline function new() {
		this = [];
	}

	inline function tween_for(type: TweenType): TweenFn {
		inline function out(f: TweenFn) {
			return function(s: Float): Float { return 1 - f(1-s); };
		}
		inline function chain(f1: TweenFn, f2: TweenFn) {
			return function(s: Float): Float { return (s < .5 ? f1(2*s) : 1 + f2(2*s-1)) * .5; }
		}
		function quad(t: Float) {
			return t*t;
		}
		function cubic(t: Float) {
			return t*t*t;
		}

		return switch(type) {
			case Constant: return function(t) { return 0; }
			case Linear: return function(t) { return t; }
			case InQuad: return quad;
			case InCubic: return cubic;
			case OutQuad: return out(quad);
			case OutCubic: return out(cubic);
			case SmoothQuad: return chain(quad, out(quad));
			case SmoothCubic: return chain(cubic, out(cubic));
		}
	}

	public function sample(time: Float, _default: T, lerp: T->T->Float->T): TimelineSample<T> {
		if (this.length == 0) {
			return {
				mix: 1,
				value: _default
			}
		}
		var f = this[this.length-1];
		var first = f.value;
		var fn    = f.interp;
		var cb    = f.callback;
		var data  = f.data;
		var then = 0.0;
		// store previous time/value until we hit greater, then figure out how
		// close we are and return that.
		for (value in this) {
			var now = value.time;
			var last = value.value;
			if (now > time) {
				var diff = now - then;
				var progress = time - then;
				var curve = tween_for(fn);
				var mix = curve(progress / diff);
				return {
					mix: mix,
					value: lerp(first, last, mix),
					callback: cb,
					data: data
				}
			}
			fn = value.interp;
			cb = value.callback;
			data = value.data;
			then = now;
			first = last;
		}
		return {
			mix: 0,
			value: first
		}
	}
}

class TimelineTrack {
	var positions = new TimelineChannel<Vec3>();
	var rotations = new TimelineChannel<Quat>();
	var scales = new TimelineChannel<Vec3>();
	var values = new Map<String, TimelineChannel<Float>>();
	public var length: Float = 0.0;
	public var framerate: Float = 30.0;
	public var time: Float = 0.0;
	public var loop: Bool = true;
	public var name: String = "<unknown>";

	public inline function new() {}

	public inline function add_keyframe_position(keyframe: Keyframe<Vec3>) {
		positions.push(keyframe);
	}

	public inline function add_keyframe_rotation(keyframe: Keyframe<Quat>) {
		rotations.push(keyframe);
	}

	public inline function add_keyframe_scale(keyframe: Keyframe<Vec3>) {
		scales.push(keyframe);
	}

	public function sample(time: Float): SampledFrame {
		var frame: SampledFrame = {
			position: this.positions.sample(time, new Vec3(0, 0, 0), Vec3.lerp).value,
			rotation: this.rotations.sample(time, new Quat(0, 0, 0, 1), Quat.slerp).value,
			scale: this.scales.sample(time, new Vec3(1, 1, 1), Vec3.lerp).value,
			value: new Map(),
			data: null,
			callback: null
		};

		for (k in this.values.keys()) {
			var channel = this.values[k];
			frame.value[k] = channel.sample(time, 0.0, Utils.lerp).value;
		}

		return frame;
	}

	public function sanitize() {
		this.positions.sort(function(a, b) {
			var t0 = a.time;
			var t1 = b.time;
			return (t0 < t1) ? -1 : (t0 > t1) ? 1 : 0;
		});
		this.rotations.sort(function(a, b) {
			var t0 = a.time;
			var t1 = b.time;
			return (t0 < t1) ? -1 : (t0 > t1) ? 1 : 0;
		});
		this.scales.sort(function(a, b) {
			var t0 = a.time;
			var t1 = b.time;
			return (t0 < t1) ? -1 : (t0 > t1) ? 1 : 0;
		});
		for (channel in this.values) {
			channel.sort(function(a, b) {
				var t0 = a.time;
				var t1 = b.time;
				return (t0 < t1) ? -1 : (t0 > t1) ? 1 : 0;
			});
		}
	}

	public function duration(): Float {
		var len = 0.0;
		if ((this.positions.length + this.rotations.length + this.scales.length) == 0) {
			var found = false;
			for (v in this.values) {
				var val = v[v.length-1];
				len = Utils.max(val.time, len);
				found = true;
			}
			if (!found) {
				return 0.0;
			}
		}
		if (this.positions.length > 0) {
			len = Utils.max(len, this.positions[this.positions.length-1].time);
		}
		if (this.rotations.length > 0) {
			len = Utils.max(len, this.rotations[this.rotations.length-1].time);
		}
		if (this.scales.length > 0) {
			len = Utils.max(len, this.scales[this.scales.length-1].time);
		}
		return len;
	}
}
