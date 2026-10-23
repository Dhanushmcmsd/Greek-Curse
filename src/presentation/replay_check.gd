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
	if data.has("fighters") and data["fighters"] != ["theron", "atalanta"]:
		var config := MatchConfig.new()
		config.seed = int(data["seed"])
		config.fighter_ids = [str(data["fighters"][0]), str(data["fighters"][1])]
		world = MatchLauncher.make_world(config)
	configure(world, str(data.get("scenario", "")))
	world.setup({"initial_limb_states": data.get("initial_limb_states", [])})
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


static func configure(world: SimWorld, scenario: String) -> void:
	if scenario == "severance":
		world.fighters[0].x = 0
		world.fighters[1].x = 430
		world.moves[0]["damage"] = 0
		world.moves[0]["limb_damage"] = 25
		world.moves[0]["hitbox"] = {"x": 0, "y": 1424, "w": 500, "h": 150}
