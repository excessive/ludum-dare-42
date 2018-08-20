import love.mouse.MouseModule;
import love.joystick.GamepadButton;
import love.joystick.GamepadAxis;
import love.joystick.JoystickModule;
import love.joystick.Joystick;
import love.keyboard.KeyConstant;
import love.keyboard.KeyboardModule;
import math.Utils;
import math.Vec2;

enum Action {
	MenuToggle;       // gamepad start
	MenuUp;           // gamepad D-up
	MenuDown;         // gamepad D-down
	MenuLeft;         // gamepad D-left
	MenuRight;        // gamepad D-right
	MenuPrev;         // gamepad LB
	MenuNext;         // gamepad RB
	MenuConfirm;      // gamepad A
	MenuCancel;       // gamepad B

	PrevItem;         // gamepad D-left
	NextItem;         // gamepad D-right
	UsePrimaryItem;   // gamepad A
	UseSecondaryItem; // TODO: gamepad X?

	// virtual inputs
	XLright;
	XLleft;
	YLup;
	YLdown;

	XRright;
	XRleft;
	YRup;
	YRdown;

	XLaxis;
	YLaxis;
	XRaxis;
	YRaxis;

	LTrigger;
	RTrigger;

	Debug_F1;
	Debug_F2;
	Debug_F3;
	Debug_F4;
	Debug_F5;
	Debug_F6;
	Debug_F7;
	Debug_F8;
	Debug_F9;
	Debug_F10;
	Debug_F11;
	Debug_F12;

	Invalid; // anything unbound
}

typedef MouseAction = {
	x: Float,
	y: Float,
	button: Int,
	press: Bool
}

typedef ActionBinding = {
	var player: Null<Action>;
	var menu: Null<Action>;
}

@:publicFields
class InputState {
	var pressed: Float = -1;
	var value: Float = 0;
	var first_update: Bool = true;
	var deadzone: Float = 0.35;
	var updated: Bool = false;
	inline function new() {}
	inline function is_down() {
		return Utils.threshold(value, deadzone) && pressed >= 0;
	}
	inline function value_deadzone() {
		return Utils.deadzone(value, deadzone);
	}
	inline function first_press() {
		return is_down() && first_update;
	}
	function press(v: Float = 1) {
		if (pressed < 0) {
			first_update = true;
			pressed = 0;
		}
		updated = true;
		value = v;
	}
	function update(dt: Float) {
		if (!updated) {
			first_update = true;
			pressed = -1;
			value = 0;
		}
		if (pressed > 0) {
			first_update = false;
			updated = false;
		}
		if (is_down()) {
			pressed += dt;
		}
	}
}

class GameInput {
	static var callbacks = new Map<Action, Void->Bool>();
	static var active: Array<Action> = [];

	static var mouse_mappings = [
		1 => { player: Action.UsePrimaryItem, menu: null },
		2 => { player: Action.UseSecondaryItem, menu: Action.MenuToggle }
	];

	static var kb_mappings = [
		// KeyConstant.Lshift => { player: Action.Slow, menu: null },
		// KeyConstant.Rshift => { player: Action.Slow, menu: null },

		KeyConstant.W => { player: Action.YLup,    menu: Action.MenuUp },
		KeyConstant.S => { player: Action.YLdown,  menu: Action.MenuDown },
		KeyConstant.A => { player: Action.XLleft,  menu: Action.MenuLeft },
		KeyConstant.D => { player: Action.XLright, menu: Action.MenuRight },

		KeyConstant.Q => { player: Action.PrevItem, menu: null },
		KeyConstant.E => { player: Action.NextItem, menu: null },
		KeyConstant.F => { player: Action.UsePrimaryItem, menu: null },
		KeyConstant.Space => { player: Action.UsePrimaryItem, menu: null },

		KeyConstant.Up    => { player: Action.YLup,    menu: Action.MenuUp },
		KeyConstant.Down  => { player: Action.YLdown,  menu: Action.MenuDown },
		KeyConstant.Left  => { player: Action.XLleft,  menu: Action.MenuLeft },
		KeyConstant.Right => { player: Action.XLright, menu: Action.MenuRight },

		KeyConstant.Rshift => { player: Action.PrevItem, menu: null },
		KeyConstant.Kp0 => { player: Action.NextItem, menu: null },

		KeyConstant.Kp8 => { player: Action.YRup,    menu: Action.MenuUp },
		KeyConstant.Kp2 => { player: Action.YRdown,  menu: Action.MenuDown },
		KeyConstant.Kp4 => { player: Action.XRleft,  menu: Action.MenuLeft },
		KeyConstant.Kp6 => { player: Action.XRright, menu: Action.MenuRight },

		KeyConstant.Return    => { player: Action.UsePrimaryItem,     menu: Action.MenuConfirm },
		KeyConstant.Escape    => { player: Action.MenuToggle,  menu: Action.MenuCancel },
		KeyConstant.Backspace => { player: null,               menu: Action.MenuCancel },
	];

	static var gp_mappings = [
		GamepadButton.A => { player: Action.UsePrimaryItem, menu: Action.MenuConfirm },
		GamepadButton.B => { player: null,           menu: Action.MenuCancel },

		GamepadButton.Leftshoulder  => { player: Action.PrevItem,  menu: Action.MenuPrev },
		GamepadButton.Rightshoulder => { player: Action.NextItem, menu: Action.MenuNext },

		GamepadButton.Dpup    => { player: null, menu: Action.MenuUp },
		GamepadButton.Dpdown  => { player: null, menu: Action.MenuDown },
		GamepadButton.Dpleft  => { player: Action.PrevItem, menu: Action.MenuLeft },
		GamepadButton.Dpright => { player: Action.NextItem, menu: Action.MenuRight },

		GamepadButton.Start => { player: Action.MenuToggle,  menu: Action.MenuToggle },
		GamepadButton.Back  => { player: null, menu: Action.MenuCancel }
	];

	static function to_action(key: String): Action {
		switch (key) {
			case "f1":  return Action.Debug_F1;
			case "f2":  return Action.Debug_F2;
			case "f3":  return Action.Debug_F3;
			case "f4":  return Action.Debug_F4;
			case "f5":  return Action.Debug_F5;
			case "f6":  return Action.Debug_F6;
			case "f7":  return Action.Debug_F7;
			case "f8":  return Action.Debug_F8;
			case "f9":  return Action.Debug_F9;
			case "f10": return Action.Debug_F10;
			case "f11": return Action.Debug_F11;
			case "f12": return Action.Debug_F12;
		}
		return Action.Invalid;
	}

	static var input_state = new Map<Action, InputState>();

	public static function keypressed(key: String) {
		var a = to_action(key);
		if (a == Action.Invalid) {
			return;
		}
		active.push(a);
	}

	public static function keyreleased(key: String) {
		var a = to_action(key);
		if (a == Action.Invalid) {
			return;
		}

		var idx = active.indexOf(a);
		if (idx >= 0) {
			active.splice(idx, 1);
		}
	}

	static var mouse_actions: Array<MouseAction> = [];
	static var scroll_offset = { x: 0.0, y: 0.0, scrolled: false };

	public static function wheelmoved(x: Float, y: Float) {
		scroll_offset.x += x;
		scroll_offset.y += y;
		scroll_offset.scrolled = true;
	}

	public static function mousepressed(x: Float, y: Float, button: Int) {
		mouse_actions.push({ x: x, y: y, button: button, press: true });
	}

	public static function mousereleased(x: Float, y: Float, button: Int) {
		mouse_actions.push({ x: x, y: y, button: button, press: false });
	}

	static var mouse_binds = [];
	static var mouse_scroll_binds = [];

	public static function bind_click(cb: MouseAction->Void) {
		mouse_binds.push(cb);
	}

	public static function bind_scroll(cb: Float->Float->Void) {
		mouse_scroll_binds.push(cb);
	}

	static function update_mouse() {
		for (action in mouse_actions) {
			for (cb in mouse_binds) {
				cb(action);
			}
		}
		for (cb in mouse_scroll_binds) {
			if (scroll_offset.x != 0 || scroll_offset.y != 0) {
				cb(scroll_offset.x, scroll_offset.y);
			}
		}

		for (btn in mouse_mappings.keys()) {
			var bind = mouse_mappings[btn];
			var b = MouseModule.isDown(btn);
			var m = bind.menu;
			if (m != null) {
				if (b) { input_state[m].press(1); }
			}
			var p = bind.player;
			if (p != null) {
				if (b) { input_state[p].press(1); }
			}
		}

		mouse_actions.resize(0);
		scroll_offset.x = 0;
		scroll_offset.y = 0;
		scroll_offset.scrolled = false;
	}

	static var gp_raw_axes = [
		GamepadAxis.Leftx  => 0.0,
		GamepadAxis.Lefty  => 0.0,
		GamepadAxis.Rightx => 0.0,
		GamepadAxis.Righty => 0.0,
		GamepadAxis.Triggerleft  => 0.0,
		GamepadAxis.Triggerright => 0.0,
	];

	/** return true from callback to remove it after this frame.
	**/
	public static function bind(input: Action, cb: Void->Bool) {
		callbacks[input] = cb;
	}

	public static function init() {
		var actions = Action.createAll();
		for (action in actions) {
			input_state[action] = new InputState();
		}

		// /!\ LEGENDARY SPLASH INPUT HACK /!\
		// EXPLANATION: basically, when we do state transitions we end up in
		// a state where keys will already be pressed when the state inits.
		// this causes annoying behavior like enter to skip splash ->
		// pressing start on first frame of the menu. the workaround here
		// is to flag all mapped buttons invalid on the first frame, so that
		// they can't be flagged as first-press until they've been released.
		invalidate();
	}

	static function update_gamepads() {
		var joysticks = JoystickModule.getJoysticks();
		for (axis in gp_raw_axes.keys()) {
			gp_raw_axes[axis] = 0;
		}

		lua.PairTools.ipairsEach(joysticks, function(i: Int, js: Joystick) {
			if (!js.isGamepad()) {
				return;
			}

			for (axis in gp_raw_axes.keys()) {
				var v = js.getGamepadAxis(axis);
				if (axis == GamepadAxis.Lefty || axis == GamepadAxis.Righty) {
					v = -v;
				}
				if (Math.abs(v) > Math.abs(gp_raw_axes[axis])) {
					gp_raw_axes[axis] = v;
				}
			}

			for (button in gp_mappings.keys()) {
				var b = js.isGamepadDown(button);
				var m = gp_mappings[button].menu;
				if (m != null) {
					if (b) { input_state[m].press(1); }
					if (b) { active.push(m); }
				}
				var p = gp_mappings[button].player;
				if (p != null) {
					if (b) { input_state[p].press(1); }
					if (b) { active.push(p); }
				}
			}
		});
	}

	static function update_keyboard() {
		for (key in kb_mappings.keys()) {
			var bind = kb_mappings[key];
			var b = KeyboardModule.isDown(Std.string(key));
			var m = bind.menu;
			if (m != null) {
				if (b) { input_state[m].press(1); }
			}
			var p = bind.player;
			if (p != null) {
				if (b) { input_state[p].press(1); }
			}
		}
	}

	public static inline function pressed(gi: Action) {
		return input_state[gi].first_press();
	}

	public static inline function get_value(gi: Action) {
		return input_state[gi].value_deadzone();
	}

	// handle combined deadzones
	public static function move_xy() {
		if (locked) {// || Stage.stop_time) {
			return new Vec2(0, 0);
		}
		var x = input_state[Action.XLaxis];
		var y = input_state[Action.YLaxis];
		var ret = new Vec2(x.value, y.value);
		// var p = 2;
		// var ret = new Vec2(Math.pow(x.value, p)*Utils.sign(x.value), Math.pow(y.value, p)*Utils.sign(y.value));
		var l = ret.length();
		if (l < Math.max(x.deadzone, y.deadzone)) {
			ret[0] = 0;
			ret[1] = 0;
		}
		if (l > 0.95) {
			var dz = 0.4;
			ret.x += Math.abs(ret.x) > dz ? Utils.sign(ret.x) : 0;
			ret.y += Math.abs(ret.y) > dz ? Utils.sign(ret.y) : 0;
			ret.normalize();
			l = ret.length();
		}
		return ret;
	}

	public static function view_xy() {
		if (locked) {
			return new Vec2(0, 0);
		}
		var x = input_state[Action.XRaxis];
		var y = input_state[Action.YRaxis];
		var ret = new Vec2(x.value, -y.value);
		var l = ret.length();
		if (l < Math.max(x.deadzone, y.deadzone)) {
			ret[0] = 0;
			ret[1] = 0;
		}
		if (l > 1) {
			ret.scale(1/l);
		}
		return ret;
	}

	static var _inner_lock = false;
	public static var locked(get, null): Bool;
	static inline function get_locked(): Bool {
		return _inner_lock;// || console.Console.visible;
	}

	public static inline function spin_lock() {
		if (_inner_lock) {
			unlock();
		}
		else {
			lock();
		}
	}

	public static inline function lock() {
		Signal.emit("quiet");
		_inner_lock = true;
	}

	public static inline function unlock() {
		Signal.emit("loud");
		_inner_lock = false;
	}

	static var _queue_unlock = false;
	public static inline function queue_unlock() {
		_queue_unlock = true;
	}

	static function invalidate() {
		for (btn in mouse_mappings.keys()) {
			var bind = mouse_mappings[btn];
			var m = bind.menu;
			if (m != null) {
				input_state[m].first_update = false;
				input_state[m].pressed = 1e-9;
			}
			var p = bind.player;
			if (p != null) {
				input_state[p].first_update = false;
				input_state[p].pressed = 1e-9;
			}
		}

		for (key in kb_mappings.keys()) {
			var bind = kb_mappings[key];
			var m = bind.menu;
			if (m != null) {
				input_state[m].first_update = false;
				input_state[m].pressed = 1e-9;
			}
			var p = bind.player;
			if (p != null) {
				input_state[p].first_update = false;
				input_state[p].pressed = 1e-9;
			}
		}

		for (b in gp_mappings.keys()) {
			var bind = gp_mappings[b];
			var m = bind.menu;
			if (m != null) {
				input_state[m].first_update = false;
				input_state[m].pressed = 1e-9;
			}
			var p = bind.player;
			if (p != null) {
				input_state[p].first_update = false;
				input_state[p].pressed = 1e-9;
			}
		}
	}

	public static function update(dt: Float) {
		if (_queue_unlock) {
			_queue_unlock = false;
			unlock();
		}

		for (run in active) {
			if (callbacks.exists(run)) {
				var fn = callbacks[run];
				if (fn()) {
					active.remove(run);
					break;
				}
			}
		}
		callbacks = new Map<Action, Void->Bool>();

		update_gamepads();
		update_keyboard();
		update_mouse();

		// combine kb and gamepad axes...
		var v = gp_raw_axes[GamepadAxis.Leftx];
		input_state[Action.XLright].value += Math.max(v, 0);
		input_state[Action.XLleft].value  += Math.max(-v, 0);

		v = gp_raw_axes[GamepadAxis.Lefty];
		input_state[Action.YLup].value   += Math.max(v, 0);
		input_state[Action.YLdown].value += Math.max(-v, 0);

		v = gp_raw_axes[GamepadAxis.Rightx];
		input_state[Action.XRright].value += Math.max(v, 0);
		input_state[Action.XRleft].value  += Math.max(-v, 0);

		v = gp_raw_axes[GamepadAxis.Righty];
		input_state[Action.YRup].value   += Math.max(v, 0);
		input_state[Action.YRdown].value += Math.max(-v, 0);

		input_state[Action.XLaxis].press(input_state[Action.XLright].value - input_state[Action.XLleft].value);
		input_state[Action.YLaxis].press(input_state[Action.YLup].value    - input_state[Action.YLdown].value);
		input_state[Action.XRaxis].press(input_state[Action.XRright].value - input_state[Action.XRleft].value);
		input_state[Action.YRaxis].press(input_state[Action.YRup].value    - input_state[Action.YRdown].value);

		for (action in input_state.keys()) {
			var bind = input_state[action];
			bind.update(dt);
		}
	}
}
