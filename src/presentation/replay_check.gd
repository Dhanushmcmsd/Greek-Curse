class_name ReplayCheck
extends RefCounted
## Replays a golden input log and compares the stored hashes.


static func verify(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return "replay is not an object"
	var data: Dictionary = parsed
	var world := ProtoFixture.world_with({}, int(data["seed"]))
	var every := int(data["hashes_every"])
	var inputs: Array = data["inputs"]
	var hashes: Array = data["hashes"]
	var seen := 0
	for row in inputs:
		world.step(row)
		if every > 0 and world.tick % every == 0:
			if seen >= hashes.size() or str(world.snapshot_hash()) != str(hashes[seen]):
				return "hash mismatch at tick %d" % world.tick
			seen += 1
	if str(world.snapshot_hash()) != str(data["final_hash"]):
		return "final hash mismatch"
	if seen != hashes.size():
		return "hash count mismatch"
	return ""
