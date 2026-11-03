extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var fighter := "theron"
	var dummy := "idle"
	var args := OS.get_cmdline_user_args()
	for i in args.size() - 1:
		if args[i] == "--fighter":
			fighter = args[i + 1]
		if args[i] == "--dummy":
			dummy = args[i + 1]
	if fighter not in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"] or dummy not in ["idle", "block_always", "attack_on_interval"]:
		push_error("Invalid playtest fighter or dummy mode")
		quit(1)
		return
	var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
	scene.match_config.mode = "practice"
	scene.match_config.fighter_ids.assign([fighter, "theron" if fighter != "theron" else "dorian"])
	scene.match_config.controllers.assign(["human_kb1", "dummy_" + dummy])
	root.add_child(scene)
	scene.world.hazards_enabled = false
	print("PLAYTEST_READY ", fighter, " dummy=", dummy, " | F2 combos | R restart | Esc pause")
