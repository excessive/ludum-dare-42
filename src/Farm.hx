import components.Player;
import math.Vec3;
import love.math.MathModule as Lm;

class Farm {
	static var weed_spread_days: Int = 3;

	public static var GROWABLE_TILES(default, null): Int;
	public static var INFESTED_TILES: Int;

	public static var orders: Array<InventoryData> = [];
	public static var deliveries: Array<InventoryData> = [];
	public static var sales: Array<InventoryData> = [];

	public static var SEED(default, null) = 0;
	public static var DAY(default, null) = 0;

	public static function get_tiles(): Array<SceneNode> {
		switch (Main.get_map().get_item()) {
			case MapInfo(info): {
				return info.nodes;
			}
			default:
		}
		return [];
	}

	static function count_tile(tile: SceneNode) {
		if (Farm.is_weed_growable(tile)) {
			GROWABLE_TILES += 1;
		}
		if (tile.item.getName() == "Weed") {
			INFESTED_TILES += 1;
			GROWABLE_TILES += 1;
		}
	}

	public static function update_stats() {
		// trace("stat recalc");
		GROWABLE_TILES = 0;
		INFESTED_TILES = 0;
		var tiles = get_tiles();
		SEED = tiles.length;
		for (tile in tiles) {
			count_tile(tile);
		}
	}

	public static function reset_time() {
		DAY = 1;
	}

	public static function get_adjacent(tile: SceneNode, ?subset: Array<SceneNode>): Array<SceneNode> {
		if (subset == null) {
			subset = get_tiles();
		}
		var adjacent = [];
		var flat = new Vec3(0, 0, tile.transform.position.z);
		var base = tile.transform.position;
		for (tile in subset) {
			var tile_pos = tile.transform.position;
			flat.x = tile_pos.x;
			flat.y = tile_pos.y;

			var distance = Vec3.distance(tile_pos, base);
			if (distance < 1.01) {
				adjacent.push(tile);
			}
		}
		return adjacent;
	}

	public static function get_tile(tile_x: Int, tile_y: Int): SceneNode {
		var map = Main.get_map();
		switch (map.get_item()) {
			case MapInfo(info): {
				var index = tile_y * info.width + tile_x;
				return info.nodes[index];
			}
			default:
		}
		console.Console.es("this shouldn't happen oh no");
		return new SceneNode();
	}

	static var mesh_types: Map<String, Array<render.MeshView>>;
	public static function get_drawable(tile: SceneNode) {
		var tile_item = tile.item;
		if (mesh_types == null) {
			mesh_types = [
				"grass" => IqmLoader.load_file("assets/models/grass.iqm"),
				"dirt" => IqmLoader.load_file("assets/models/dirt.iqm"),
				"depleted_dirt" => IqmLoader.load_file("assets/models/depleted_dirt.iqm"),
				"rock" => IqmLoader.load_file("assets/models/rock.iqm"),

				"pumpkin" => IqmLoader.load_file("assets/models/pumpkin.iqm"),
				"pumpkin_small" => IqmLoader.load_file("assets/models/pumpkin_small.iqm"),

				"turnip" => IqmLoader.load_file("assets/models/turnip.iqm"),
				"turnip_small" => IqmLoader.load_file("assets/models/turnip_small.iqm"),

				"wheat" => IqmLoader.load_file("assets/models/wheat.iqm"),
				"wheat_small" => IqmLoader.load_file("assets/models/wheat_small.iqm"),

				"lettuce" => IqmLoader.load_file("assets/models/lettuce.iqm"),
				"lettuce_small" => IqmLoader.load_file("assets/models/lettuce_small.iqm"),

				"weed" => IqmLoader.load_file("assets/models/weed.iqm"),
				"weed_small" => IqmLoader.load_file("assets/models/weed_small.iqm"),

				"door" => IqmLoader.load_file("assets/models/door.iqm"),
				"mailbox" => IqmLoader.load_file("assets/models/mailbox.iqm"),

				"cube" => IqmLoader.load_file("assets/models/debug/unit-cube.iqm")
			];
		}

		var dirt = tile.status.deficient ? mesh_types["depleted_dirt"] : mesh_types["dirt"];

		var base = switch (tile_item) {
			case Ground(type): {
				return switch (type) {
					case Grass: mesh_types["grass"];
					case Dirt: dirt;
					case Rock: mesh_types["rock"];
				}
			}
			case Weed(info): switch (info.base) {
				case Grass: mesh_types["grass"];
				case Dirt: dirt;
				case Rock: mesh_types["rock"];
			}
			case CropPlanted(_): dirt;
			case CropHarvestable(_): dirt;
			case CropDead(_): dirt;
			case Home: mesh_types["rock"];
			case Bin: mesh_types["rock"];
			default: mesh_types["grass"];
		}
		if (tile_item == null) {
			trace("missing tile info");
			return base;
		}
		base = base.copy();

		switch (tile_item) {
			case Weed(info): {
				if (info.days_remaining <= 0) {
					return base.concat(mesh_types["weed"]);
				}
				return base.concat(mesh_types["weed_small"]);
			}
			case CropPlanted(info): return switch(info.type) {
				case Lettuce: base.concat(mesh_types["lettuce_small"]);
				case Turnip: base.concat(mesh_types["turnip_small"]);
				case Wheat: base.concat(mesh_types["wheat_small"]);
				case Carrot: base.concat(mesh_types["lettuce_small"]);
				case Onion: base.concat(mesh_types["lettuce_small"]);
				case Potato: base.concat(mesh_types["lettuce_small"]);
				case Tomato: base.concat(mesh_types["lettuce_small"]);
				case Corn: base.concat(mesh_types["lettuce_small"]);
				case Pumpkin: base.concat(mesh_types["pumpkin_small"]);
				case Blueberry: base.concat(mesh_types["lettuce_small"]);
				case Fertilizer: base;
			}
			case CropHarvestable(info): return switch(info.type) {
				case Lettuce: base.concat(mesh_types["lettuce"]);
				case Turnip: base.concat(mesh_types["turnip"]);
				case Wheat: base.concat(mesh_types["wheat"]);
				case Carrot: base.concat(mesh_types["lettuce"]);
				case Onion: base.concat(mesh_types["lettuce"]);
				case Potato: base.concat(mesh_types["lettuce"]);
				case Tomato: base.concat(mesh_types["lettuce"]);
				case Corn: base.concat(mesh_types["lettuce"]);
				case Pumpkin: base.concat(mesh_types["pumpkin"]);
				case Blueberry: base.concat(mesh_types["lettuce"]);
				case Fertilizer: base;
			}
			case Home: return base.concat(mesh_types["door"]);
			case Bin: return base.concat(mesh_types["mailbox"]);
			default:
		}

		trace('no drawable for this tile type: ${tile_item.getName()}');
		return base;
	}

	public static function next_day() {
		// trace("advanced day");

		DAY += 1;

		for (order in orders) {
			deliveries.push(order);
		}
		orders.resize(0);

		var debt_unpaid = true;
		if (Render.player != null) {
			var player = Render.player.player;
			for (sale in sales) {
				player.wallet += sale.count * ItemDb.get_value(sale.type, sale.category).sell;
				// trace('sold ${sale.type.getName()}x${sale.count}');
			}
			sales.resize(0);
			if (player.debt <= 0) {
				debt_unpaid = false;
			}
		}

		var tiles = get_tiles();
		var spread_weeds = [];

		var rng = Lm.newRandomGenerator();
		rng.setSeed(SEED + DAY);

		INFESTED_TILES = 0;
		GROWABLE_TILES = 0;

		var random_weeds = [];

		// tick every tile, replacing grown crops with harvestables,
		// gathering weeds to spread, etc.
		// TODO: water states, weed-b-gone
		for (tile in tiles) {
			// update stats as we go
			count_tile(tile);

			if (tile.item == null) {
				continue;
			}

			// 0.5% chance of random weeds on an empty tile
			if (rng.random(0, 1000) > 995 && debt_unpaid) {
				switch (tile.item) {
					case Ground(type): {
						if (type != Rock) {
							random_weeds.push(tile);
						}
					}
					default:
				}
			}

			switch (tile.item) {
				case CropPlanted(info): {
					if (!tile.status.deficient) {
						if (tile.status.watered) {
							info.days_remaining -= 1;
						}
						if (tile.status.fertilized) {
							info.days_remaining -= 1;
						}
					}
					if (info.days_remaining <= 0) {
						tile.item = CropHarvestable({
							type: info.type,
							yield: ItemDb.get_yield(info.type),
							value: ItemDb.get_value(info.type, Sellable)
						});
					}
				}
				case Weed(info): {
					if (tile.status.watered) {
						info.days_remaining -= 1;
					}
					if (tile.status.fertilized) {
						info.days_remaining -= 1;
					}
					if (info.days_remaining > 0) {
						tile.item = Weed({
							base: info.base,
							days_remaining: info.days_remaining - 1
						});
					}
					else {
						info.days_remaining -= 1;
						spread_weeds.push(tile);
					}

					// die and regrow weeds after mature for a few days
					var kill_timer = rng.random(5, 10);
					if (info.days_remaining <= -kill_timer) {
						info.days_remaining = 3;
					}

					if (info.days_remaining <= 0 && info.base == Dirt) {
						tile.status.deficient = true;
					}
				}
				default:
			}
			tile.drawable = get_drawable(tile);

			tile.status.watered = false;
			tile.status.fertilized = false;
		}

		// have some more weeds loser
		for (weed in random_weeds) {
			switch (weed.item) {
				case Ground(type): {
					weed.item = Weed({
						base: type,
						days_remaining: weed_spread_days
					});
					if (type == Dirt) {
						weed.status.deficient = true;
					}
					weed.drawable = get_drawable(weed);
				}
				default:
			}
		}

		// infect everything with loss of profits
		for (weed in spread_weeds) {
			var adjacent = get_adjacent(weed);
			for (tile in adjacent) {
				if (is_weed_growable(tile)) {
					switch (tile.item) {
						default:
						case Ground(type): {
							tile.item = Weed({
								base: type,
								days_remaining: weed_spread_days
							});
							tile.drawable = get_drawable(tile);
						}
						case CropPlanted(info): {
							tile.item = CropDead(info.type);
							tile.drawable = get_drawable(tile);
						}
						case CropHarvestable(info): {
							tile.item = CropDead(info.type);
							tile.drawable = get_drawable(tile);
						}
						case CropDead(type): {
							tile.item = Weed({
								base: Dirt,
								days_remaining: weed_spread_days
							});
							tile.drawable = get_drawable(tile);
						}
					}
				}
				switch (tile.item) {
					default:
					case Weed(info): {
						if (info.base == Dirt) {
							tile.status.deficient = true;
							tile.drawable = get_drawable(tile);
						}
					}
				}
			}
		}
	}

	public static function is_weed_growable(tile: SceneNode): Bool {
		return switch (tile.item) {
			case Ground(type): type != Rock;
			case CropPlanted(info): true;
			case CropHarvestable(info): true;
			case CropDead(type): true;
			default: false;
		}
	}
}
