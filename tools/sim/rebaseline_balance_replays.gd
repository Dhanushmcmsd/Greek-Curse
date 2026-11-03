extends SceneTree
## Explicitly rebaseline existing inputs after an intentional balance change.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for file in DirAccess.get_files_at("res://tests/golden"):
		if file.ends_with(".replay.json"):
			if not refresh("res://tests/golden/" + file):
				quit(1)
				return
	quit()


func refresh(path: String) -> bool:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var fixture = load("res://tests/proto_fixture.gd")
	var checker = load("res://src/presentation/replay_check.gd")
	var launcher = load("res://src/presentation/match_launcher.gd")
	var world = fixture.world_with({}, int(data["seed"]))
	if (
		data.has("arena_id")
		or (data.has("fighters") and data["fighters"] != ["theron", "atalanta"])
	):
		var config = load("res://src/sim/match_config.gd").new()
		config.seed = int(data["seed"])
		config.fighter_ids[0] = str(data["fighters"][0])
		config.fighter_ids[1] = str(data["fighters"][1])
		config.arena_id = str(data.get("arena_id", "mount_olympus"))
		config.rules["hazards"] = bool(data.get("hazards", false))
		config.loadouts = data.get("loadouts", [])
		world = launcher.make_world(config)
	checker.configure(world, str(data.get("scenario", "")))
	world.setup({"initial_limb_states": data.get("initial_limb_states", [])})
	for index in data.get("initial_meters", []).size():
		world.fighters[index].meter = int(data["initial_meters"][index])
	var hashes: Array = []
	var events: Array = []
	for row in data.inputs:
		for event in world.step(row):
			if event.kind >= SimEvent.Kind.LIMB_STATE_CHANGED:
				events.append({"kind": SimEvent.Kind.keys()[event.kind], "payload": event.payload})
		if int(data.hashes_every) > 0 and world.tick % int(data.hashes_every) == 0:
			hashes.append(str(world.snapshot_hash()))
	data.hashes = hashes
	data.final_hash = str(world.snapshot_hash())
	if data.has("wins"):
		data.wins = world.wins
	if data.has("events"):
		data.events = events
	var output: FileAccess = null
	for attempt in 10:
		output = FileAccess.open(path, FileAccess.WRITE)
		if output != null:
			break
		OS.delay_msec(50)
	if output == null:
		push_error(
			"Cannot write replay baseline: " + path + " error=" + str(FileAccess.get_open_error())
		)
		return false
	output.store_string(JSON.stringify(data) + "\n")
	output.close()
	var error: String = checker.verify(path)
	if error != "":
		push_error(path + ": " + error)
		return false
	print("REBASELINE_VERIFIED ", path)
	return true
