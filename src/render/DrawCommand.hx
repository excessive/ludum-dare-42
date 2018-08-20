package render;

// import math.Vec3;
import math.Mat4;
import components.Material;

import lua.Table;

typedef DrawCommand = {
	var dicks: Int;
	var xform_mtx: Mat4;
	var normal_mtx: Mat4;
	var mesh: MeshView;
	var material: Material;
	// var view_pos: Vec3;
	var bones: Table<Dynamic, Dynamic>;
}
