extends SceneTree


func _initialize() -> void:
	var fixture = load("res://tests/proto_fixture.gd")
	var recorder_script = load("res://src/input/input_recorder.gd")
	var results: Array = []
	var failed := 0
	for mask in 16:
		var world = fixture.world_with()
		SimBodyState.apply_mask(world.fighters[0], mask)
		var recorder = recorder_script.new()
		recorder.initial = world.export_limb_state()
		var allowed: Array = []
		for input in [16, 32, 64, 18, 34, 72, 80]:
			var chosen := SimMoveAvailability.select(world.fighters[0], input, world.body_rules)
			if not chosen.is_empty():
				allowed.append({"input": input, "move": chosen["id"]})
		var start: int = world.fighters[0].x
		var chosen_input := 0 if allowed.is_empty() else int(allowed[0]["input"])
		for tick in 240:
			var input := SimInput.RIGHT if tick < 130 else chosen_input
			var row := [input, SimInput.LEFT if tick < 80 else 0]
			world.step(row)
			recorder.record(world, row)
		var hit: bool = world.fighters[1].health < 300
		var moved: bool = world.fighters[0].x != start
		if not hit or not moved:
			failed += 1
		results.append({"mask": mask, "allowed": allowed, "moved": moved, "hit": hit})
		recorder.save_to("res://tests/golden/body_%02d.replay.json" % mask, world)
	var file := FileAccess.open("res://build/body_state_matrix.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(results, "  "))
	print("BODY_MATRIX masks=16 failures=%d" % failed)
	quit(0 if failed == 0 else 1)
