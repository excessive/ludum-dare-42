import iqm.Iqm;
import iqm.Iqm.ExmMeta;
import math.Bounds;
import math.Mat4;
import math.Octree;
import math.Triangle;
import math.Utils;
import math.Vec3;

class World {
	static var tri_octree: Octree<Triangle>;

	public static inline function convert(t: lua.Table<Int, Dynamic>) {
		var tris = [];
		// so it turns out: I know something about math.Triangle.
		// it's a liar. it doesn't use vec3's, it just decomposes them.
		// so reuse this and be nicer to the gc
		var v0 = new Vec3(0, 0, 0);
		var v1 = new Vec3(0, 0, 0);
		var v2 = new Vec3(0, 0, 0);
		var zero = Vec3.zero();
		lua.PairTools.ipairsEach(t, function(i, v) {
			v0.set_xyz(v[1].position[1], v[1].position[2], v[1].position[3]);
			v1.set_xyz(v[2].position[1], v[2].position[2], v[2].position[3]);
			v2.set_xyz(v[3].position[1], v[3].position[2], v[3].position[3]);
			tris.push(Triangle.without_normal(v0, v1, v2));
		});
		return tris;
	}

	public static function load(filename: String) {
		var root = new SceneNode();
		root.name = "Map";
		root.hidden = true;

		var meta: ExmMeta = null;
		if (backend.Fs.is_file(filename)) {
			console.Console.is('loading stage $filename');
		}
		else {
			throw "ARGH!";
		}

		var map_model = Iqm.load(filename, true);
		root.name = "MapExtras";
		root.transform.is_static = true;
		root.transform.update();

		meta = Iqm.decode_meta(map_model);

		var base: Bounds = untyped __lua__("{0}.base", map_model.bounds);

		var world_size = base.max[0] - base.min[0];
		world_size = Utils.max(world_size, base.max[1] - base.min[1]);
		world_size = Utils.max(world_size, base.max[2] - base.min[2]);
		world_size *= 1.01;

		var center = new Vec3(
			(base.min[0] + base.max[0]) / 2,
			(base.min[1] + base.max[1]) / 2,
			(base.min[2] + base.max[2]) / 2
		);

		// for the stages tested, 1.05 seemed to help perf & memory usage
		var octree_looseness = 1.05;
		var min_size = 5.0;
		tri_octree = new Octree(world_size, center, min_size, octree_looseness);

		root.drawable = IqmLoader.get_views(map_model);

		var tris = convert(map_model.triangles);
		add_triangles(tris, new Mat4());

		return root;
	}

	public static function get_triangles(min: Vec3, max: Vec3): Array<Triangle> {
		var tris = tri_octree.get_colliding(Bounds.from_extents(min, max));
		return tris;
	}

	public static function add_triangles(tris: Array<Triangle>, ?xform: Mat4) {
		for (t in tris) {
			var xt = t;
			if (xform != null) {
				xt = Triangle.transform(t, xform);
			}
			var min = xt.min();
			var max = xt.max();
			tri_octree.add(xt, Bounds.from_extents(min, max));
		}
	}
}
