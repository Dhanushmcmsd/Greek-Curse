class_name ChainRecord
extends RefCounted
## Combo chain the defender is in. Stage 07 reads this. It does not sever.

var combo_hits: int = 0
var last_hit_tick: int = 0
var limb_damage: Array[int] = [0, 0, 0, 0]
var contributions: Dictionary = {}


func note(tick: int, gap_limit: int, zone: String, amount: int, attacker: int = 0) -> void:
	var gap := tick - last_hit_tick
	var fresh := combo_hits == 0 or gap > gap_limit
	if fresh:
		combo_hits = 1
		limb_damage = [0, 0, 0, 0]
		contributions = {}
	else:
		combo_hits += 1
	last_hit_tick = tick
	var index := _zone_index(zone)
	if index >= 0:
		limb_damage[index] = limb_damage[index] + amount
		if not contributions.has(zone):
			contributions[zone] = {}
		contributions[zone][attacker] = int(contributions[zone].get(attacker, 0)) + amount


func is_live(tick: int, rules: Dictionary) -> bool:
	return (
		combo_hits >= int(rules["combo_min_hits"])
		and tick - last_hit_tick <= int(rules["grace_ticks"])
	)


func credit_for(zone: String, fallback: int) -> int:
	var amounts: Dictionary = contributions.get(zone, {})
	var ids := amounts.keys()
	ids.sort()
	var best := fallback
	var most := -1
	for id in ids:
		if int(amounts[id]) > most:
			best = int(id)
			most = int(amounts[id])
	return best


func hash_values() -> Array:
	var values: Array = [
		combo_hits, last_hit_tick, limb_damage[0], limb_damage[1], limb_damage[2], limb_damage[3]
	]
	for zone in SimLimbs.LIMB_NAMES:
		var amounts: Dictionary = contributions.get(zone, {})
		var ids := amounts.keys()
		ids.sort()
		values.append(ids.size())
		for id in ids:
			values.append_array([int(id), int(amounts[id])])
	return values


func _zone_index(zone: String) -> int:
	if zone == "arm_l":
		return 0
	if zone == "arm_r":
		return 1
	if zone == "leg_l":
		return 2
	if zone == "leg_r":
		return 3
	return -1
