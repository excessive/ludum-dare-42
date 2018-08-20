package systems;

import systems.System;

class ItemEffect extends System {
	override function filter(e: Entity) {
		return e.item != null;
	}

	override function process(e: Entity, dt: Float) {
		if (GameInput.locked) {
			return;
		}

		switch (e.item) {
			case Weed(info): {
				e.status.message = null;
				if (info.days_remaining <= 0) {
					e.status.message = "!";
				}
			}
			case Bin: {
				e.status.message = "";
				if (Farm.deliveries.length > 0) {
					var plural = "";
					if (Farm.deliveries.length > 1) {
						plural = "s";
					}
					e.status.message = '${Farm.deliveries.length} Package${plural} Available!';
				}
				if (Farm.sales.length > 0) {
					if (e.status.message != "") {
						e.status.message += "\n";
					}
					var plural = "";
					var items = 0;
					for (sale in Farm.sales) {
						items += sale.count;
					}
					if (items > 1) {
						plural = "s";
					}
					e.status.message += '${items} Item${plural} Shipping';
				}
				if (e.status.message == "") {
					e.status.message = null;
				}
			}
			case CropHarvestable(info): {
				e.status.message = "!";
			}
			default: e.status.message = null;
		}
	}
}
