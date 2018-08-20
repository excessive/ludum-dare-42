package ui;

import actor.*;
import backend.Fs;
import backend.Profiler;
import components.Player.ItemCategory;
import components.Item.ItemType;
import components.Item.HarvestData;
import math.Vec3;
import math.Vec4;
import love.graphics.GraphicsModule as Lg;

class Phone {
	static inline function format(fmt: String, args: Array<Dynamic>): String {
		var _real = untyped __lua__("{}");
		for (i in 0...args.length) {
			untyped __lua__("table.insert({0}, {1})", _real, args[i]);
		}
		return untyped __lua__("string.format({0}, unpack({1}))", fmt, _real);
	}

	static function submit_order(info: HarvestData, category: ItemCategory) {
		var inv = Farm.orders;
		for (inv_info in inv) {
			if (inv_info.type == info.type && inv_info.category == category) {
				trace("added order stock");
				inv_info.count += info.yield;
				return;
			}
		}
		trace("new order item");
		inv.push({
			type: info.type,
			category: category,
			count: info.yield,
			value: ItemDb.get_value(info.type, category)
		});
	}

	static function set_list(list: Array<Actor>, index: Int) {
		selectable = list;
		selected   = index;
	}

	public static var layer: ActorLayer;
	static var was_locked = false;

	static var selected: Int = 0;
	static var selectable: Array<Actor>;

	public static function init() {
		Signal.register("update", update);

		var noto_sans_36 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 36);
		var noto_sans_22 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 22);
		var noto_sans_18 = Lg.newFont("assets/fonts/NotoSans-Regular.ttf", 18);

		var padding = 15;
		var isize   = 62;
		var w       = 400;
		var h       = 600;

		layer = new ActorLayer(() -> [
			new PatchActor((self) -> {
				self.set_name("phone");
				self.set_anchor((vp) -> new Vec3(vp.left, vp.bottom - h, 0));
				self.set_size(w, h);
				self.set_padding(padding, padding);
				self.load_patch("assets/textures/window.9.png");
				self.move_to(0, 1000);

				self.set_visible(false);
				self.register("show", () -> {
					selected = 0;
					self.stop().set_visible(true).decelerate(0.25).move_to(0, 0);
				});
				self.register("hide", () -> self.stop().decelerate(0.25).set_visible(false).move_to(0, 1000));

				self.children = [
					new TextActor((self) -> {
						self.set_name("phone_title");
						self.set_text("Amazoom Pyro");
						self.set_color(0.25, 0, 0);
						self.set_stroke(0, -1, 2);
						self.set_stroke_color(1, 0.8, 0.5);
						self.set_font(noto_sans_36);
						self.set_align(Center);
						self.set_limit(w-padding*2);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_home");
						self.set_color(0, 0, 0);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.move_to(0, padding*4);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_shop");
						self.set_color(0, 0, 0);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.set_visible(false);
						self.move_to(0, padding*4);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_finance");
						self.set_color(0, 0, 0);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.set_visible(false);
						self.move_to(0, padding*4);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_credits");
						self.set_color(89/255, 157/255, 220/255);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.set_visible(false);
						self.move_to(0, padding*4);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_exit");
						self.set_color(0, 0, 0);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.set_visible(false);
						self.move_to(0, padding*4);
					}),

					new QuadActor((self) -> {
						self.set_name("phone_report");
						self.set_color(0, 0, 0);
						self.set_size(w-padding*2, h-padding*7);
						self.set_padding(padding, padding);
						self.set_visible(false);
						self.move_to(0, padding*4);
					})
				];
			})
		]);

		/** HOME **/

		var home = layer.find_actor("phone_home");
		var status_h = 100;

		home.children = [
			new PatchActor((self) -> {
				self.set_name("phone_status");
				self.set_color(.2, .4, .5);
				self.set_size(w-padding*4, status_h);
				self.set_padding(padding, padding);
				self.load_patch("assets/textures/button.9.png");

				self.children = [
					new TextActor((self) -> {
						self.set_text("Farm Status");
						self.set_font(noto_sans_22);
						self.set_limit(w-padding*6);
						self.set_align(Center);
					}),

					new TextActor((self) -> {
						self.set_name("status_weeds");
						self.set_font(noto_sans_18);
						self.move_to(0, 45);
					})
				];
			}),

			new QuadActor((self) -> {
				self.set_name("home_buttons");
				self.set_color(0, 0, 0, 0);
				self.set_size(w-padding*4, h-padding*10-status_h);
				self.move_to(0, status_h+padding);

				self.children = [
					new PatchActor((self) -> {
						self.set_name("app_shop");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 0*isize + 0*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							var app = layer.find_actor('phone_shop');
							app.set_visible(true);
							home.set_visible(false);
							set_list(layer.find_actor('shop_buttons').children, 0);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Amazoom Shop");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					}),

					new PatchActor((self) -> {
						self.set_name("app_finance");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 1*isize + 1*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							var app = layer.find_actor('phone_finance');
							app.set_visible(true);
							home.set_visible(false);
							set_list(layer.find_actor('finance_buttons').children, 0);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Amazoom Finance");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					}),

					new PatchActor((self) -> {
						self.set_name("app_credits");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 2*isize + 2*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							var app = layer.find_actor('phone_credits');
							app.set_visible(true);
							home.set_visible(false);
							set_list(layer.find_actor('credits_buttons').children, 0);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Credits");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					}),

					new PatchActor((self) -> {
						self.set_name("app_exit");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 3*isize + 3*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							var app = layer.find_actor('phone_exit');
							app.set_visible(true);
							home.set_visible(false);
							set_list(layer.find_actor('exit_buttons').children, 0);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Exit to Desktop");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					})
				];
			})
		];

		set_list(layer.find_actor('home_buttons').children, 0);

		/** SHOP **/

		var app   = layer.find_actor("phone_shop");
		var items = ItemType.createAll();

		app.children = [
			new TextActor((self) -> {
				self.set_name("shop_bux");
				self.set_font(noto_sans_22);
				self.set_align(Right);
				self.set_limit(w-padding*4);
			}),

			new QuadActor((self) -> {
				self.set_name("shop_items");
				self.move_to(0, padding*3);
				self.set_color(0, 0, 0, 0);
				self.set_size(w-padding*4, h-padding*12);
				self.scissor_test = true;

				self.children = [
					new QuadActor((self) -> {
						self.set_name("shop_buttons");
						self.set_color(0, 0, 0, 0);
						self.set_size(w-padding*4, 908);
					})
				];
			})
		];

		var shop = layer.find_actor("shop_buttons");
		for (i in 0...items.length) {
			var item = items[i];

			shop.children.push(new PatchActor((self) -> {
				self.set_name('shop_${item.getName()}');
				self.set_color(.2, .2, .2);
				self.set_size(w-padding*4, isize);
				self.set_padding(padding, padding);
				self.move_to(0, i*isize + i*padding);
				self.load_patch("assets/textures/button.9.png");

				self.on_click = () -> {
					var player  = Render.player.player;
					var product = layer.find_actor('product_${item.getName()}').user_data;

					var category: ItemCategory = switch(product.type) {
						case Fertilizer: Consumable;
						default: Seed;
					};

					if (player.wallet >= product.value.buy) {
						submit_order(product, category);
						player.wallet -= product.value.buy;
					}
				};

				self.children = [
					new Actor((self) -> {
						self.load_sprite("assets/icons/water.png");
					}),

					new TextActor((self) -> {
						switch(item) {
							case Fertilizer: self.set_text(item.getName());
							default: self.set_text('${item.getName()} Seed');
						}

						self.set_font(noto_sans_22);
						self.move_to(32+padding, 0);
					}),

					new TextActor((self) -> {
						var category: ItemCategory = switch(item) {
							case Fertilizer: Consumable;
							default: Seed;
						}

						self.user_data = {
							type:  item,
							yield: 1,
							value: ItemDb.get_value(item, category)
						};

						self.set_name('product_${item.getName()}');
						self.set_text('Ƶ${self.user_data.value.buy}');
						self.set_font(noto_sans_18);
						self.set_limit(w-padding*6);
						self.set_align(Right);
						self.move_to(0, 2);
					}),
				];
			}));
		}

		shop.children.push(new PatchActor((self) -> {
			self.set_color(.2, .2, .2);
			self.set_size(w-padding*4, isize);
			self.set_padding(padding, padding);
			self.move_to(0, items.length*isize + items.length*padding);
			self.load_patch("assets/textures/button.9.png");

			self.on_click = () -> {
				app.set_visible(false);
				home.set_visible(true);
				shop.move_to(0, 0);
				set_list(layer.find_actor('home_buttons').children, 0);
			};

			self.children = [
				new TextActor((self) -> {
					self.set_text("Go Back");
					self.set_font(noto_sans_22);
					self.move_to(padding, 0);
				})
			];
		}));

		/** FINANCE **/

		var app = layer.find_actor("phone_finance");

		app.children = [
			new TextActor((self) -> {
				self.set_name("finance_bux");
				self.set_font(noto_sans_22);
				self.set_align(Right);
				self.set_limit(w-padding*4);
			}),

			new TextActor((self) -> {
				self.set_name("finance_debt");
				self.set_font(noto_sans_22);
				self.set_align(Right);
				self.set_limit(w-padding*4);
				self.move_to(0, 35);
			}),

			new QuadActor((self) -> {
				self.set_name('finance_buttons');
				self.set_color(0, 0, 0, 0);
				self.move_to(0, 1*isize + 1*padding);

				self.children = [
					new PatchActor((self) -> {
						self.set_name("finance_1k");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.load_patch("assets/textures/button.9.png");
						var pay = 0;

						self.on_click = () -> {
							var player = Render.player.player;
							pay = Math.floor(math.Utils.min(1000, player.debt));

							if (player.wallet >= pay) {
								player.debt   -= pay;
								player.wallet -= pay;
							}
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text('Pay Ƶ${pay}');
								self.set_font(noto_sans_22);
								self.move_to(0, 2);
							}),
						];
					}),

					new PatchActor((self) -> {
						self.set_name("finance_5k");
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 1*isize + 1*padding);
						self.load_patch("assets/textures/button.9.png");
						var pay = 0;

						self.on_click = () -> {
							var player = Render.player.player;
							pay = Math.floor(math.Utils.min(5000, player.debt));

							if (player.wallet >= pay) {
								player.debt   -= pay;
								player.wallet -= pay;
							}
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text('Pay Ƶ${pay}');
								self.set_font(noto_sans_22);
								self.move_to(0, 2);
							}),
						];
					}),

					new PatchActor((self) -> {
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 2*isize + 2*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							app.set_visible(false);
							home.set_visible(true);
							set_list(layer.find_actor('home_buttons').children, 1);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Go Back");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					})

				];
			}),

		];

		/** CREDITS **/

		var app     = layer.find_actor("phone_credits");
		var credits = Fs.read("assets/credits.txt").toString();

		app.children = [
			new TextActor((self) -> {
				self.set_text(credits);
				self.set_font(noto_sans_18);
				self.set_align(Center);
				self.set_limit(w-padding*4);
			}),

			new QuadActor((self) -> {
				self.set_name('credits_buttons');
				self.set_color(0, 0, 0, 0);
				self.move_to(0, Math.floor(5*isize + 5*padding));

				self.children = [
					new PatchActor((self) -> {
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							app.set_visible(false);
							home.set_visible(true);
							set_list(layer.find_actor('home_buttons').children, 2);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Go Back");
								self.set_font(noto_sans_22);
							})
						];
					})
				];
			})
		];

		/** EXIT **/

		var app = layer.find_actor("phone_exit");

		app.children = [
			new TextActor((self) -> {
				self.set_text("Are you sure? You will lose all of your progress!");
				self.set_font(noto_sans_18);
				self.set_align(Center);
				self.set_limit(w-padding*4);
			}),

			new QuadActor((self) -> {
				self.set_name('exit_buttons');
				self.set_color(0, 0, 0, 0);
				self.move_to(0, 1*isize + 1*padding);

				self.children = [
					new PatchActor((self) -> {
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							love.event.EventModule.quit(0);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Default on loan");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					}),

					new PatchActor((self) -> {
						self.set_color(.2, .2, .2);
						self.set_size(w-padding*4, isize);
						self.set_padding(padding, padding);
						self.move_to(0, 1*isize + 1*padding);
						self.load_patch("assets/textures/button.9.png");

						self.on_click = () -> {
							app.set_visible(false);
							home.set_visible(true);
							set_list(layer.find_actor('home_buttons').children, 3);
						};

						self.children = [
							new TextActor((self) -> {
								self.set_text("Go Back");
								self.set_font(noto_sans_22);
								self.move_to(padding, 0);
							})
						];
					})
				];
			})
		];

		/** REPORT **/

		var app = layer.find_actor("phone_report");

		app.children = [
			new PatchActor((self) -> {
				self.set_color(.2, .4, .5);
				self.set_size(w-padding*4, 465);
				self.set_padding(padding, padding);
				self.load_patch("assets/textures/button.9.png");
				self.register("advance-day", () -> {
					app.set_visible(true);
					home.set_visible(false);

					var products = "";
					var revenue  = "";
					var total    = 0;

					for (i in 0...Farm.sales.length) {
						var sale = Farm.sales[i];

						var num   = sale.count;
						var price = sale.value.sell * num;
						var name  = switch (sale.category) {
							case Seed: '${sale.type.getName()} Seed';
							default: sale.type.getName();
						}

						products = '${products}${name} x${num}\n';
						revenue  = '${revenue}Ƶ${price}\n';
						total   += price;
					}

					products = '${products}TOTAL ZOOMBUX EARNED';
					revenue  = '${revenue}Ƶ${total}';

					var p: TextActor = cast layer.find_actor("report_products");
					p.set_text(products);

					var r: TextActor = cast layer.find_actor("report_revenue");
					r.set_text(revenue);

					set_list(layer.find_actor('report_buttons').children, 0);

					var t: TextActor = cast layer.find_actor('report_title');
					t.set_suffix('${Farm.DAY}');
				});

				self.children = [
					new TextActor((self) -> {
						self.set_name("report_title");
						self.set_text("Day End Report: Day ");
						self.set_suffix('${Farm.DAY}');
						self.set_font(noto_sans_22);
						self.set_limit(w-padding*6);
						self.set_align(Center);
					}),

					new TextActor((self) -> {
						self.set_name('report_products');
						self.set_font(noto_sans_18);
						self.move_to(0, 40);
					}),

					new TextActor((self) -> {
						self.set_name('report_revenue');
						self.set_font(noto_sans_18);
						self.set_limit(w-padding*6);
						self.set_align(Right);
						self.move_to(0, 40);
					}),

					new QuadActor((self) -> {
						self.set_name("report_buttons");
						self.set_color(0, 0, 0, 0);
						self.move_to(0, 400 - padding*2);

						self.children = [
							new PatchActor((self) -> {
								self.set_color(.2, .2, .2);
								self.set_size(w-padding*6, isize);
								self.set_padding(padding, padding);
								self.load_patch("assets/textures/button.9.png");

								self.on_click = () -> {
									app.set_visible(false);
									home.set_visible(true);
									layer.find_actor('phone_shop').set_visible(false);
									layer.find_actor('phone_finance').set_visible(false);
									layer.find_actor('phone_credits').set_visible(false);
									layer.find_actor('phone_exit').set_visible(false);

									set_list(layer.find_actor('home_buttons').children, 0);
									GameInput.queue_unlock();
								};

								self.children = [
									new TextActor((self) -> {
										self.set_text("Start Next Day");
										self.set_font(noto_sans_22);
										self.move_to(0, 0);
									})
								];
							})
						];
					})
				];
			})
		];

		/** LAYER BOILERPLATE **/

		GameInput.bind_click((click) -> {
			// only pass clicks if we're in the menu
			if (!GameInput.locked) {
				return;
			}
			if (click.button == 1 && click.press) {
				layer.hit(click.x, click.y);
			}
		});

		GameInput.bind_scroll((x, y) -> {
			// only pass scrolls if we're in the menu
			if (!GameInput.locked) {
				return;
			}
			if (y != 0) {
				selected = null;

				var frame: QuadActor = cast layer.find_actor("shop_buttons");

				frame.stop().move_by(0, y*30);

				// Clamp scroll
				if (frame.actual.position.y < -500) {
					frame.stop().move_to(0, -500);
				}

				if (frame.actual.position.y > 0) {
					frame.stop().move_to(0, 0);
				}
			}
		});

		layer.update_bounds(new Vec4(Lg.getWidth()/2 - w/2, Lg.getHeight()/2 - h/2, w, h));
		layer.scissor_test = true;
	}

	public static function update(dt) {
		/** INPUT **/
		if (GameInput.locked && selectable != null) {
			if (GameInput.pressed(MenuUp)) {
				if (selected == null) {
					selected = 0;
				}
				selected -= 1;
			}

			if (GameInput.pressed(MenuDown)) {
				if (selected == null) {
					selected = 0;
				}
				selected += 1;
			}

			for (actor in selectable) {
				var a: PatchActor = cast actor;
				a.set_color(.2, .2, .2);
			}

			if (selected != null) {
				while (selected < 0) {
					selected += selectable.length;
				}
				selected = (selected % selectable.length);

				var a: PatchActor = cast selectable[selected];
				a.set_color(.4, .4, .4);

				if (GameInput.pressed(MenuConfirm)) {
					selectable[selected].on_click();
				}
			}
		}

		/** PHONE **/

		if (GameInput.locked != was_locked) {
			was_locked = GameInput.locked;
			var phone = layer.find_actor("phone");

			if (GameInput.locked) {
				phone.trigger("show");
			} else {
				phone.trigger("hide");
			}
		}

		// 
		if (selected != null) {
			var frame: QuadActor = cast layer.find_actor("shop_buttons");
			var spacing = -45;
			frame.stop().decelerate(1/10).move_to(0, selected*spacing);
		}

		/** HOME **/

		// Update weed counter
		var weeds: TextActor = cast layer.find_actor("status_weeds");
		var num_weeds = Farm.INFESTED_TILES;
		var num_tiles = Farm.GROWABLE_TILES;

		weeds.set_text('Weeds: ${format("%d (%0.2f%%)", [
			num_weeds, num_weeds / num_tiles * 100
		])}');

		/** SHOP **/

		// Update bux
		var bux: TextActor = cast layer.find_actor("shop_bux");
		bux.set_text(format("ZoomBux: Ƶ%d", [
			Render.player.player.wallet
		]));

		/** FINANCE **/

		var bux: TextActor = cast layer.find_actor("finance_bux");
		bux.set_text('Balance: Ƶ${Render.player.player.wallet}');

		var debt: TextActor = cast layer.find_actor("finance_debt");
		debt.set_text('Debt: Ƶ${Render.player.player.debt}');

		var monay = layer.find_actor("finance_1k");
		var label: TextActor = cast monay.children[0];
		label.set_text('Pay Ƶ${Math.floor(math.Utils.min(1000, Render.player.player.debt))}');

		var monay = layer.find_actor("finance_5k");
		var label: TextActor = cast monay.children[0];
		label.set_text('Pay Ƶ${Math.floor(math.Utils.min(5000, Render.player.player.debt))}');

		// update actors
		Profiler.push_block("PhoneUpdate");
		layer.update(dt);
		Profiler.pop_block();
	}

	public static function draw() {
		Profiler.push_block("PhoneDraw");
		ActorLayer.draw(layer);
		Profiler.pop_block();
	}
}
