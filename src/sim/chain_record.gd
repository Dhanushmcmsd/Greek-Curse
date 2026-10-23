class_name ChainRecord
extends RefCounted
## Combo chain the defender is in. Stage 07 reads this. It does not sever.

var combo_hits: int = 0
var last_hit_tick: int = 0
var limb_damage: Array[int] = [0, 0, 0, 0]


func note(tick: int, gap_limit: int, zone: String, amount: int) -> void:
	var gap := tick - last_hit_tick
	var fresh := combo_hits == 0 or gap > gap_limit
	if fresh:
		combo_hits = 1
		limb_damage = [0, 0, 0, 0]
	else:
		combo_hits += 1
	last_hit_tick = tick
	var index := _zone_index(zone)
	if index >= 0:
		limb_damage[index] = limb_damage[index] + amount


func hash_values() -> Array:
	return [
		combo_hits, last_hit_tick, limb_damage[0], limb_damage[1], limb_damage[2], limb_damage[3]
	]


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
