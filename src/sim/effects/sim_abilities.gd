class_name SimAbilities
extends RefCounted


static func ready(world: SimWorld, fighter: SimFighter, id: String) -> bool:
	if not world.abilities.has(id):
		return true
	var ability: Dictionary = world.abilities[id]
	return (
		world.tick >= int(fighter.ability_cooldowns.get(id, 0))
		and fighter.meter >= int(ability["meter_cost"])
	)


static func begin(world: SimWorld, fighter: SimFighter, id: String) -> void:
	if not world.abilities.has(id):
		return
	var ability: Dictionary = world.abilities[id]
	var event := SimEvent.make(
		SimEvent.Kind.ABILITY, world.fighters.find(fighter), -1, 0, world.round_index, -1
	)
	event.payload = {"id": id, "type": ability["type"]}
	world.pending_events.append(event)
	fighter.meter -= int(ability["meter_cost"])
	fighter.ability_cooldowns[id] = world.tick + int(ability["cooldown_ticks"])
	fighter.ability_uses[id] = int(fighter.ability_uses.get(id, 0)) + 1
	for effect in ability["effects"]:
		if effect.get("timing", "") == "begin":
			apply(world, fighter, fighter, effect)


static func on_hit(world: SimWorld, attacker: SimFighter, target: SimFighter, zone: String) -> void:
	if not world.abilities.has(attacker.move_name):
		return
	for effect in world.abilities[attacker.move_name]["effects"]:
		var timing: String = effect.get("timing", "")
		if (
			timing == "hit"
			or (timing == "last_hit" and attacker.hits_done == attacker.attack_hit_count - 1)
		):
			apply(world, attacker, target, effect, zone)


static func apply(
	world: SimWorld, source: SimFighter, target: SimFighter, effect: Dictionary, zone: String = ""
) -> void:
	match str(effect["kind"]):
		"dash":
			source.x += source.facing * int(effect["distance"])
			source.invulnerable_until = world.tick + int(effect["invulnerable_ticks"])
		"shield":
			source.shield = int(effect["absorb"])
			source.shield_burst = int(effect["burst_damage"])
		"buff_self", "stone_stiff", "status_limb_vulnerability":
			var recipient := source if effect["kind"] == "buff_self" else target
			var modifier := SimModifier.new()
			modifier.id = str(effect["kind"])
			modifier.expires_tick = world.tick + int(effect["duration"])
			modifier.damage_percent = int(effect.get("damage_percent", 100))
			modifier.speed_percent = int(effect.get("speed_percent", 100))
			modifier.taken_percent = int(effect.get("taken_percent", 100))
			modifier.limb_percent = int(effect.get("limb_percent", 100))
			for i in range(recipient.modifiers.size() - 1, -1, -1):
				if recipient.modifiers[i].id == modifier.id:
					recipient.modifiers.remove_at(i)
			recipient.modifiers.append(modifier)
		"ground_bounce":
			target.y = int(effect["amount"])
		"force_limb_state":
			if not target.limbs.parts.has(zone):
				zone = "arm_l"
			var limb: SimLimb = target.limbs.parts[zone]
			if limb.state != "severed":
				limb.integrity = mini(limb.integrity, Fx.percent(limb.max_integrity, 25))
				target.limbs.integrity[zone] = limb.integrity
				limb.refresh(world.limb_rules)


static func incoming(fighter: SimFighter, tick: int, amount: int, limb: bool) -> int:
	var percent := fighter.passive_limb_percent if limb else 100
	for modifier in fighter.modifiers:
		if tick < modifier.expires_tick:
			percent = Fx.percent(percent, modifier.limb_percent if limb else modifier.taken_percent)
	return Fx.percent(amount, percent)


static func passive(world: SimWorld, fighter: SimFighter) -> void:
	for id in fighter.loadout.get("passive", []):
		for effect in world.abilities[id]["effects"]:
			fighter.passive_limb_percent = int(effect.get("limb_percent", 100))
			fighter.passive_speed_percent = int(effect.get("speed_percent", 100))
			fighter.frenzy_maximum = int(effect.get("maximum", 100))
			if effect.has("integrity_percent"):
				fighter.limbs.max_integrity = Fx.percent(
					fighter.limbs.max_integrity, int(effect["integrity_percent"])
				)
				for slot in SimLimbs.LIMB_NAMES:
					var limb: SimLimb = fighter.limbs.parts[slot]
					limb.max_integrity = Fx.percent(
						limb.max_integrity, int(effect["integrity_percent"])
					)
					limb.integrity = limb.max_integrity
					fighter.limbs.integrity[slot] = limb.integrity


static func speed(fighter: SimFighter, maximum_health: int) -> int:
	var frenzy := (
		100
		+ (
			(fighter.frenzy_maximum - 100)
			* (maximum_health - fighter.health)
			/ maxi(1, maximum_health)
		)
	)
	return Fx.percent(fighter.passive_speed_percent, frenzy)
