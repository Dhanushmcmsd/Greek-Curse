extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	root.size = Vector2i(1280, 720)
	var match_node = load("res://scenes/match/match_prototype.tscn").instantiate()
	root.add_child(match_node)
	match_node.set_physics_process(false)
	match_node.world.fighters[0].x = -300
	match_node.world.fighters[1].x = 300
	var fighter: SimFighter = match_node.world.fighters[0]
	SimMovement._begin_named(match_node.world, fighter, "muay_thai_flurry", "leg_r")
	fighter.state = SimFighter.State.ACTIVE
	fighter.state_tick = 24
	match_node._sync(false)
	for frame in 8:
		await process_frame
	await shot("res://build/continuation_knee.png")
	var effects = get_first_node_in_group("gore_manager")
	effects.impact(Vector3(0.15, 1.1, 0.2), false, false, 2)
	await create_timer(0.045).timeout
	await shot("res://build/refine_impact.png")
	var defender: SimFighter = match_node.world.fighters[1]
	defender.state = SimFighter.State.HITSTUN
	defender.state_tick = 28
	match_node._views[1].notify_hit("torso", false, 4, "thunder_elbow_strike")
	for frame in 10:
		match_node._sync(false)
		await process_frame
	await shot("res://build/continuation_reaction.png")
	match_node.world.round_index = 2
	defender.health = 50
	var sever_events: Array = []
	SimSeverance.award_round_end(match_node.world, 0, sever_events)
	match_node._consume(sever_events)
	match_node._sync(false)
	for frame in 8:
		await process_frame
	await shot("res://build/continuation_sever.png")
	await create_timer(0.9).timeout
	await shot("res://build/polish_detached_limb.png")
	match_node._match_tools.open_combos()
	for frame in 4:
		await process_frame
	await shot("res://build/continuation_combos.png")
	print("CONTINUATION_RENDER_OK")
	quit()


func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
