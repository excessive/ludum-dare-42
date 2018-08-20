package ui;

import actor.*;
import backend.Profiler;
import math.Vec2;
import math.Vec3;
import math.Vec4;
import love.graphics.GraphicsModule as Lg;

typedef OverlayInfo = { id: Int, text: String, location: Vec3 };

class Hud {
	static inline function format(fmt: String, args: Array<Dynamic>): String {
		var _real = untyped __lua__("{}");
		for (i in 0...args.length) {
			untyped __lua__("table.insert({0}, {1})", _real, args[i]);
		}
		return untyped __lua__("string.format({0}, unpack({1}))", fmt, _real);
	}

	static var overlays: Array<OverlayInfo> = [];

	static function mismatch_overlays(out: Array<OverlayInfo>, list_a: Array<OverlayInfo>, list_b: Array<OverlayInfo>) {
		for (a in list_a) {
			var is_new = true;
			for (b in list_b) {
				if (a.id == b.id) {
					is_new = false;
				}
			}
			if (is_new) {
				out.push(a);
			}
		}
	}

	// i don't want to know how slow this is with an n larger than a few
	public static function update_overlays(?_overlays: Array<OverlayInfo>) {
		var bubbles = layer.find_actor("bubbles");
		if (_overlays == null || _overlays.length == 0) {
			bubbles.trigger("hide", true);
			overlays.resize(0);
			return;
		}

		var new_overlays = [];
		mismatch_overlays(new_overlays, _overlays, overlays);

		var old_overlays = [];
		mismatch_overlays(old_overlays, overlays, _overlays);

		for (o in new_overlays) {
			bubbles.children.push(new BubbleActor(o.id, o.text, (self) -> {
				self.user_data = o.location;
				self.set_font(noto_sans_14);
				self.set_offset(0, -30);
				self.trigger("show");
			}));
		}

		for (o in old_overlays) {
			var actor = layer.find_actor("bubble_" + o.id, bubbles);
			if (actor == null) {
				continue;
			}
			actor.trigger("hide");
		}

		overlays = _overlays;

		var remove = [];
		for (c in bubbles.children) {
			if (c.actual.aux[0] < -0.99) {
				remove.push(c);
			}
		}

		for (c in remove) {
			bubbles.children.remove(c);
		}

		for (o in overlays) {
			var actor: BubbleActor = cast layer.find_actor("bubble_" + o.id, bubbles);
			if (actor == null) {
				continue;
			}
			actor.set_text(o.text);
			actor.user_data = o.location;
		}

		var center = new Vec2(ui.Anchor.center_x, ui.Anchor.center_y);
		var scale = ui.Anchor.width / 1.5;
		for (a in bubbles.children) {
			var location: Vec3 = a.user_data;
			var pos = new Vec2(location.x, location.y);
			location.z = Math.max(1-Vec2.distance(pos, center) / scale, 0);
			location.z = Math.pow(location.z, 0.25);
		}
	}

	static var layer: ActorLayer;
	static var noto_sans_30;
	static var noto_sans_22;
	static var noto_sans_18;
	static var noto_sans_14;
	static var brown = {
		r: 81/255,
		g: 39/255,
		b:  3/255
	};

	public static function init() {
		Signal.register("update", update);
		Signal.register("resize", (_vp) -> {
			var vp: Vec4 = _vp;
			layer.update_bounds(vp);
		});

		noto_sans_30 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 30);
		noto_sans_22 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 22);
		noto_sans_18 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 18);
		noto_sans_14 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 14);
		var padding  = 15;

		layer = new ActorLayer(() -> [
			// overlay locator
			new Actor((self) -> {
				self.set_name("bubbles");
			}),

			// Clock
			new PatchActor((self) -> {
				var w = 121;
				var h =  77;

				self.set_name("time");
				self.set_anchor((vp) -> new Vec3(vp.right-w, vp.top, 0));
				self.load_patch("assets/textures/window.9.png");
				self.set_size(w, h);
				self.set_padding(padding, padding);

				self.children = [
					new TextActor((self) -> {
						self.set_name("time_text");
						self.set_font(noto_sans_30);
						self.set_align(Center);
						self.set_limit(w-padding*2);
						self.set_color(1, 1, 1);
						self.set_stroke(2, 0, 0);
						self.set_stroke_color(brown.r, brown.g, brown.b);
					})
				];
			}),

			// Tile Info
			new PatchActor((self) -> {
				var w = 166;
				var h =  80;
				var padding = 3;

				self.set_name("tile");
				self.set_anchor((vp) -> new Vec3(vp.left, vp.bottom-h, 0));
				self.set_size(w, h);
				self.load_patch("assets/textures/window.9.png");
				self.set_padding(padding, padding);

				self.children = [
					new TextActor((self) -> {
						self.set_name("tile_title");
						self.set_font(noto_sans_22);
						self.set_align(Center);
						self.set_limit(w-padding*2);
						self.set_stroke(2, 0, 0);
						self.set_stroke_color(brown.r, brown.g, brown.b);
					}),

					new QuadActor((self) -> {
						padding = 15;

						self.set_name("tile_status");
						self.set_size(w-padding*2, 32);
						self.set_padding(padding, 0);
						self.set_color(0, 0, 0, 0);
						self.move_to(0, 30);

						self.children = [
							new Actor((self) -> {
								self.set_name("status_water");
								self.load_sprite("assets/icons/water.png");
								self.set_opacity(0.25);
							}),

							new Actor((self) -> {
								self.set_name("status_fertilizer");
								self.load_sprite("assets/icons/fertilizer.png");
								self.set_opacity(0.25);
								self.move_to(30+padding, 0);
							}),

							new Actor((self) -> {
								self.set_name("status_deficient");
								self.load_sprite("assets/icons/deficient.png");
								self.set_opacity(0.25);
								self.move_to(30*2+padding*2, 0);
							})
						];
					})
				];
			}),

			// Stamina
			new QuadActor((self) -> {
				var w = 38;
				var h = 150;

				self.set_name("stamina");
				self.set_anchor((vp) -> new Vec3(vp.right-w, vp.bottom-h, 0));
				self.set_size(w, h);
				self.set_color(0, 0, 0, 0);

				self.children = [
					new QuadActor((self) -> {
						self.set_name("stamina_background");
						self.set_size(w-10, h-16);
						self.set_offset(5, 8);
						self.set_color(0, 0, 0);
					}),

					new QuadActor((self) -> {
						self.set_name("stamina_bar");
						self.set_size(w-10, h-16);
						self.set_offset(5, 8);
						self.set_color(0, .818181, 0);
					}),

					new PatchActor((self) -> {
						self.set_name("stamina_border");
						self.set_size(w, h);
						self.load_patch("assets/textures/stamina.9.png");
					})
				];
			}),

			// Inventory
			new PatchActor((self) -> {
				var w = 240;
				var h = 90;
				var padding = 15;

				self.set_name("inventory");
				self.set_anchor((vp) -> new Vec3(vp.center_x-w/2, vp.bottom-h, 0));
				self.load_patch("assets/textures/window.9.png");
				self.set_size(w, h);
				self.set_padding(padding, padding);
				self.children = [];
			})
		]);
	}

	public static function update(dt) {
		// Update on screen clock
		var time: TextActor = cast layer.find_actor("time_text");
		time.set_text(format("%02d:%02d", [
			Time.current_time.to_hour24(),
			Std.int(Time.current_time.to_minute()/15)*15
		]));

		// Update current tile data
		var tile = Render.closest_tile;

		if (tile != null) {
			var title: TextActor = cast layer.find_actor("tile_title");
			title.set_text(tile.item.getName());

			function fade_actor(actor: Actor, state: Bool) {
				if (actor == null) {
					return;
				}
				var edge: Bool = actor.user_data;
				if (edge == state) {
					return;
				}
				actor.user_data = state;
				if (state) {
					actor.stop().decelerate(0.25).set_opacity(1.0);
				}
				else {
					actor.stop().decelerate(0.25).set_opacity(0.25);
				}
			}

			fade_actor(layer.find_actor("status_water"), tile.status.watered);
			fade_actor(layer.find_actor("status_fertilizer"), tile.status.fertilized);
			fade_actor(layer.find_actor("status_deficient"), tile.status.deficient);

			var time_remaining = switch (tile.item) {
				case CropPlanted(info): info.days_remaining;
				case Weed(info): info.days_remaining;
				default: 0;
			}
		}

		// Update stamina
		var stamina: QuadActor = cast layer.find_actor("stamina_bar");
		var stam = Render.player.player.stamina;
		var w = 38-10;
		var h = 150-16;
		var nh = Math.floor(h * stam);
		stamina.set_size(w, nh);
		stamina.move_to(0, h-nh);

		// Update inventory
		var player = Render.player.player;
		var w = 240;
		var h = 60;
		var padding = 15;
		var inventory: PatchActor = cast layer.find_actor("inventory");

		inventory.children = [];

		inventory.children.push(new TextActor((self) -> {
			var name: String = switch (player.inventory.get()) {
				case Water:   "Water";
				case Harvest: "Harvest";
				case InventoryItem(info): switch(info.category) {
					case Seed:       '${info.type.getName()} Seed';
					case Consumable: info.type.getName();
					case Sellable:   info.type.getName();
					default: "Unknown InventoryItem";
				}

				default: "Unknown";
			}
			self.set_text('${name}');
			self.set_font(noto_sans_22);
			self.set_align(Center);
			self.set_limit(w-padding*2);
			self.set_offset(0, -50);
			self.set_stroke(2, 0, 0);
			self.set_stroke_color(brown.r, brown.g, brown.b);
		}));

		for (i in -1...2) {
			var item = player.inventory.get_offset(i);

			inventory.children.push(new Actor((self) -> {
				self.move_to((i+1)*(h+padding), 0);

				var itenz = null;
				switch (item) {
					case Water:   self.load_sprite("assets/icons/item-water.png");
					case Harvest: self.load_sprite("assets/icons/item-harvest.png");
					case InventoryItem(info): {
						itenz = info;
						switch(info.category) {
							case Seed:       self.load_sprite("assets/icons/item-seed.png");
							case Sellable:   self.load_sprite("assets/icons/item-crop.png");
							case Consumable: self.load_sprite("assets/icons/item-fertilizer.png");
						}
					}
					default: self.load_sprite("assets/icons/item-default.png");
				}

				self.children = [
					new PatchActor((self) -> {
						self.set_name("stamina_border");
						self.set_size(h, h);

						if (i == 0) {
							self.load_patch("assets/textures/border.9.png");
						} else {
							self.load_patch("assets/textures/cover.9.png");
						}
					}),

					new TextActor((self) -> {
						if (itenz != null) {
							self.set_text('x${itenz.count}');
						}
						self.set_font(noto_sans_14);
						self.set_align(Right);
						self.set_limit(h);
						self.set_offset(-7, h-23);
					})
				];
			}));
		}

		Profiler.push_block("HudUpdate");
		layer.update(dt);
		Profiler.pop_block();
	}

	public static function draw() {
		Profiler.push_block("HudDraw");
		ActorLayer.draw(layer);
		Profiler.pop_block();
	}
}
