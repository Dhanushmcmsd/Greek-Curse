extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for id in ["theron", "pyrrhus", "atalanta", "sibyl", "dorian"]:
		var config = load("res://src/sim/match_config.gd").new()
		config.fighter_ids.assign([id, "dorian"])
		var world = load("res://src/presentation/match_launcher.gd").make_world(config)
		var rig = load("res://src/presentation/fighter_rig.gd").new()
		root.add_child(rig)
		rig.load_fighter(id)
		var driver = load("res://src/presentation/pose_driver.gd").new()
		driver.setup(rig)
		var samples: Array[float] = []
		var ground_samples: Array[float] = []
		for tick in 160:
			var fighter = world.fighters[0]
			if tick % 50 == 0:
				fighter.clear_move()
				fighter.state = SimFighter.State.IDLE
				SimMovement._begin_named(world, fighter, id + "_counter", "arm_l")
			world.step([0, 0])
			var start := Time.get_ticks_usec()
			driver.update(fighter)
			var end := Time.get_ticks_usec()
			driver._ground(fighter, driver.data.settings)
			if tick >= 10:
				samples.append(float(end - start) / 1000.0)
				ground_samples.append(float(Time.get_ticks_usec() - end) / 1000.0)
		samples.sort()
		ground_samples.sort()
		print("POSE_BENCH ", id, " median_ms=", samples[75], " p95_ms=", samples[142], " ground_median_ms=", ground_samples[75])
		rig.free()
		await process_frame
	quit()

