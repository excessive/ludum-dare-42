package utils;

import love.window.WindowModule as Lw;

import math.Vec2;
// import math.Vec3;
// import backend.Timer;

class Scroller<T, U> {
	// var default_sounds = {
	// 	prev   = false,
	// 	next   = false,
	// 	select = false
	// }

	var fixed: Bool;
	var switch_time: Float;
	var size: Null<Vec2>;
	// var sounds      = options.sounds       or default_sounds;
	var transform: Float->Int->Int->Vec2;
	var position: Void->Vec2;
	// var cursor_data: Vec2;
	var data: Array<Vec2>;
	// var _timer: Timer;
	// var _rb: RingBuffer<T>;
	// var _pos   = 1;
	// var _tween: Bool;
	// var _last_hit: Vec2;

	public function new(items: T, options: U) {
		this.fixed = false;
		this.switch_time = 0.2;
		this.size = null;
		this.transform = function(offset: Float, count: Int, index: Int): Vec2 {
			var spacing = Lw.toPixels(50);
			return new Vec2(
				Math.floor(Math.cos(offset / (count / 2)) * Lw.toPixels(50)),
				Math.floor(offset * spacing)
			);
		}
		this.position = function() {
			return new Vec2(0, 0);
		}
		this.data = [];
		// this.sounds      = options.sounds       or default_sounds,
		// this._timer = timer.new(),
		// this._rb    = ringbuffer(items),
		// this._pos   = 1,
		// this._tween = false,
		// this._last_hit = { love.mouse.getPosition() }
	}

	// var function new(items, options)
	// 	var t = {
	// 	}
	// 	t = setmetatable(t, scroller_mt)
	// 	t:reset()
	// 	return t
	// end

	// scroller_mt.__index = scroller
	// scroller_mt.__call  = function(_, ...)
	// 	return new(...)
	// end
	// var function tween(self)
	// 	if self._tween then
	// 		self._timer:cancel(self._tween)
	// 	end
	// 	self._tween = self._timer:tween(self.switch_time, self, { _pos = self._rb.current }, "out-back")
	// end

	// function scroller:get()
	// 	return self._rb.items[self._rb.current]
	// end

	// function scroller:prev(n)
	// 	if self.sounds.prev then
	// 		self.sounds.prev:stop()
	// 		self.sounds.prev:play()
	// 	end
	// 	for _ = 1, (n or 1) do self._rb:prev() end
	// 	var item = self:get()
	// 	if item.skip then
	// 		self:prev()
	// 	else
	// 		tween(self)
	// 	end
	// end

	// function scroller:next(n)
	// 	if self.sounds.next then
	// 		self.sounds.next:stop()
	// 		self.sounds.next:play()
	// 	end

	// 	for _ = 1, (n or 1) do self._rb:next() end
	// 	var item = self:get()
	// 	if item.skip then
	// 		self:next()
	// 	else
	// 		tween(self)
	// 	end
	// end

	// function scroller:reset()
	// 	self._rb:reset()

	// 	-- If you manage to land on a skip that is bad mojo, go to the next one
	// 	var item = self:get()
	// 	while item.skip do
	// 		self:next()
	// 		item = self:get()
	// 	end

	// 	-- throw in a big number to force an initial skip to not animate
	// 	self:update(math.huge)
	// end

	// function scroller:hit(x, y, click)
	// 	if not self.size or (not self.fixed and not click) then
	// 		self._last_hit = false
	// 		return false
	// 	end
	// 	if self._last_hit and self._last_hit[1] == x and self._last_hit[2] == y then
	// 		if not click then
	// 			return false
	// 		end
	// 	end
	// 	self._last_hit = { x, y }
	// 	var p = cpml.vec3(x, y, 0)
	// 	for i, item in ipairs(self._rb.items) do
	// 		var b = {
	// 			min = cpml.vec3(self.data[i].x, self.data[i].y, 0),
	// 			max = cpml.vec3(self.data[i].x + self.size.w, self.data[i].y + self.size.h, 0)
	// 		}
	// 		if not item.skip and cpml.intersect.point_aabb(p, b) then
	// 			self._rb.current = i
	// 			tween(self)
	// 			return true
	// 		end
	// 	end
	// 	return false
	// end

	// function scroller:update(dt)
	// 	self._timer:update(dt)
	// 	var x, y = self:position()
	// 	for i, v in ipairs(self._rb.items) do
	// 		self.data[i] = setmetatable({ x = 0, y = 0 }, { __index = v })
	// 		var ipos = i
	// 		if not self.fixed then
	// 			ipos = ipos - self._pos
	// 		end
	// 		self.transform(self.data[i], ipos, #self._rb.items, i)
	// 		self.data[i].x = self.data[i].x + x
	// 		self.data[i].y = self.data[i].y + y
	// 	end
	// 	self.transform(self.cursor_data, self.fixed and self._pos or 0, #self._rb.items, 1)
	// 	self.cursor_data.x = self.cursor_data.x + x
	// 	self.cursor_data.y = self.cursor_data.y + y

	// 	while #self.data > #self._rb.items do
	// 		table.remove(self.data)
	// 	end
	// end
}
