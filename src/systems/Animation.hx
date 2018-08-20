package systems;

import systems.System;

class Animation extends System {
	override function filter(e: Entity): Bool {
		return e.animation != null;
	}
	override function process(e: Entity, dt: Float) {
		e.animation.update(dt);
	}
}
