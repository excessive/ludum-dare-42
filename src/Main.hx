import anim9.Anim9;
import haxe.ds.Map;
import backend.Fs;
import math.Utils;
import math.Vec3;
import math.Bounds;
import math.Quat;
import backend.BaseGame;
import backend.GameLoop;
import backend.Gc;
import backend.Profiler;
import components.*;
import math.Vec4;
import systems.*;
import ui.Anchor;
import ui.Phone;
import utils.RecycleBuffer;
import love.math.MathModule as Lm;

import components.Item;

import haxe.Json;

typedef TiledMap = {
	width: Int,
	height: Int,
	hexsidelength: Int,
	infinite: Bool,
	layers: Array<{
		data: Array<Int>,
		// data: [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3],
		height: Int,
		id: Int,
		// name: Tile Layer 1,
		opacity: Float,
		// type: tilelayer,
		visible: Bool,
		width: Int,
		x: Int,
		y: Int
	}>,
 	nextlayerid: Int,
	nextobjectid: Int,
	orientation: String, // hex
	renderorder: String, // left-up
	staggeraxis: String, // x
	staggerindex: String, // even
	tiledversion: String, // 2018.08.06
	tileheight: Int,
	tilesets: Array<{
		columns: Int,
		firstgid: Int,
		grid: {
			height: Int,
			orientation: String, //orthogonal,
			width: Int
		},
		margin: Int,
		name: String, // stuff
		spacing: Int,
		tilecount: Int,
		tileheight: Int,
		tiles: Array<{
			id: Int,
			image: String, //dirt tile.png,
			imageheight: Int,
			imagewidth: Int,
			type: String,
			properties: Array<{
				name: String,
				type: String,
				value: String
			}>
		}>,
		tilewidth: Int
	}>,
 	tilewidth: Int,
	type: String, // map
	version: Float // 1.2,
}

class Main extends BaseGame {
	public static var game_title = "Farmageddon (v1.0.2-LD42)";
	public static var scene: Scene;

	var systems:       Array<System>;
	var lag:           Float = 0.0;
	var current_state: RecycleBuffer<Entity>;
	public static var timestep(default, never): Float = 1 / 60;

	public static function get_map(): SceneNode {
		var map = scene.get_child("Map");
		if (map == null) {
			console.Console.es("Map node not found");
			return new SceneNode(); // rip
		}
		return map;
	}

	public static var home_tile(default, null): SceneNode;

	static function load_map(filename: String): SceneNode {
		var raw = Fs.read(filename).toString();
		var data: TiledMap = Json.parse(raw);

		var root = new SceneNode();
		root.name = "Map";

		var spinny = false;
		var layer = data.layers[0];
		if (spinny) {
			layer = data.layers[1];
		}
		if (layer == null) {
			root.item = MapInfo({
				width: 1,
				height: 1,
				nodes: root.children
			});
			var tile = new SceneNode();
			tile.transform.is_static = true;
			tile.transform.update();
			tile.item = Ground(Grass);
			tile.drawable = Farm.get_drawable(tile);
			root.children.push(tile);
			return root;
		}

		root.item = MapInfo({
			width: layer.width,
			height: layer.height,
			nodes: root.children
		});

		var rng = Lm.newRandomGenerator();
		rng.setSeed(Farm.SEED);

		var tile_types: Map<Int, Item> = new Map();
		for (def in data.tilesets[0].tiles) {
			var tile_type = "weed";
			if (def.type != null && def.type != "") {
				tile_type = def.type;
			}
			// for (prop in def.properties) {
			// 	if (prop.name == "type") {
			// 		tile_type = prop.value;
			// 	}
			// }
			var weed = Weed({ base: Grass, days_remaining: 0 });
			tile_types[def.id] = switch(tile_type) {
				case "weed": weed;
				case "dirt": Ground(Dirt);
				case "grass": Ground(Grass);
				case "rock": Ground(Rock);
				case "home": Home;
				case "bin": Bin;
				default: weed;
			}
		}

		var tile_size = 1.0;
		for (idx in 0...layer.data.length) {
			var x = idx % layer.width;
			var y = Std.int(idx / layer.width);

			var tid = layer.data[idx]-1;
			var tile_item = tile_types[tid];
			if (tile_item == null) {
				tile_item = Ground(Dirt);
			}

			var tile = new SceneNode();
			var hahafuckyou = 0.433012; // hexagonal ratio bullshit
			var y_offset = ((x+1) % 2) * tile_size * hahafuckyou;
			tile.transform.position.x = -x * (tile_size * 0.75);
			tile.transform.position.y =  y * tile_size * (hahafuckyou * 2) + y_offset;
			if (spinny) {
				tile.transform.orientation = Quat.from_angle_axis(Utils.rad(60), Vec3.up());
			}
			tile.transform.is_static = true;
			tile.transform.update();
			tile.item = tile_item;
			// randomize weeds
			switch (tile.item) {
				case Weed(info): {
					var time_left = Math.floor(rng.random(0, 3));
					tile.item = Weed({
						base: info.base,
						days_remaining: time_left
					});
				}
				default:
			}
			tile.drawable = Farm.get_drawable(tile);
			var size = new Vec3(3, 3, 6);
			var offset = new Vec3(0, 0, size.z / 2);
			tile.bounds = new Bounds(tile.transform.position + offset, size);
			root.children.push(tile);

			if (tile.item == Home) {
				home_tile = tile;
			}
		}

		return root;
	}

	public static function new_scene() {
		// paranoid memory release of everything in the old scene
		if (scene != null) {
			scene.release();
		}
		scene = new Scene();

		// clean out the old map and entities
		Gc.run(true);

		Time.set_time(10);

		scene.add(load_map("assets/map.json"));
		Farm.update_stats();

		scene.add(World.load("assets/models/extras.exm"));

		// spread the weeds a bit, make the player work for it.
		for (i in 0...3) {
			Farm.next_day();
		}
		Farm.reset_time();

		// begin with 5x lettuce, 5x turnips, 5x fertilizer
		function give(item, count) {
			var cat = ItemDb.get_delivery_category(item);
			Farm.deliveries.push({
				type: item,
				category: cat,
				count: count,
				value: ItemDb.get_value(item, cat)
			});
		}
		give(Lettuce, 5);
		give(Turnip, 5);
		give(Fertilizer, 5);

		// clean out the temporary data from stage load
		// these help prevent a large memory usage spike on level reload
		Gc.run(true);

		var player        = new SceneNode();
		player.player     = new Player();
		player.name       = "Korbo";
		player.collidable = new Collidable();
		player.drawable   = IqmLoader.load_file("assets/models/player.iqm");
		if (player.drawable.length > 0) {
			var anim = player.drawable[0].iqm_anim;
			if (anim != null) {
				player.animation = new Anim9(anim);
				var t = player.animation.new_track("idle");
				player.animation.play(t);
				player.animation.update(0);
			}
			// trace(anim != null);
		}
		player.transform.scale *= 0.5;

		send_home(player.transform);

		scene.add(player);
		Render.player = player;

		var cam = new Camera(player.transform.position);
		cam.orientation = Quat.from_angle_axis(Utils.rad(70), Vec3.right());
		Render.camera = cam;

		// hack: this should be done in a non-bindy way in PlayerController
		GameInput.bind_scroll((x, y) -> {
			if (GameInput.locked) {
				return;
			}

			var e = player;
			var count = Math.floor(Math.abs(y));
			var dir = Std.int(Utils.sign(y));
			if (count > 0 && dir != 0) {
				Sfx.bloop.stop();
				Sfx.bloop.play();
			}
			while (count > 0) {
				if (dir > 0) {
					e.player.inventory.prev();
				}
				else if (dir < 0) {
					e.player.inventory.next();
				}
				count -= 1;
			}
		});
		// Stage.stop_time = false;
	}

	public static function send_home(transform: Transform) {
		var position = new Vec3(0, 0, 0);
		if (home_tile != null) {
			position = home_tile.transform.position.copy();
			position.y += 0.25;
		}
		transform.position = position;
		transform.orientation *= Quat.from_angle_axis(Utils.rad(180), Vec3.up());
	}

	override function quit(): Bool {
		return false;
	}

	override function load(window, args) {
		love.mouse.MouseModule.setVisible(true);

		Anchor.update(window);

		Bgm.load_tracks(["assets/bgm/Cactus_Demo5.ogg"]);

		Sfx.init();

		Signal.register("quiet", (_) -> { Bgm.set_ducking(0.25); Sfx.menu_pause(true); });
		Signal.register("loud", (_) -> { Bgm.set_ducking(1.0); Sfx.menu_pause(false); });

		// TODO: only fire on the currently active gamepad(s)
		Signal.register("vibrate", function(params: { power: Float, duration: Float, ?weak: Bool  }) {
			var lpower = params.power;
			var rpower = params.power;
			if (params.weak != null && params.weak) {
				rpower *= 0;
			}

			var js: lua.Table<Int, love.joystick.Joystick> = cast love.joystick.JoystickModule.getJoysticks();
			var i = 0;
			while (i++ < love.joystick.JoystickModule.getJoystickCount()) {
				if (!js[i].isGamepad()) {
					continue;
				}
				js[i].setVibration(lpower, rpower, params.duration);
			}
		});

		GameInput.init();
		Time.init();
		Render.init();

		systems = [
			new ItemEffect(),
			new Trigger(),
			new PlayerController(),
			new ParticleEffect(),
			new Animation(),
		];
		new_scene();

		Signal.emit("resize", Anchor.get_viewport());

		// force a tick on the first frame if we're using fixed timestep.
		// this prevents init bugs
		if (timestep > 0) {
			tick(timestep);
		}

		Signal.register("advance-day", (_) -> {
			GameInput.lock();
			Phone.layer.broadcast("advance-day");

			var player = Render.player.player;
			// advancing day will automatically regain partial stamina
			player.stamina = Utils.clamp(player.stamina + 1/3, 0.0, 1.0);

			Farm.next_day();
			Time.set_time(5.5); // bright and early at 5:30
		});
	}

	function tick(dt: Float) {
		Profiler.push_block("Tick");
		GameInput.update(dt);
		Time.update(dt);
		// Stage.update(dt);
		Signal.update(dt);
		Bgm.update(dt);

		// order-insensitive updates can self register
		Profiler.push_block("SelfUpdates");
		Signal.emit("update", dt);
		Profiler.pop_block();

#if (imgui || debug)
		GameInput.bind(Debug_F8, function() {
			Signal.emit("advance-day");
			return true;
		});
#end

#if debug
		GameInput.bind(Debug_F6, function() {
			trace("nvm back");
			Bgm.prev();
			return true;
		});

		GameInput.bind(Debug_F7, function() {
			trace("skip");
			Bgm.next();
			return true;
		});
#end

		var cam = Render.camera;
		cam.last_orientation = cam.orientation;
		cam.last_target   = cam.target;

		var entities = scene.get_entities();

		Profiler.push_block("TransformCache");
		for (e in entities) {
			if (!e.transform.is_static) {
				e.last_tx.position    = e.transform.position.copy();
				e.last_tx.orientation = e.transform.orientation.copy();
				e.last_tx.scale       = e.transform.scale.copy();
				e.last_tx.velocity    = e.transform.velocity.copy();
			}
		}
		Profiler.pop_block();

		var relevant = [];
		for (system in systems) {
			Profiler.push_block(system.PROFILE_NAME, system.PROFILE_COLOR);
			relevant.resize(0);
			for (entity in entities) {
				if (system.filter(entity)) {
					relevant.push(entity);
					system.process(entity, dt);
				}
			}
			system.update(relevant, dt);
			Profiler.pop_block();
		}

		Profiler.pop_block();
	}

	public static var frame_graph(default, null): Array<Float> = [ for (i in 0...250) 0.0 ];

	var last_vp: Vec4;

	override function update(window, dt: Float) {
		Anchor.update(window);
		var vp = Anchor.get_viewport();
		if (vp != last_vp) {
			last_vp = vp;
			Signal.emit("resize", vp);
#if debug
			trace("resize");
#end
		}

#if !imgui
		if (love.mouse.MouseModule.isVisible()) {
			// love.mouse.MouseModule.setVisible(false);
		}
#end

		frame_graph.push(dt);
		while (frame_graph.length > 250) {
			frame_graph.shift();
		}

		if (timestep < 0) {
			tick(dt);
			current_state = scene.get_entities();
			return;
		}

		lag += dt;

		while (lag >= timestep) {
			lag -= timestep;
			if (lag >= timestep) {
				Debug.draw(true);
				Debug.clear_capsules();
			}
			tick(timestep);
		}

		current_state = scene.get_entities();
	}

	override function mousepressed(x: Float, y: Float, button: Int) {
		GameInput.mousepressed(x, y, button);
	}

	override function mousereleased(x: Float, y: Float, button: Int) {
		GameInput.mousereleased(x, y, button);
	}

	override function wheelmoved(x: Float, y: Float) {
		GameInput.wheelmoved(x, y);
	}

	override function keypressed(key: String, scan: String, isrepeat: Bool) {
		if (!isrepeat) {
			GameInput.keypressed(scan);
		}
	}

	override function keyreleased(key: String, scan: String) {
		GameInput.keyreleased(scan);
	}

	override function resize(w, h) {
		Render.reset(w, h);
	}

	override function draw(window) {
		var alpha = lag / timestep;
		if (timestep < 0) {
			alpha = 1;
		}
		var visible = scene.get_visible_entities();
		Profiler.push_block("Render");
		Render.frame(window, visible, alpha);
		Profiler.pop_block();
	}

	static function main() {
#if (debug || !release)
		return GameLoop.run(new Main());
#else
		return GameLoop.run(new Splash());
#end
	}
}
