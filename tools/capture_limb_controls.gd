extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var match_node: Node = load("res://scenes/match/match_prototype.tscn").instantiate()
	root.add_child(match_node)
	match_node.set_physics_process(false)
	var folder := "res://docs/playtest/limb_controls"
	DirAccess.make_dir_recursive_absolute(folder)
	var fighter = match_node.world.fighters[0]
	var view: Node = match_node._views[0]
	fighter.x = -650
	match_node.world.fighters[1].x = 1000
	for side in ["l", "r"]:
		for slot in ["leg_l", "leg_r"]:
			fighter.limbs.parts[slot].state = "healthy"
			fighter.limbs.parts[slot].integrity = fighter.limbs.parts[slot].max_integrity
		var missing := "leg_r" if side == "l" else "leg_l"
		fighter.limbs.parts[missing].state = "severed"
		fighter.limbs.parts[missing].integrity = 0
		fighter.limbs.parts[missing].regrown_id = ""
		view._last_states[missing] = "severed"
		fighter.pose = "hop"
		fighter.clear_move()
		fighter.state = 1
		view.driver.time = 0.2
		match_node._sync(false)
		await save(folder + "/hop_" + side + ".png")
		var move: Dictionary = view.driver.moves.pegasus_kick
		fighter.begin_move(1, move, 10, 10)
		fighter.attack_slot = "leg_" + side
		for stage in ["kick", "fall", "rise"]:
			fighter.state = 3 if stage == "kick" else 4
			fighter.state_tick = fighter.startup_ticks
			if stage != "kick":
				fighter.state_tick += (
					fighter.active_ticks
					+ int(fighter.recovery_ticks * (0.4 if stage == "fall" else 0.85))
				)
			match_node._sync(true)
			await save(folder + "/" + stage + "_" + side + ".png")
	quit()


func save(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)
