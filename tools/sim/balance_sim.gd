extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var launcher = load("res://src/presentation/match_launcher.gd")
	var roster := ["theron", "atalanta", "pyrrhus", "sibyl"]
	var report := {
		"matches": 0,
		"failures": 0,
		"ticks": 0,
		"severs": 0,
		"timeouts": 0,
		"wins": {},
		"usage": {},
		"rounds": 0,
		"appearances": {},
		"ability_wins": {}
	}
	var catalog: Dictionary = launcher.make_world(MatchConfig.new()).abilities
	for index in 192:
		var config := MatchConfig.new()
		config.seed = index + 71
		config.fighter_ids = [roster[(index / 48) % 4], roster[(index / 12) % 4]]
		config.arena_id = ["mount_olympus", "athens_colosseum", "tartarus_pits"][(index / 4) % 3]
		config.rules["hazards"] = index % 2 == 0
		var slots := _sample_loadout(catalog, 800 + (index / 2) % 2)
		config.loadouts = [slots.duplicate(true), slots.duplicate(true)]
		var world = launcher.make_world(config)
		var ai := [launcher.make_ai("normal", index + 20), launcher.make_ai("normal", index + 30)]
		while world.phase == 0 and world.tick < 40000:
			var events: Array = world.step(
				[
					ai[0].decide(AIObservation.capture(world, 0)),
					ai[1].decide(AIObservation.capture(world, 1))
				]
			)
			for event in events:
				if event.kind == SimEvent.Kind.ROUND_END and world.round_tick >= world.round_ticks:
					report["timeouts"] += 1
		report["matches"] += 1
		report["rounds"] += world.wins[0] + world.wins[1]
		for id in config.fighter_ids:
			report["appearances"][id] = int(report["appearances"].get(id, 0)) + 1
		report["failures"] += int(world.phase != 1)
		report["ticks"] += world.tick
		report["severs"] += world.amputations.size()
		var winner: String = config.fighter_ids[0 if world.wins[0] > world.wins[1] else 1]
		report["wins"][winner] = int(report["wins"].get(winner, 0)) + 1
		for values in slots.values():
			for id in values:
				report["ability_wins"][id] = int(report["ability_wins"].get(id, 0)) + 1
		for fighter in world.fighters:
			for id in fighter.ability_uses:
				report["usage"][id] = (
					int(report["usage"].get(id, 0)) + int(fighter.ability_uses[id])
				)
		if index % 12 == 11:
			print("BALANCE_PROGRESS ", index + 1)
	DirAccess.make_dir_recursive_absolute("res://docs/balance")
	var file := FileAccess.open("res://docs/balance/report_2026-10-24.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("BALANCE ", JSON.stringify(report))
	quit(int(report["failures"] > 0))


func _sample_loadout(catalog: Dictionary, seed: int) -> Dictionary:
	var rng := SimRng.new(seed)
	var slots := {}
	for kind in Loadout.COUNTS:
		var pool: Array = catalog.keys().filter(func(id): return catalog[id]["type"] == kind)
		pool.sort()
		slots[kind] = []
		for count in Loadout.COUNTS[kind]:
			var index := rng.range_i(0, pool.size())
			slots[kind].append(pool[index])
			pool.remove_at(index)
	return slots
