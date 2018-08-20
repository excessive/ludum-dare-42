package components;

enum GroundType {
	Grass;
	Dirt;
	Rock;
}

enum ItemType {
	Lettuce;
	Turnip;
	Wheat;
	Carrot;
	Onion;
	Potato;
	Tomato;
	Corn;
	Pumpkin;
	Blueberry;
	Fertilizer;
}

typedef ItemValue = {
	buy:  Int,
	sell: Int
}

typedef HarvestData = {
	type: ItemType,
	yield: Int,
	value: ItemValue
}

typedef WeedData = {
	base: GroundType,
	days_remaining: Int
}

typedef CropData = {
	type: ItemType,
	days_remaining: Int
}

enum Item {
	Home;
	Bin;
	Ground(type: GroundType);
	Weed(info: WeedData);
	CropPlanted(info: CropData);
	CropHarvestable(info: HarvestData);
	CropDead(type: ItemType);
	MapInfo(info: { width: Int, height: Int, nodes: Array<SceneNode> });
}
