import love.graphics.Mesh;
import utils.RecycleBuffer;

class Scene {
	public var root = new SceneNode();
	var entities = new RecycleBuffer<Entity>();

	public function release() {
		var entities = this.get_entities();
		var meshes = new Map<Mesh, Bool>();
		for (e in entities) {
			var drawable = e.drawable;
			if (drawable.length == 0) {
				continue;
			}
			for (view in drawable) {
				var mesh = view.use();
				meshes[mesh] = true;
			}
		}
		for (m in meshes.keys()) {
			m.release();
			meshes.remove(m);
		}
	}

	public inline function get_child(name: String): Null<SceneNode> {
		return root.get_child(name);
	}

	public function new() {
		root.name = "Root";
	}

	public inline function get_entities(?cb: Entity->Bool): RecycleBuffer<Entity> {
		entities.reset();
		SceneNode.flatten_tree(root, entities);
		return entities;
	}

	public inline function get_visible_entities(): RecycleBuffer<Entity> {
		#if 0
		var culled = 0;
		return get_entities((e: Entity) -> {
			if (e.bounds != null && e.transform.is_static) {
				if (!Intersect.aabb_frustum(e.bounds, camera.frustum)) {
					culled += 1;
					return false;
				}
			}
			return true;
		});
		#end
		return get_entities();
	}

	function update_parents(base: SceneNode) {
		for (child in base.children) {
			child.parent = base;
			update_parents(child);
		}
	}

	public function add(node: SceneNode) {
		root.children.push(node);

		if (node.parent == null) {
			node.parent = root;
		}
		for (child in node.children) {
			update_parents(node);
		}
	}

	public function remove(node: SceneNode) {
		if (node.parent != null) {
			node.parent.children.remove(node);
		}
	}
}
