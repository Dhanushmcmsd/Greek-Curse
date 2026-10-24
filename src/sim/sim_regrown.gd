class_name SimRegrown
extends RefCounted
## Small data-key hooks; no limb IDs or presentation dependencies here.


static func effects(fighter: SimFighter, slot: String) -> Dictionary:
	if not fighter.limbs.parts.has(slot):
		return {}
	var limb: SimLimb = fighter.limbs.parts[slot]
	if limb.regrown_id == "" or limb.state == "severed":
		return {}
	return fighter.limbs.catalog[limb.regrown_id]["modifiers"]


static func begin(fighter: SimFighter, move: Dictionary) -> void:
	var effect := effects(fighter, fighter.attack_slot)
	var category := str(move.get("category", ""))
	if category in ["light", "heavy", "kick"] and not str(move["id"]).begins_with("body_"):
		fighter.hit_w = (
			Fx.percent(fighter.hit_x + fighter.hit_w, fighter.reach_percent) - fighter.hit_x
		)
	if category == "light":
		fighter.hit_w = (
			Fx.percent(fighter.hit_x + fighter.hit_w, int(effect.get("light_reach_percent", 100)))
			- fighter.hit_x
		)
	if category == "heavy":
		fighter.attack_damage = Fx.percent(
			fighter.attack_damage, int(effect.get("heavy_damage_percent", 100))
		)
	if category == "kick":
		fighter.attack_damage = Fx.percent(
			fighter.attack_damage, int(effect.get("kick_damage_percent", 100))
		)
	if category == "grab" and effect.has("grab_chip_percent"):
		fighter.attack_damage = Fx.percent(fighter.attack_damage, int(effect["grab_chip_percent"]))
	fighter.attack_category = category


static func whiff(world: SimWorld, fighter: SimFighter) -> int:
	if fighter.landed_hit:
		return 0
	var effect := effects(fighter, fighter.attack_slot)
	if fighter.attack_category == "heavy":
		return int(effect.get("heavy_whiff_stagger_ticks", 0))
	if fighter.attack_category == "grab" and effect.has("grab_whiff_chance"):
		if world.rng.range_i(0, 100) < int(effect["grab_whiff_chance"]):
			return int(effect["grab_whiff_stagger_ticks"])
	return 0


static func after_movement(world: SimWorld, fighter: SimFighter, events: Array) -> void:
	if fighter.state != SimFighter.State.WALK:
		return
	for slot in SimLimbs.LIMB_NAMES:
		var effect := effects(fighter, slot)
		var interval := int(effect.get("zoom_interval_ticks", 0))
		if interval <= 0 or world.tick % interval != 0:
			continue
		if world.rng.range_i(0, 100) < int(effect["zoom_chance"]):
			var direction := world.rng.range_i(0, 2) * 2 - 1
			fighter.x += direction * int(effect["zoom_mm"])
			var event := SimEvent.make(
				SimEvent.Kind.LIMB_QUIRK, world.fighters.find(fighter), -1, 0, world.round_index, -1
			)
			event.payload = {
				"quirk": "zoom", "slot": slot, "direction": direction, "tick": world.tick
			}
			events.append(event)
