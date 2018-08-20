import math.Mat4;
import math.Vec3;
import math.Quat;
import math.Utils;

typedef AnimInfo = {
	var name: String;
	var length: Int;
	var framerate: Float;
	var loop: Bool;
	var first: Int;
	var last: Int;
	var frames: Array<AnimFrame>;
}

typedef AnimTrack = {
	var name: String;
	var offset: Float;
	var weight: Float;
	var rate: Float;
	var callback: Null<Timeline->Void>;
	var lock: Bool;
	var early: Bool;
	var playing: Bool;
	var active: Bool;
	var frame: Int;
	var marker: Int;
	var blend: Float;
	var base: Int;
	var time: Float;
}

typedef AnimJoint = {
	var name: String;
	var parent: Int;
	var position: Vec3;
	var rotation: Quat;
	var scale: Vec3;
}

typedef AnimBone = {
	var translate: Vec3;
	var rotate: Quat;
	var scale: Vec3;
}

typedef AnimFrame = Array<AnimBone>;

typedef AnimData = {
	var skeleton: Array<AnimJoint>;
	var animations: Array<AnimInfo>;
}

class Timeline {
	var current_pose: Array<Mat4> = [];
	var current_matrices: Map<String, Mat4>;
	var timeline: Array<AnimTrack> = [];
	var timeline_lookup = new Map<AnimTrack, AnimTrack>();
	var animations = new Map<String, AnimInfo>();
	var time: Float = 0;
	var skeleton: Array<AnimJoint>;
	var inverse_base: Array<Mat4> = [];
	var bind_pose: Array<AnimBone>;

	static function calc_bone_matrix(pos: Vec3, rot: Quat, scale: Vec3): Mat4 {
		return Mat4.translate(pos) *
			Mat4.rotate(rot) *
			Mat4.scale(scale)
		;
	}

	static function convert_bind_pose(skeleton: Array<AnimJoint>): Array<AnimBone> {
		var pose = [];
		for (i in 0...skeleton.length) {
			pose.push({
				translate: skeleton[i].position,
				rotate:    skeleton[i].rotation,
				scale:     skeleton[i].scale
			});
		}
		return pose;
	}

	static function is_child(skeleton, bone, which) {
		var next = skeleton[bone];
		if (bone == which) {
			return true;
		}
		else if (next.parent < which) {
			return false;
		}
		else {
			return is_child(skeleton, next.parent, which);
		}
	}

	// this and mix_pose_new do the same thing, but this one dodges the allocations.
	// prefer this when working on temporary data.
	static function mix_pose_on(p1: Array<AnimBone>, p2: Array<AnimBone>, skeleton: Array<AnimJoint>, weight: Float, start: Int) {
		for (i in 0...skeleton.length) {
			var mix = weight;
			if (start > 0) {
				if (!is_child(skeleton, i, start)) {
					continue;
				}
			}
			var pose = p1[i];
			pose.translate = Vec3.lerp(pose.translate, p2[i].translate, mix);
			pose.rotate = Quat.slerp(p1[i].rotate, p2[i].rotate, mix);
			pose.rotate.normalize();
			pose.scale = Vec3.lerp(pose.scale, p2[i].scale, mix);
		}
	}

	static function copy_pose(pose: Array<AnimBone>): Array<AnimBone> {
		var out_pose = [];
		for (p in pose) {
			out_pose.push({
				translate: p.translate.copy(),
				rotate: p.rotate.copy(),
				scale: p.scale.copy()
			});
		}
		return out_pose;
	}

	static function update_matrices(skeleton: Array<AnimJoint>, base: Array<Mat4>, pose: Array<AnimBone>) {
		var animation_buffer = [];
		var transform = [];
		var bone_lookup = new Map<String, Mat4>();

		for (i in 0...skeleton.length) {
			var joint = skeleton[i];
			var m = calc_bone_matrix(pose[i].translate, pose[i].rotate, pose[i].scale);
			var render: Mat4;

			if (joint.parent > 0) {
				// assert(joint.parent < i)
				transform.push(m * transform[joint.parent]);
				render = base[i] * transform[i];
			}
			else {
				transform.push(m);
				render = base[i] * m;
			}

			bone_lookup[joint.name] = transform[i];
			animation_buffer.push(render);
		}
		animation_buffer.push(animation_buffer[animation_buffer.length-1]);

		return { buffer: animation_buffer, lookup: bone_lookup };
	}

	public function new(data: AnimData) {
		if (data.skeleton == null) {
			return;
		}

		// Calculate inverse base pose.
		for (i in 0...data.skeleton.length) {
			var joint = data.skeleton[i];
			var m = calc_bone_matrix(joint.position, joint.rotation, joint.scale);
			var inv = m.copy();
			inv.invert();

			if (joint.parent >= 0) {
				// assert(joint.parent < i);
				this.inverse_base.push(this.inverse_base[joint.parent] * inv);
			}
			else {
				this.inverse_base.push(inv);
			}
		}

		this.bind_pose = convert_bind_pose(data.skeleton);

		for (v in data.animations) {
			this.add_animation(v);
		}
	}

	/// Create a new track
	// @param name Name of animation for track
	// @param weight Percentage of total timeline blending being given to track
	// @param rate Playback rate of animation
	// @param callback Function to call after non-looping animation ends
	// @param lock Stops track from being affected by transition
	// @return table Track object
	function new_track(name: String, weight: Float = 1, rate: Float = 1, ?callback: Timeline->Void, lock: Bool = false, early: Bool = false): Null<AnimTrack> {
		if (this.animations.exists(name)) {
			return null;
		}
		return {
			name:     name,
			offset:   this.time,
			time:     this.time,
			weight:   weight,
			rate:     rate,
			callback: callback,
			lock:     lock,
			early:    early,
			playing:  false,
			active:   true,
			frame:    0,
			marker:   0,
			blend:    1,
			base:     1
		}
	}

	public function find_index(bone_name: String): Int {
		for (i in 0...this.skeleton.length) {
			var bone = this.skeleton[i];
			if (bone.name == bone_name) {
				return i;
			}
		}
		return 0;
	}

	/// Add animation to anim object
	// @param animation Animation data
	// @param frames Frame data
	function add_animation(animation: AnimInfo) {
		var new_anim: AnimInfo = {
			name:      animation.name,
			frames:    [],
			length:    animation.last - animation.first,
			framerate: animation.framerate,
			loop:      animation.loop,
			first:     0,
			last:      animation.frames.length
		};

		for (i in animation.first...animation.last) {
			new_anim.frames.push(animation.frames[i]);
		}
		this.animations[new_anim.name] = new_anim;
	}
	
	/// Add track to timeline
	// @param track Track object to play
	// @return table Track object
	public function play(track: AnimTrack) {
		// assert(this.timeline[track] == null);
		track.playing = true;
		track.offset = this.time;
		track.time = this.time;

		this.timeline.push(track);
		this.timeline_lookup[track] = track;
		return track;
	}

	/// Remove track from timeline
	// @param track Track to remove from timeline (optional). If not specified, removes all.
	public function stop(?track: AnimTrack) {
		if (track != null) {
			// assert(this.timeline[track]);
			return;
		}
		var i = this.timeline.length;
		while (--i >= 0) {
			if (this.timeline[i] == track || track == null) {
				this.timeline.remove(this.timeline[i]);
				this.timeline.splice(i, 1);
				break;
			}
		}
	}

	/// Get length of animation
	// @param name Name of animation
	// @return number Length of animation (in seconds)
	public function length(name: String): Float {
		var _anim = this.animations[name];//, string.format("Invalid animation: \'%s\'", name))
		return _anim.length / _anim.framerate
	}

	var transitioning: {
		track:  AnimTrack,
		length: Float,
		time:   Float
	};

	/// Update animations
	// @param _dt Delta time
	public function update(dt: Float) {
		this.time = this.time + dt

		for (track in this.timeline) {
			track.time = track.time + (dt * track.rate);
		}

		// Transition from one animation to the next
		if (this.transitioning != null) {
			var t  = this.transitioning;
			t.time = t.time + dt * t.track.rate
			var progress = Utils.min(t.time / t.length, 1)

			// fade new animation in
			t.track.blend  = Utils.lerp(0, 1, progress);

			// fade old animations out
			for (track in this.timeline) {
				if (track != t.track && !track.lock) {
					track.blend = Utils.lerp(0, 1, 1-progress);
				}
			}

			// remove dead animations
			if (progress >= 1) {
				for (track in this.timeline) {
					if (track.blend == 0 && !track.lock) {
						this.stop(track);
						// Call callback on early exit if flagged
						if (track.early && track.callback != null) {
							track.callback(this);
						}
					}
				}

				this.transitioning = null;
			}
		}

		var pose = this.bind_pose;
		for (track in this.timeline) {
			if (!track.playing) {
				track.offset = track.offset + dt;
			}

			if (!track.active) {
				continue;
			}

			var time  = track.time - track.offset;
			var _anim = this.animations[track.name];
			var frame = time * _anim.framerate;

			if (_anim.loop) {
				frame = frame % _anim.length;
			}
			else {
				if (frame >= _anim.length && !track.lock) {
					this.stop(track);
					if (track.callback != null) {
						track.callback(this);
					}
					continue;
				}
				frame = Utils.min(_anim.length, frame);
			}

			frame = Utils.max(frame, 0);
			var f1 = Math.floor(frame);
			var f2 = Math.ceil(frame);
			track.frame = f1;

			// make sure f2 doesn't exceed anim length or wrongly loop
			if (_anim.loop) {
				f2 = f2 % _anim.length;
			}
			else {
				f2 = Std.int(Utils.min(_anim.length, f2));
			}

			var base = copy_pose(_anim.frames[f1+1]);
			var target = _anim.frames[f2+1];

			// mix between keyframes
			mix_pose_on(base, target, this.skeleton, frame - f1, track.base);

			// update the final pose
			mix_pose_on(pose, base, this.skeleton, track.weight * track.blend, track.base);
		}
		var state = update_matrices(this.skeleton, this.inverse_base, pose);
		this.current_pose = state.buffer;
		this.current_matrices = state.lookup;
	}

	/// Reset animations
	// @param clear_locked Flag to clear even locked tracks
	public function reset(clear_locked: Bool = false) {
		this.time = 0;
		this.transitioning = null;
		var i = this.timeline.length;
		while (--i >= 0) {
			var track = this.timeline[i]
			if (!track.lock || clear_locked) {
				this.timeline.splice(i, 1);
				this.timeline_lookup.remove(track);
			}
		}
	}

	/// Transition from one animation to another
	// @param track Track object to transition to
	// @param length Length of transition (in seconds)
	public function transition(track: AnimTrack, length: Float = 0.2) {
		if (this.transitioning != null && this.transitioning.track == track) {
			return;
		}

		if (!this.timeline_lookup.exists(track)) {
			this.play(track);
		}

		this.transitioning = {
			track:  track,
			length: length,
			time:   0
		};

		track.offset = this.time;
		track.time = this.time;
	}

	/// Find track in timeline
	// @param track Track to locate
	// @return boolean true if found, false if !found
	public inline function find_track(track: AnimTrack): Bool {
		return this.timeline_lookup.exists(track);
	}
}
