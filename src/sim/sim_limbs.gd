class_name SimLimbs
extends RefCounted
## Limb integrity storage. Severing thresholds are stage 07.
## apply_limb_damage is the hook that stage calls.

const LIMB_NAMES: Array[String] = ["arm_l", "arm_r", "leg_l", "leg_r"]

var max_integrity: int = 100
var integrity: Dictionary = {}
var profiles: Dictionary = {}
var parts: Dictionary = {}
var losses: int = 0
var rules: Dictionary = {}
var catalog: Dictionary = {}
var modifiers: Array[SimModifier] = []


var limb_damage_tracker: Dictionary = {
	"arm_l": 0, "arm_r": 0, "leg_l": 0, "leg_r": 0
}
var amputation_occurred: bool = false


func setup(row: Dictionary, combat: Dictionary, toughness: int) -> void:
	var curve: Array = combat["toughness_percent"]
	max_integrity = Fx.percent(int(combat["integrity_base"]), int(curve[toughness]))
	integrity = {}
	limb_damage_tracker = {"arm_l": 0, "arm_r": 0, "leg_l": 0, "leg_r": 0}
	amputation_occurred = false
	for name in LIMB_NAMES:
		integrity[name] = max_integrity
		var limb := SimLimb.new()
		limb.integrity = max_integrity
		limb.max_integrity = max_integrity
		parts[name] = limb
	profiles = row["hurtboxes"]


func register_limb_hit(limb_id: String, damage: int, is_block: bool) -> void:
	if is_block:
		damage = int(damage * 0.25)
	if limb_damage_tracker.has(limb_id):
		limb_damage_tracker[limb_id] += damage


func highest_damaged_limb() -> String:
	var best_limb: String = ""
	var max_dmg: int = -1
	for name in LIMB_NAMES:
		if parts.has(name) and parts[name].state != "severed":
			var dmg: int = int(limb_damage_tracker.get(name, 0))
			if dmg > max_dmg:
				max_dmg = dmg
				best_limb = name
	return best_limb


func apply_limb_damage(zone: String, amount: int) -> int:
	if amount <= 0 or not integrity.has(zone):
		return 0
	var current := int(integrity[zone])
	var next := current - amount
	if next < 0:
		next = 0
	integrity[zone] = next
	var limb: SimLimb = parts[zone]
	limb.integrity = next
	limb.refresh(rules)
	return current - next


func usable(zone: String) -> bool:
	if not parts.has(zone):
		return false
	var limb: SimLimb = parts[zone]
	return limb.state == "healthy" or limb.state == "bruised"


func can_block() -> bool:
	return usable("arm_l") or usable("arm_r")


func regrow(slot: String, id: String) -> bool:
	if not parts.has(slot) or not catalog.has(id):
		return false
	var limb: SimLimb = parts[slot]
	var definition: Dictionary = catalog[id]
	if limb.state != "severed" or not slot.begins_with(str(definition["slot"])):
		return false
	var effect: Dictionary = definition["modifiers"]
	limb.max_integrity = Fx.percent(max_integrity, int(effect.get("integrity_max_percent", 100)))
	limb.integrity = Fx.percent(max_integrity, int(definition["integrity_pct"]))
	limb.state = "healthy"
	limb.regrown_id = id
	limb.zero_pending = false
	limb.cap_blocked = false
	limb.refresh(rules)
	integrity[slot] = limb.integrity
	register_modifier(slot)
	return true


func register_modifier(slot: String) -> void:
	remove_modifier(slot)
	var limb: SimLimb = parts[slot]
	if limb.regrown_id == "" or limb.state == "severed" or not catalog.has(limb.regrown_id):
		return
	var modifier := SimModifier.new()
	modifier.id = "regrown:" + slot
	modifier.expires_tick = 2147483647
	modifier.speed_percent = int(catalog[limb.regrown_id]["modifiers"].get("speed_percent", 100))
	modifiers.append(modifier)


func remove_modifier(slot: String) -> void:
	for index in range(modifiers.size() - 1, -1, -1):
		if modifiers[index].id == "regrown:" + slot:
			modifiers.remove_at(index)


func export_state() -> Dictionary:
	var result := {}
	for zone in LIMB_NAMES:
		result[zone] = parts[zone].export_state()
	return result


func restore_state(rows: Dictionary) -> void:
	for zone in LIMB_NAMES:
		if not rows.has(zone):
			continue
		var row: Dictionary = rows[zone]
		var limb: SimLimb = parts[zone]
		limb.max_integrity = maxi(1, int(row.get("max_integrity", max_integrity)))
		limb.integrity = int(row.get("integrity", limb.max_integrity))
		limb.state = str(row.get("state", "healthy"))
		limb.zero_pending = bool(row.get("zero_pending", false))
		limb.regrown_id = str(row.get("regrown_id", ""))
		limb.credited = false
		limb.cap_blocked = false
		limb.refresh(rules)
		integrity[zone] = limb.integrity
		register_modifier(zone)
	losses = 0


func world_boxes(
	body_x: int, body_y: int, body_width: int, body_height: int, pose: String
) -> Array:
	var pose_name := pose if profiles.has(pose) else "standing"
	var source: Array = profiles[pose_name]
	var boxes: Array = []
	for entry in source:
		var spec: Dictionary = entry
		if parts.has(str(spec["name"])) and parts[str(spec["name"])].state == "severed":
			continue
		var width := Fx.mul_div(body_width, int(spec["w_pct"]), 100)
		var zone := str(spec["name"])
		if parts.has(zone) and catalog.has(parts[zone].regrown_id):
			width = Fx.percent(
				width, int(catalog[parts[zone].regrown_id]["modifiers"].get("hurtbox_percent", 100))
			)
		var height := Fx.mul_div(body_height, int(spec["h_pct"]), 100)
		var local_x := Fx.mul_div(body_width, int(spec["x_pct"]), 100)
		var top := body_y + Fx.mul_div(body_height, int(spec["y_pct"]), 100)
		boxes.append({"name": str(spec["name"]), "rect": [body_x + local_x, top, width, height]})
	return boxes


func hash_values() -> Array:
	var values: Array = [max_integrity, losses]
	for name in LIMB_NAMES:
		values.append(int(integrity.get(name, 0)))
		values.append_array(parts[name].hash_values())
	return values
