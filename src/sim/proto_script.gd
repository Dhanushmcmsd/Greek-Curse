class_name ProtoScript
extends RefCounted
## Fixed input log for the prototype golden match. Tick 0 is the first step.


static func inputs_at(tick: int) -> Array:
	if tick < 80:
		return [SimInput.RIGHT, SimInput.LEFT]
	# Keep walking in. A round reset puts the fighters back at their marks, and a
	# held attack does not move them on its own.
	return [SimInput.RIGHT | SimInput.LIGHT, 0]
