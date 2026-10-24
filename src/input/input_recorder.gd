class_name InputRecorder
extends RefCounted

var inputs: Array = []
var hashes: Array = []
var initial: Array = []
var initial_meters: Array = []
var seed: int = 1
var fighter_ids: Array = ["theron", "atalanta"]


func record(world: SimWorld, masks: Array) -> void:
	inputs.append(masks.duplicate())
	if world.tick % 30 == 0:
		hashes.append(str(world.hash_state()))


func payload(world: SimWorld) -> Dictionary:
	var result := {
		"fighters": fighter_ids,
		"seed": seed,
		"initial_limb_states": initial,
		"initial_meters": initial_meters,
		"inputs": inputs,
		"hashes": hashes,
		"hashes_every": 30,
		"final_hash": str(world.hash_state())
	}
	if not world.arena_rules.is_empty():
		result["arena_id"] = world.arena_rules["id"]
		result["hazards"] = world.hazards_enabled
		result["loadouts"] = [world.fighters[0].loadout, world.fighters[1].loadout]
	return result


func save_to(path: String, world: SimWorld) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload(world)))
	return OK
