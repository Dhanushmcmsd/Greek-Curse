extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var launcher = load("res://src/presentation/match_launcher.gd")
	for id in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
		var config := MatchConfig.new()
		config.arena_id = id
		var a = launcher.make_world(config)
		var b = launcher.make_world(config)
		for world in [a, b]:
			world.fighters[0].x = -3500
		for tick in 1200:
			a.step([0, 0])
			b.step([0, 0])
		if a.hash_state() != b.hash_state():
			quit(1)
			return
		print("HAZARD_REPLAY ", id, " hash=", a.hash_state(), " hp=", a.fighters[0].health)
	quit(0)
