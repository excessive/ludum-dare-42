package render;

import love.graphics.Canvas;
import love.graphics.GraphicsModule as Lg;
import math.Vec3;
import math.Mat4;

class DebugPass {
	public static function render(shaded: Canvas, depth: Canvas) {
		Lg.setCanvas(untyped __lua__(
			"{ {0}, depthstencil = {1} }",
			shaded, depth
		));
		Lg.setWireframe(true);
		Lg.setDepthMode(Lequal, false);

		var shader = Shader.get("debug");
		var camera = Render.camera;
		Lg.setShader(shader);
		Helpers.send_uniforms(camera, shader);

		var cfg = Render.config;
		var exposure = cfg.color.exposure;
		var rgb = Render.white_point;
		var r = rgb[0], g = rgb[1], b = rgb[2];

		var white = new Vec3(r, g, b);
		Helpers.send(shader, "u_white_point", white.unpack());
		Helpers.send(shader, "u_exposure", exposure);

		Lg.setMeshCullMode(None);
		Helpers.send(shader, "u_model", new Mat4().to_vec4s());

		Debug.draw(false);

		Lg.setShader();

		// todo
		// Debug.clear_capsules();

		Lg.setWireframe(false);
	}
}
