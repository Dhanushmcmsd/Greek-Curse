extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var match_node: Node = load("res://scenes/match/match_prototype.tscn").instantiate()
	root.add_child(match_node)
	match_node.set_physics_process(false)
	var folder := "res://docs/playtest/combat_depth"
	DirAccess.make_dir_recursive_absolute(folder)
	match_node.world.fighters[0].x = -650
	match_node.world.fighters[1].x = 650
	match_node._sync(true)
	var fighter = match_node.world.fighters[0]
	for slot in ["leg_l", "leg_r"]:
		match_node._views[0]._last_states[slot] = "severed"
		fighter.limbs.parts[slot].state = "severed"
		fighter.limbs.parts[slot].integrity = 0
	fighter.pose = "crawl"
	fighter.state = 1
	match_node._sync(true)
	var view: Node = match_node._views[0]
	view.rig.anim_player.seek(0.5, true)
	view.driver.update(fighter)
	for frame in 3:
		await process_frame
	await save(folder + "/crawl.png")
	for slot in ["leg_l", "leg_r"]:
		fighter.limbs.parts[slot].state = "cracked"
	view.driver.update(fighter)
	for frame in 3:
		await process_frame
	await save(folder + "/fractured_legs.png")
	for slot in ["leg_l", "leg_r"]:
		fighter.limbs.parts[slot].state = "healthy"
		fighter.limbs.parts[slot].integrity = fighter.limbs.parts[slot].max_integrity
	fighter.pose = "standing"
	for index in 2:
		fighter = match_node.world.fighters[index]
		view = match_node._views[index]
		for action in view.driver.pack_map.fighters[fighter.fighter_id].actions:
			if not str(action).begins_with("move_"):
				continue
			var id := str(action).trim_prefix("move_")
			var move: Dictionary = view.driver.moves[id]
			fighter.begin_move(1, move, 10, 10)
			fighter.attack_slot = move.limb_side
			fighter.state = 3
			fighter.state_tick = fighter.startup_ticks
			view.driver.update(fighter)
			for frame in 2:
				await process_frame
			await save(folder + "/%s_%s.png" % [fighter.fighter_id, id])
		fighter.clear_move()
		fighter.state = 0
		view.driver.update(fighter)
	match_node._restart()
	match_node.set_physics_process(false)
	match_node.world.fighters[0].x = -260
	match_node.world.fighters[1].x = 260
	match_node._sync(true)
	for frame in 3:
		await process_frame
	await save(folder + "/spacing_before.png")
	var hit := false
	for tick in 60:
		var events: Array = match_node.world.step([32, 0])
		match_node._consume(events)
		match_node._sync(false)
		for event in events:
			if event.kind == 0:
				hit = true
		await process_frame
		if hit:
			break
	print("SPACING_CONTACT ", hit)
	await save(folder + "/spacing_contact.png")
	for tick in 18:
		match_node._consume(match_node.world.step([0, 128]))
		match_node._sync(false)
		await process_frame
	await save(folder + "/spacing_after.png")
	for tick in 35:
		match_node._consume(match_node.world.step([0, 128]))
		match_node._sync(false)
		await process_frame
	await save(folder + "/spacing_recovered.png")
	print("SEPARATION_MM ", match_node.world.fighters[1].x - match_node.world.fighters[0].x)
	quit()


func save(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("CAPTURE ", path)
