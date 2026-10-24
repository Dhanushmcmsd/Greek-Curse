class_name SimHazards
extends RefCounted


static func configure(world: SimWorld, data: Dictionary, enabled: bool, seed: int) -> void:
	world.arena_rules = data
	world.hazards_enabled = enabled and data["hazard"]["type"] != "none"
	var schedule := SimRng.new(seed + 901)
	world.hazard_offset = schedule.range_i(1, int(data["hazard"]["period"]))
	world.hazard_zone = schedule.range_i(0, 2)


static func step(world: SimWorld, events: Array) -> void:
	if not world.hazards_enabled or world.tick < world.hazard_offset:
		return
	var rule: Dictionary = world.arena_rules["hazard"]
	var period := int(rule["period"])
	var age := (world.tick - world.hazard_offset) % period
	var cycle := (world.tick - world.hazard_offset) / period
	var zone: Array = rule["zones"][(cycle + world.hazard_zone) % rule["zones"].size()]
	if cycle != world.hazard_cycle:
		world.hazard_cycle = cycle
		world.hazard_hits = 0
	if age == 0 or age == int(rule["telegraph_ticks"]):
		var event := SimEvent.make(SimEvent.Kind.HAZARD, -1, -1, 0, world.round_index, -1)
		event.payload = {
			"stage": "warning" if age == 0 else "active",
			"zone": zone,
			"type": rule["type"],
			"tick": world.tick
		}
		events.append(event)
	if (
		age < int(rule["telegraph_ticks"])
		or age >= int(rule["telegraph_ticks"]) + int(rule["active_ticks"])
	):
		return
	for index in world.fighters.size():
		var fighter := world.fighters[index]
		if world.hazard_hits & (1 << index) or fighter.x < int(zone[0]) or fighter.x > int(zone[1]):
			continue
		world.hazard_hits |= 1 << index
		fighter.health = maxi(0, fighter.health - int(rule["damage"]))
		if rule["type"] == "lightning":
			var charred := SimModifier.new()
			charred.id = "charred"
			charred.expires_tick = world.tick + 300
			fighter.modifiers.append(charred)
		for slot in SimLimbs.LIMB_NAMES:
			if fighter.limbs.parts[slot].state != "severed":
				SimSeverance.hit(
					world, index, 1 - index, slot, int(rule["limb_damage"]), events, false
				)
				break
		if fighter.health == 0:
			fighter.state = SimFighter.State.KO
		var event := SimEvent.make(
			SimEvent.Kind.HAZARD, -1, index, int(rule["damage"]), world.round_index, -1
		)
		event.payload = {"stage": "damage", "zone": zone, "type": rule["type"], "tick": world.tick}
		events.append(event)
