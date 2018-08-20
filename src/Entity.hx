import components.*;

import anim9.Anim9;
import math.Bounds;

typedef Entity = {
	var id: Int;
	var bounds:     Bounds;
	var transform:  Transform;
	var item:       Item;
	var animation:  Anim9;
	var status:     Status;
	var last_tx:    Transform;
	var collidable: Collidable;
	var drawable:   Drawable;
	var physics:    Physics;
	var player:     Player;
	var trigger:    Trigger;
	var emitter:    Array<Emitter>;
}
