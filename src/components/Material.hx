package components;

import math.Vec3;

typedef Material = {
	var color: Vec3;
	var emission: Float;
	var metalness: Float;
	var roughness: Float;
	var vampire: Bool;
	var opacity: Float;
	var double_sided: Bool;
	@:optional var triplanar: Bool;
	@:optional var shadow: Bool;
	@:optional var textures: {
		@:optional var albedo: String;
		@:optional var roughness: String;
		@:optional var metalness: String;
		@:optional var scale: Float;
	}
}
