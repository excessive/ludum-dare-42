package systems;

class ParticleEffect extends System {
	override function filter(e: Entity) {
		return e.emitter.length > 0;
	}

	override function process(e: Entity, dt: Float) {
		if (GameInput.locked) {
			return;
		}

		var kill = [];
		for (params in e.emitter) {
			// emitters with negative lifetime are forever, otherwise
			// clean up when their time is up.
			if (params.lifetime > 0) {
				params.lifetime -= dt;
				if (params.lifetime <= 0) {
					kill.push(params);
				}
			}

			for (p in params.particles) {
				//
			}
		}
		for (rm in kill) {
			e.emitter.remove(rm);
		}
	}
}
