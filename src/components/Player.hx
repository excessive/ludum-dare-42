package components;

import math.Vec3;
import utils.RingBuffer;
import components.Item.ItemType;
import components.Item.ItemValue;

enum ItemCategory {
	Seed;
	Sellable;
	Consumable;
}

typedef InventoryData = {
	type: ItemType,
	category: ItemCategory,
	count: Int,
	value: ItemValue
}

enum ActionItem {
	Harvest;
	Water;
	InventoryItem(info: InventoryData);
}

class Player {
	public var last_position = new Vec3(0, 0, 0);
	public var inventory     = new RingBuffer<ActionItem>([ Harvest, Water ]);
	public var wallet        = 100;
	public var stamina       = 1.0;
	public var debt          = 50000;
	public inline function new() {}
}
