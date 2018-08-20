import components.Item;
import components.Player;

class ItemDb {
	public static function get_value(name: ItemType, category: ItemCategory): ItemValue {
		var nodda = { buy:  0, sell: 0 };

		return switch (name) {
			case Lettuce: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 70 };
					case Seed:     { buy: 10, sell:  5 };
					default:       nodda;
				}
			}

			case Turnip: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 80 };
					case Seed:     { buy: 14, sell:  7 };
					default:       nodda;
				}
			}

			case Wheat: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 20 };
					case Seed:     { buy: 22, sell: 11 };
					default:       nodda;
				}
			}

			case Carrot: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 132 };
					case Seed:     { buy: 20, sell:  10 };
					default:       nodda;
				}
			}

			case Onion: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 72 };
					case Seed:     { buy: 24, sell: 12 };
					default:       nodda;
				}
			}

			case Potato: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 40 };
					case Seed:     { buy: 28, sell: 14 };
					default:       nodda;
				}
			}

			case Tomato: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 70 };
					case Seed:     { buy: 35, sell: 17 };
					default:       nodda;
				}
			}

			case Corn: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 400 };
					case Seed:     { buy: 40, sell:  20 };
					default:       nodda;
				}
			}

			case Pumpkin: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 490 };
					case Seed:     { buy: 50, sell:  25 };
					default:       nodda;
				}
			}

			case Blueberry: {
				return switch (category) {
					case Sellable: { buy:  0, sell: 78 };
					case Seed:     { buy: 80, sell: 40 };
					default:       nodda;
				}
			}

			case Fertilizer: { buy: 20, sell: 10 };
		}
	}

	// default categories for deliveries
	public static function get_delivery_category(name: ItemType): ItemCategory {
		return switch (name) {
			case Lettuce:    Seed;
			case Turnip:     Seed;
			case Wheat:      Seed;
			case Carrot:     Seed;
			case Onion:      Seed;
			case Potato:     Seed;
			case Tomato:     Seed;
			case Corn:       Seed;
			case Pumpkin:    Seed;
			case Blueberry:  Seed;
			case Fertilizer: Consumable;
		}
	}

	public static function get_gestation(name: ItemType): Int {
		return switch (name) {
			case Lettuce:     3;
			case Turnip:      3;
			case Wheat:       3;
			case Carrot:      4;
			case Onion:       4;
			case Potato:      4;
			case Tomato:      7;
			case Corn:       10;
			case Pumpkin:    11;
			case Blueberry:  14;
			case Fertilizer: -1;
		}
	}

	public static function get_yield(name: ItemType): Int {
		return switch (name) {
			case Lettuce:     1;
			case Turnip:      1;
			case Wheat:       5;
			case Carrot:      1;
			case Onion:       2;
			case Potato:      4;
			case Tomato:      4;
			case Corn:        1;
			case Pumpkin:     1;
			case Blueberry:  10;
			case Fertilizer:  0;
		}
	}
}
