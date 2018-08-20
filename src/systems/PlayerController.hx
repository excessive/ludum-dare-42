package systems;

import love.mouse.MouseModule;
import math.Utils;
import anim9.Anim9.Anim9Track;
import math.Vec2;
import math.Quat;
import components.Player.ItemCategory;
import components.Item.HarvestData;
import components.Player.ActionItem;
import utils.RingBuffer;
import math.Vec3;
import systems.System;

import ui.Phone;

import collision.Response;

#if imgui
import imgui.ImGui as Ui;
#end

enum QueueAnim {
	Idle;
	// Tired;
	Run;
	Pull;
}

class PlayerController extends System {
	override function filter(e: Entity): Bool {
		return e.player != null && e.transform != null && e.collidable != null;
	}

	function add_inventory_item(inv: RingBuffer<ActionItem>, info: HarvestData, category: ItemCategory) {
		for (item in inv.items) {
			switch (item) {
				case InventoryItem(inv_info): {
					if (inv_info.type == info.type && inv_info.category == category) {
						// trace("added inv stock");
						inv_info.count += info.yield;
						return;
					}
				}
				default:
			}
		}
		// trace("new inv item");
		inv.push(InventoryItem({
			type: info.type,
			category: category,
			count: info.yield,
			value: ItemDb.get_value(info.type, category)
		}));
	}

	static var tracks: {
		idle: Anim9Track,
		run: Anim9Track,
		pull: Anim9Track
	} = {
		idle: null,
		run: null,
		pull: null
	};

	static var was_blocked = false;
	static var pulling_tile: SceneNode;

	override function process(e: Entity, dt: Float) {
		// MouseModule.setVisible(GameInput.locked);
		if (GameInput.pressed(MenuToggle) || (GameInput.locked && GameInput.pressed(MenuCancel))) {
			GameInput.spin_lock();

			if (Phone.layer.find_actor("phone_report").actual.visible) {
				Phone.layer.find_actor("phone_report").set_visible(false);
				Phone.layer.find_actor("phone_home").set_visible(true);
			}
		}

		if (GameInput.locked) {
			return;
		}

		// no late nights for you mister
		if (Time.current_time.to_hour24() >= 22) {
			Main.send_home(e.transform);
			Signal.emit("advance-day");
			return;
		}

		// Movement input
		var move = GameInput.move_xy() * -1;
		move.trim(1.0);
		var move_len = move.length();

		if (e.animation != null && tracks.idle == null) {
			var anim = e.animation;
			tracks.idle = anim.new_track("idle");
			tracks.run  = anim.new_track("run");
			tracks.pull = anim.new_track("pull");
		}

		function play(track: Anim9Track) {
			if (e.animation == null || track == null) {
				return;
			}
			if (!e.animation.find_track(track)) {
				e.animation.transition(track, 0.2);
				was_blocked = !e.animation.animations[cast track.name].loop;
				if (was_blocked) {
					track.callback = () -> {
						// Signal.emit("vibrate", {
						// 	power: 0.5,
						// 	duration: 1/8
						// });
						e.animation.transition(tracks.idle, 0.2);
						was_blocked = false;
					}
				}
			}
		}

		// Move player
		var target = e.transform.position;
		var move_speed = 2.0 * dt;
		// target.x += move.x * move_speed;
		// target.y += move.y * move_speed;

		var queue_anim = Idle;
		if (move_len > 0) {
			queue_anim = Run;
		}

		// Lock camera to player
		var camera = Render.camera.target;
		camera.x = target.x;
		camera.y = target.y;

		// Determine which tile we are standing on and adjacent tiles
		var tiles = Farm.get_tiles();
		var closest = {
			node: null,
			dist: 1.0e22
		};

		// get nearest tiles in radius 2 so we can use the short list
		// to get adjacent faster.
		// flatten Z, so we can freely change tile height.
		var flat = new Vec3(0, 0, target.z);
		var nearby: Array<SceneNode> = [];
		// var num_weeds = Farm.INFESTED_TILES;
		// var num_tiles = Farm.GROWABLE_TILES;

		for (tile in tiles) {
			var tile_pos = tile.transform.position;
			flat.x = tile_pos.x;
			flat.y = tile_pos.y;

			var distance = Vec3.distance(flat, target);
			if (distance < 2) {
				nearby.push(tile);
			}
			if (closest.dist > distance) {
				closest.dist = distance;
				closest.node = tile;
			}
		}

		Render.closest_tile = closest.node;

		var adjacent = Farm.get_adjacent(closest.node, nearby);
		Render.adjacent_tiles = adjacent;

		// Cycle through actions
		/*
		 * If cycle left is active, move back in ring buffer
		 * If cycle right is active, move forward in ring buffer
		 * left+right cancels out implicitly
		*/
		if (GameInput.pressed(PrevItem)) {
			e.player.inventory.prev();
			Sfx.bloop.stop();
			Sfx.bloop.play();
		}
		if (GameInput.pressed(NextItem)) {
			e.player.inventory.next();
			Sfx.bloop.stop();
			Sfx.bloop.play();
		}

		#if imgui
		utils.Helpers.input_vec3("position", e.transform.position, false);
		#end

		// Perform action on tile
		/*
		 * If action input is active, check if action can be performed on tile
		 * If action can be performed, do action else ignore input (display a warning?)
		*/
		var cancel_action = was_blocked;
		if (GameInput.pressed(UsePrimaryItem) && !cancel_action) {
			switch (closest.node.item) {
				case Bin: {
					if (Farm.deliveries.length > 0) {
						// trace('picked up ${Farm.deliveries.length} deliveries');
						for (pkg in Farm.deliveries) {
							var item: HarvestData = {
								type: pkg.type,
								yield: pkg.count,
								value: pkg.value
							};
							add_inventory_item(e.player.inventory, item, pkg.category);
						}
						Farm.deliveries.resize(0);
					}
					else {
						switch (e.player.inventory.get()) {
							case InventoryItem(info): {
								Farm.sales.push(info);
								e.player.inventory.remove();
							}
							default:
						}
					}
					cancel_action = true;
				}
				case Home: {
					cancel_action = true;

					Main.send_home(e.transform);

					// + 1/3 stamina if you go to bed early
					if (Time.current_time.to_hour24() < 20) {
						e.player.stamina += 1/3;
					}

					// + 1/3 stamina if you returned home voluntarily
					e.player.stamina += 1/3;

					// + 1/3 stamina unconditionally
					Signal.emit("advance-day");
					return;
				}
				default:
			}
		}

		if (GameInput.pressed(UsePrimaryItem) && !cancel_action && e.player.stamina > 0) {
			switch (e.player.inventory.get()) {
				case Harvest:
					switch (closest.node.item) {
						case CropHarvestable(harvest): {
							e.player.stamina -= 1/20;
							add_inventory_item(e.player.inventory, harvest, Sellable);
							closest.node.item = Ground(Dirt);
							closest.node.status.deficient = true;
							pulling_tile = closest.node;
							queue_anim = Pull;
						}
						case Weed(info): {
							e.player.stamina -= 1/20;
							// trace("weed break");
							closest.node.item = Ground(info.base);
							pulling_tile = closest.node;
							Farm.INFESTED_TILES -= 1;
							queue_anim = Pull;
						}
						default:
					}
				case Water: {
					e.player.stamina -= 1/20;
					Sfx.water.stop();
					Sfx.water.play();
					for (tile in adjacent) {
						tile.status.watered = true;
					}
				}
				case InventoryItem(info): {
					// if current item can be used on current tile (plant, sell, use)
					// consume item and perform action
					var tile = closest.node;
					function fertilize() {
						if (info.type != Fertilizer) {
							return;
						}

						// If deficient, return to normal
						if (tile.status.deficient) {
							tile.status.deficient = false;
							tile.drawable = Farm.get_drawable(tile);
							info.count -=1;
							return;
						}

						// If not fertilized, fertilize
						if (!tile.status.fertilized) {
							tile.status.fertilized = true;
							tile.drawable = Farm.get_drawable(tile);
							info.count -= 1;
							return;
						}
					}
					switch (closest.node.item) {
						case Ground(Dirt): {
							if (info.category == Seed) {
								tile.item = CropPlanted({
									type: info.type,
									days_remaining: ItemDb.get_gestation(info.type)
								});
								tile.drawable = Farm.get_drawable(tile);
								info.count -= 1;
								e.player.stamina -= 1/40;
							}
							fertilize();
						}
						case CropPlanted(_): fertilize();
						case CropHarvestable(_): fertilize();
						case CropDead(_): fertilize();
						default:
					}
					if (info.count <= 0) {
						e.player.inventory.remove();
					}
				}
			}
		}

		if (was_blocked) {
			move_len = 0;
		}
		Sfx.wub_for_speed(move_len * 9);

		// we need to move last so that blocking animations keep you frozen
		if (!was_blocked) {
			switch (queue_anim) {
				case Run: play(tracks.run);
				case Idle: play(tracks.idle);
				case Pull: {
					play(tracks.pull);
					Signal.after(1.0, () -> {
						Sfx.pluck.stop();
						Sfx.pluck.play();
						// Sfx.bloop.stop();
						// Sfx.bloop.play();
						if (pulling_tile != null) {
							pulling_tile.drawable = Farm.get_drawable(pulling_tile);
							pulling_tile = null;
						}
					});
				}
			}
			var offset = new Vec3(0, 0, e.collidable.radius.z);
			var response = Response.update(
				e.transform.position + offset,
				new Vec3(move.x * move_speed, move.y * move_speed, 0) * 0.5, // collision bug/speed hack
				e.collidable.radius, new Vec3(0, 0, -0.25), World.get_triangles
			);

			e.transform.position = response.position - offset;

			if (move_len > 0) {
				var angle: Float = new Vec2(move.x, move.y + 0.0001).angle_to() + Math.PI / 2;
				e.transform.orientation = Quat.slerp(e.transform.orientation, Quat.from_angle_axis(angle, Vec3.up()), 1/8);
			}
		}
	}
}
