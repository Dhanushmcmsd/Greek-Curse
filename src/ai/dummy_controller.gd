class_name DummyController
extends RefCounted


static func input_for(mode: String, tick: int) -> int:
	match mode:
		"block_always":
			return SimInput.BLOCK
		"walk_back_forth":
			return SimInput.LEFT if tick % 240 < 120 else SimInput.RIGHT
		"attack_on_interval":
			return SimInput.LIGHT if tick % 90 == 0 else 0
	return 0


static func reset(world: SimWorld) -> void:
	world.reset_for_match("practice")
