extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var launcher = load("res://src/presentation/match_launcher.gd")
	var catalog: Dictionary = launcher.make_world(MatchConfig.new()).abilities
	for id in catalog:
		var row: Dictionary = catalog[id]
		var config := MatchConfig.new()
		config.rules["hazards"] = false
		var slots := Loadout.starter()
		slots[row["type"]] = [id]
		config.loadouts = [slots, Loadout.starter()]
		var world = launcher.make_world(config)
		var recorder := InputRecorder.new()
		world.fighters[0].meter = 100
		recorder.initial_meters = [100,0]
		var bit: int = {
			"light": 16, "heavy": 32, "kick": 64, "superpower": 512, "ultimate": 1024, "passive": 16
		}[row["type"]]
		for tick in 480:
			var inputs := [SimInput.RIGHT if tick < 40 else bit, SimInput.LEFT if tick < 40 else 0]
			world.step(inputs)
			recorder.record(world, inputs)
		recorder.save_to("res://tests/golden/ability_%s.replay.json" % id, world)
	print("ABILITY_REPLAYS 21")
	quit(0)
