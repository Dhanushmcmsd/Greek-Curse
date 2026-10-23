class_name InputRecorder
extends RefCounted

var inputs: Array = []
var hashes: Array = []
var initial: Array = []
var seed: int = 1


func record(world: SimWorld, masks: Array) -> void:
	inputs.append(masks.duplicate())
	if world.tick % 30 == 0:
		hashes.append(str(world.hash_state()))


func payload(world: SimWorld) -> Dictionary:
	return {
		"seed": seed,
		"initial_limb_states": initial,
		"inputs": inputs,
		"hashes": hashes,
		"hashes_every": 30,
		"final_hash": str(world.hash_state())
	}


func save_to(path: String, world: SimWorld) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload(world)))
	return OK
