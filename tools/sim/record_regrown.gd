extends SceneTree


func _initialize() -> void:
	var fixture = load("res://tests/proto_fixture.gd")
	var recorder_script = load("res://src/input/input_recorder.gd")
	var probe = fixture.world_with()
	for id in probe.fighters[0].limbs.catalog:
		var world = fixture.world_with()
		var slot: String = world.fighters[0].limbs.catalog[id]["slot"] + "_l"
		world.fighters[0].limbs.parts[slot].state = "severed"
		world.fighters[0].limbs.regrow(slot, id)
		var recorder = recorder_script.new()
		recorder.initial = world.export_limb_state()
		for tick in 420:
			var mask := SimInput.RIGHT if tick < 100 else (SimInput.HEAVY if tick < 220 else SimInput.KICK)
			var inputs := [mask, SimInput.LEFT if tick < 100 else 0]
			world.step(inputs)
			recorder.record(world, inputs)
		recorder.save_to("res://tests/golden/regrown_%s.replay.json" % id, world)
		print("RECORDED_REGROWN ", id)
	quit()
