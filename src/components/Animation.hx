package components;

import anim.Timeline;
import anim.TimelineTrack;
import anim.AnimSkeleton;

typedef Animation = {
	var timeline: Timeline;
	var actions: Map<String, TimelineTrack>;
	var skeleton: AnimSkeleton;
}
