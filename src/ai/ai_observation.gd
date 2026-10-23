class_name AIObservation
extends RefCounted
## Detached visible-state data; no live fighter/world references escape capture.


static func capture(world: SimWorld, index: int) -> Dictionary:
	var own := world.fighters[index]
	var other := world.fighters[1 - index]
	var options: Array = []
	for mask in [16, 32, 64, 18, 34, 72, 80, 17, 33]:
		var chosen := SimMoveAvailability.select(own, mask, world.body_rules)
		if chosen.is_empty():
			continue
		for move in world.moves:
			if move["id"] == chosen["id"]:
				options.append(
					{
						"mask": mask,
						"id": move["id"],
						"cost": int(move["cost"]),
						"damage": int(move["damage"]),
						"startup": int(move["startup_ticks"]),
						"range":
						int(move["hitbox"]["x"]) + int(move["hitbox"]["w"]) + other.half_width(),
						"limb_damage": int(move["limb_damage"]),
						"grab": bool(move["is_grab"])
					}
				)
	return {
		"tick": world.tick,
		"x": own.x,
		"other_x": other.x,
		"facing": own.facing,
		"state": own.state,
		"other_state": other.state,
		"stamina": own.stamina,
		"can_block": own.limbs.can_block(),
		"other_blocking": other.blocking,
		"other_limbs": other.limbs.export_state(),
		"body": SimBodyState.derive(own.limbs),
		"options": options
	}
