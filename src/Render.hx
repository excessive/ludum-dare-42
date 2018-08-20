import math.Vec4;
import backend.Fs;
import ini.IniFile;
import backend.love.GameLoop;
import love.graphics.GraphicsModule as Lg;
import math.Intersect;

import backend.Window as PlatformWindow;
import backend.Profiler;

#if imgui
import imgui.ImGui as Ui;
#end

import math.Vec3;
import math.Mat4;
import math.Quat;
import render.*;
import utils.RecycleBuffer;

import ui.*;

typedef RenderConfig = {
	quality: {
		fxaa: Bool,
		ssaa: Float,
		smoothing: Bool,
		anisotropic_filtering: Bool
	},
	color: {
		white_point: String,
		exposure: Float
	},
	post: {
		vignette: Float
	}
}

class Render {
	public static var camera = new Camera(new Vec3(0, 0, 0));
	public static var player: SceneNode;
	public static var config(default, null): RenderConfig;
	public static var white_point: Array<Float>;

	public static function init() {
		Debug.init();
		Shader.init();
		Hud.init();
		Phone.init();

		var default_config: RenderConfig = {
			quality: {
				fxaa: true,
				ssaa: 1.0,
				smoothing: true,
				anisotropic_filtering: true
			},
			color: {
				white_point: "7,14,16",
				exposure: 0.75,
				// exposure: 1.1,
			},
			post: {
				vignette: 0.35
			}
		};

		// load engine render config
		var config_file = "assets/render_config.ini";
		if (Fs.is_file(config_file)) {
			config = IniFile.parse_typed(default_config, config_file);
			console.Console.ds('loaded config $config_file');
		}
		else {
			config = default_config;
		}

		var r: Float = 5;
		var g: Float = 5;
		var b: Float = 5;
		var rgb = config.color.white_point.split(",");
		if (rgb.length >= 3) {
			var pr = Std.parseInt(rgb[0]);
			if (pr != null) {
				r = pr;
			}
			var pg = Std.parseInt(rgb[1]);
			if (pg != null) {
				g = pg;
			}
			var pb = Std.parseInt(rgb[2]);
			if (pb != null) {
				b = pb;
			}
		}
		white_point = [ r, g, b ];
	}

	public static var shadow(default, null): {
		color: love.graphics.Canvas,
		depth: love.graphics.Canvas
	};

	static var gbuffer: GBuffer;

	public static var gles_mode = false;

	public static var rgbm_const(default, null): Float = 1.125;

	public static function reset(w: Float, h: Float) {
		var renderer = Lg.getRendererInfo();
		gles_mode = renderer.name == "OpenGL ES";

		var lag = config.quality.ssaa;
		if (gbuffer != null) {
			for (c in gbuffer.layers) {
				c.release();
			}
			gbuffer.depth.release();
			gbuffer.out1.release();
			gbuffer.out2.release();
		}

		if (shadow != null) {
			shadow.color.release();
			shadow.depth.release();
		}

		w *= lag;
		h *= lag;
		var formats: lua.Table<String, Bool> = cast Lg.getCanvasFormats();
		var fmt = "rgba8";
		if (formats.rgb10a2) {
			fmt = "rgb10a2";
		}
		var hdr = "rgba8";
		if (formats.rgba16f) {
			hdr = "rgba16f";
		}
		if (formats.rg11b10f) {
			hdr = "rg11b10f";
		}
		var depth = "depth16";
		if (formats.depth24) {
			depth = "depth24";
		}

		var shadow_res = 256;
		var sw = shadow_res;
		var sh = shadow_res;

		shadow = {
			color: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", sw, sh, "rgba8"),
			depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { readable = true, format = {2} } )", sw, sh, depth)
		};

		gbuffer = {
			layers: [
				// albedo (rgb) + roughness (a)
				// untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = 'rgba8' } )", w, h),
				// normal (rg) + distance (b) + unused (a)
				// untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, fmt),
			],
			// depth
			depth: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, depth),
			// final combined rg11b10f buffer. might need to increase to rgba16f?
			out1: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { mipmaps = 'manual', format = {2} } )", w, h, hdr),
			// final tonemapped buffer we apply AA to
			out2: untyped __lua__("love.graphics.newCanvas( {0}, {1}, { format = {2} } )", w, h, fmt)
		};

		if (config.quality.ssaa < 1.0 && !config.quality.smoothing || gles_mode) {
			gbuffer.out1.setFilter(Linear, Nearest);
			gbuffer.out2.setFilter(Linear, Nearest);
		}
	}

	static var debug_draw = true;
	public static var show_profiler = #if (debug && imgui) true #else false #end;
	static var forward = new RecycleBuffer<DrawCommand>();
	static var shadow_draws = new RecycleBuffer<DrawCommand>();

	public static var closest_tile: SceneNode = null;
	public static var adjacent_tiles: Array<SceneNode> = null;

	static function render_game(width: Float, height: Float, state: RecycleBuffer<Entity>, alpha: Float) {
		var vp: Viewport = { x: 0, y: 0, w: width, h: height };
		camera.update(vp.w, vp.h, alpha);

		Lg.setColor(1, 1, 1, 1);

#if (imgui && debug)
		Profiler.push_block("Prepare");
		var ret = Ui.slider_float("rgbm exp", rgbm_const, 0.1, 20.0);
		rgbm_const = ret.f1;

		ret = Ui.slider_float("exposure", config.color.exposure, -5, 5);
		config.color.exposure = ret.f1;

		if (Ui.begin("Render Options##Render")) {
			if (Ui.checkbox("FXAA", config.quality.fxaa)) {
				config.quality.fxaa = !config.quality.fxaa;
			}
			if (Ui.checkbox("More Ghetto", config.quality.ssaa < 1.0)) {
				config.quality.ssaa = 0.5;
				reset(width, height);
			}
			if (Ui.checkbox("Less Ghetto", config.quality.ssaa > 1.0)) {
				config.quality.ssaa = 2.0;
				reset(width, height);
			}
			if (Ui.checkbox("Debug", debug_draw)) {
				debug_draw = !debug_draw;
			}
		}
		Ui.end();
#end

		forward.reset();
		shadow_draws.reset();

		// interpolate dynamic objects and sort objects into the appropriate passes
		var player_pos = new Vec3(0, 0, 0);
		var player_size = 0.5;

		var overlays: Array<ui.Hud.OverlayInfo> = [];
		var overlay_vp = new Vec4(vp.x, vp.y, vp.w, vp.h);
		var cam_vp = camera.projection * camera.view;
		var origin = new Vec3(0, 0, 0);

		var ui_vp = ui.Anchor.get_viewport();

		var culled = 0;
		for (e in state) {
			if (e.drawable.length <= 0) {
				continue;
			}

			if (e.bounds != null && e.transform.is_static) {
				if (!Intersect.aabb_frustum(e.bounds, camera.frustum)) {
					culled += 1;
					continue;
				}
			}

			var mtx = e.transform.matrix;
			var inv = e.transform.normal_matrix;

			var pos = e.transform.position;
			if (!e.transform.is_static) {
				var a = e.last_tx.position;
				var b = e.transform.position;
				pos = Vec3.lerp(a, b, alpha) + e.transform.offset;
				var rot = Quat.lerp(e.last_tx.orientation, e.transform.orientation, alpha);
				var scale = Vec3.lerp(e.last_tx.scale, e.transform.scale, alpha);
				mtx = Mat4.from_srt(pos, rot, scale);

				inv = Mat4.inverse(mtx);
				inv.transpose();

				if (e.player != null) {
					player_pos = pos;
				}

				if (e.collidable != null && e.player != null) {
					player_size = e.collidable.radius.length();
				}
			}

			if (e.status.message != null) {
				var wpos = mtx * origin;
				var bubble_range = 4;
				if (Vec3.distance(wpos, player.transform.position) < bubble_range) {
					var screen_pos = Mat4.project(wpos, cam_vp, overlay_vp);
					screen_pos.y = vp.h - screen_pos.y;
					if (  screen_pos.x > ui_vp.x && screen_pos.x < ui_vp.z
						&& screen_pos.y > ui_vp.y && screen_pos.y < ui_vp.w
						&& screen_pos.z > 0    && screen_pos.z < 1
					) {
						overlays.push({ id: e.id, text: e.status.message, location: screen_pos });
					}
				}
			}

			var diiiiicks = 0;
			if (e.status.watered) {
				diiiiicks = 28;
			}
			if (closest_tile.id == e.id) {
				diiiiicks = 37;
			}

			var bones = null;
			if (e.animation != null) {
				bones = e.animation.current_pose;
			}

			for (submesh in e.drawable) {
				var mat = MaterialCache.get(submesh.material);
				var cmd: DrawCommand = {
					dicks: diiiiicks,
					xform_mtx: mtx,
					normal_mtx: inv,
					// for sorting
					mesh: submesh,
					material: mat,
					bones: bones
				};
				// #if imgui
				// Ui.text('${submesh.material} => $mat');
				// #end
				forward.push(cmd);
				if (mat.shadow) {
					shadow_draws.push(cmd);
				}
			}
		}

		Lg.setColor(1, 1, 1, 1);

		Profiler.pop_block();

		Profiler.push_block("Render wait");
		Lg.setCanvas(untyped __lua__("{ {0}, depthstencil = {1} }", gbuffer.out1, gbuffer.depth));
		Lg.clear(cast Lg.getBackgroundColor(), cast false, cast true);
		Profiler.pop_block();

		var light = {
			pos: player_pos,
			dir: Time.sun_direction,
			size: player_size
		};
		var light_view = Mat4.look_at(light.pos, light.pos + light.dir, Vec3.up());
		var light_size = light.size * 2;
		var light_proj = Mat4.from_ortho(-light_size, light_size, -light_size, light_size, -light_size, light_size);
		var light_vp = light_proj * light_view;
		var light_vp_biased = Mat4.bias(0.0) * light_vp;

		var really_debug_draw = debug_draw && backend.love.GameLoop.show_imgui;

		ShadowPass.render(shadow.color, shadow.depth, light_vp, shadow_draws);
		ForwardPass.render(gbuffer.out1, gbuffer.depth, light_vp_biased, forward);
		// SkyPass.render(gbuffer.out1, gbuffer.depth);
		Lg.setBlendMode(Alpha);

		if (really_debug_draw) {
			DebugPass.render(gbuffer.out1, gbuffer.depth);
		}
		else {
			Debug.draw(true);
			Debug.clear_capsules();
		}
		PostPass.render(gbuffer, vp, really_debug_draw);

#if imgui
		if (Ui.begin("Render Buffers")) {
			var aspect = Math.min(width/height, height/width);
			Ui.image(shadow.depth, 256, 256, 0, 0, 1, 1);
			if (config.quality.fxaa) {
				Ui.image(gbuffer.out1, 256, 256*aspect, 0, 0, 1, 1);
			}
			else {
				Ui.image(gbuffer.out2, 256, 256*aspect, 0, 0, 1, 1);
			}
		}
		Ui.end();

		if (Ui.begin("Render Stats")) {
			var region = Ui.get_content_region_max();
			Ui.plot_lines("", Main.frame_graph, 0, null, 0, 1/20, region[0] - 10, 100);
			Ui.text('fps: ${backend.Timer.get_fps()}');
			Ui.text('culled: ${culled}');

			if (Ui.tree_node("Dirty Details")) {
				Ui.text('batches: ${forward.length}');
				Ui.same_line();
				Ui.text('(deferred: n/a, forward: ${forward.length})');
				var stats = Lg.getStats();
				var diff = stats.drawcalls - (forward.length);
				Ui.text('misc draws: $diff');
				Ui.text('auto-batched drawcalls: ${stats.drawcallsbatched}');
				Ui.text('total drawcalls: ${stats.drawcalls}');
				Ui.text('canvas switches: ${stats.canvasswitches}');
				Ui.text('texture memory (MiB): ${Std.int(stats.texturememory/1024/1024)}');
				Ui.tree_pop();
			}
		}
		Ui.end();
#end

		Lg.setColor(1, 1, 1, 1);
		Lg.setCanvas();
		Lg.setWireframe(false);
		Lg.setMeshCullMode(None);
		Lg.setDepthMode();
		Lg.setBlendMode(Alpha);
		Lg.setShader();

		// 2D stuff
		Hud.update_overlays(overlays);
		Hud.draw();
		Phone.draw();
		// Menu.draw();

		// reset
		Lg.setColor(1, 1, 1, 1);
	}

	public static function frame(window: PlatformWindow, state: RecycleBuffer<Entity>, alpha: Float) {
		GameInput.bind(GameInput.Action.Debug_F2, function() {
			GameLoop.show_imgui = !GameLoop.show_imgui;
			return true;
		});

		var size = window.get_size();
		if (gbuffer == null) {
			reset(size.width, size.height);
		}
		render_game(size.width, size.height, state, alpha);

		TextureCache.free_unused();
	}
}
