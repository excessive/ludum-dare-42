import love.audio.AudioModule as La;
import love.audio.Source;

class Sfx {
	public static var wub:   Source;
	public static var bloop: Source;
	public static var pluck: Source;
	public static var water: Source;

	static var all_sounds: Array<Source> = [];

	static var volume = 0.95;

	public static function init() {
		if (bloop == null) {
			bloop = La.newSource("assets/sfx/bloop.wav", Static);
			bloop.setVolume(0.25);
		}

		if (wub == null) {
			wub = La.newSource("assets/sfx/wub.wav", Static);
			bloop.setVolume(0.6);
		}

		if (pluck == null) {
			pluck = La.newSource("assets/sfx/pluck.wav", Static);
			pluck.setVolume(0.95);
		}

		if (water == null) {
			water = La.newSource("assets/sfx/water.wav", Static);
			water.setVolume(0.4);
		}

		all_sounds = [
			wub,
			bloop,
			pluck,
			water
		];
	}

	public static function wub_for_speed(speed: Float) {
		var wub_mul = 1.5;
		wub.setPitch(1);
		wub.setVolume(wub_mul*0.35);

		if (speed < 50) {
			wub.setPitch(0.9);
			wub.setVolume(wub_mul*0.3);
		}

		if (speed < 40) {
			wub.setPitch(0.8);
			wub.setVolume(wub_mul*0.25);
		}

		if (speed < 30) {
			wub.setPitch(0.7);
			wub.setVolume(wub_mul*0.2);
		}

		if (speed < 20) {
			wub.setPitch(0.6);
			wub.setVolume(wub_mul*0.15);
		}

		if (speed < 10) {
			wub.setPitch(0.5);
			wub.setVolume(wub_mul*0.1);
		}

		if (speed < 5) {
			wub.setPitch(0.4);
			wub.setVolume(wub_mul*0.075);
		}

		if (speed >= 5) {
			wub.play();
		}
	}

	static var holding = [];

	public static function menu_pause(set: Bool) {
		if (set) {
			for (s in all_sounds) {
				if (s.isPlaying()) {
					s.pause();
					if (holding.indexOf(s) < 0) {
						holding.push(s);
					}
				}
			}
		}
		else {
			for (s in holding) {
				s.play();
			}
			holding.resize(0);
		}
	}

	public static function stop_all() {
		for (s in all_sounds) {
			s.stop();
		}
	}
}
