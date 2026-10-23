extends SceneTree
## Full matches. Alternates sides, cycles all roster pairs, records failure inputs.


func _initialize() -> void:
	var launcher = load("res://src/presentation/match_launcher.gd")
	var recorder_script = load("res://src/input/input_recorder.gd")
	var count := 300
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--matches="):
			count = int(arg.substr(10))
	var summary := {"matches": count, "failures": 0, "ticks": 0, "severs": 0,
		"hard_over_normal": 0, "normal_over_easy": 0, "comparisons": [0, 0], "body_masks": {}}
	for n in count:
		var config := MatchConfig.new()
		var roster := ["theron", "atalanta", "pyrrhus", "sibyl"]
		config.fighter_ids = [roster[(n / 4) % 4], roster[n % 4]]
		config.seed = n + 1
		var category := n % 2
		var stronger := "hard" if category == 0 else "normal"
		var weaker := "normal" if category == 0 else "easy"
		var strong_side := (n / 2) % 2
		var ai := [launcher.make_ai(stronger if strong_side == 0 else weaker, n * 2 + 10),
			launcher.make_ai(stronger if strong_side == 1 else weaker, n * 2 + 11)]
		var world = launcher.make_world(config)
		var recorder = recorder_script.new()
		recorder.seed = config.seed
		recorder.fighter_ids = config.fighter_ids.duplicate()
		var stagnant := 0
		var prior: Array = []
		var issue := ""
		while world.phase == 0 and world.tick < 40000:
			var masks := [ai[0].decide(AIObservation.capture(world, 0)), ai[1].decide(AIObservation.capture(world, 1))]
			world.step(masks)
			recorder.record(world, masks)
			var progress := [world.fighters[0].x, world.fighters[1].x, world.fighters[0].health, world.fighters[1].health]
			stagnant = stagnant + 1 if progress == prior else 0
			prior = progress
			for fighter in world.fighters:
				var mask: int = SimBodyState.derive(fighter.limbs)["mask"]
				summary["body_masks"][str(mask)] = true
				if fighter.health < 0 or fighter.limbs.losses > 2:
					issue = "invariant"
			if stagnant > 600:
				issue = "stagnant"
			if issue != "":
				break
		if world.phase != 1 or issue != "":
			summary["failures"] += 1
			DirAccess.make_dir_recursive_absolute("res://build/soak_failures")
			recorder.save_to("res://build/soak_failures/%d.json" % n, world)
			print("SOAK_FAIL ", n, " ", issue)
		else:
			var key := "hard_over_normal" if category == 0 else "normal_over_easy"
			summary["comparisons"][category] += 1
			if world.wins[strong_side] >= 2:
				summary[key] += 1
		summary["ticks"] += world.tick
		summary["severs"] += world.amputations.size()
		if n % 25 == 24:
			print("SOAK_PROGRESS ", n + 1, "/", count)
	var file := FileAccess.open("res://build/soak_summary.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(summary, "  "))
	print("SOAK_SUMMARY ", JSON.stringify(summary))
	quit(0 if summary["failures"] == 0 else 1)
