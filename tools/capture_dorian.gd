extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1280, 720)
	var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
	scene.match_config.fighter_ids.assign(["dorian", "theron"])
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.world.fighters[0].x = -500
	scene.world.fighters[1].x = 500
	var movement = load("res://src/sim/sim_movement.gd")
	for move in ["dorian_front_punch_1", "dorian_front_kick_1", "dorian_shadow_kick", "dorian_nut_punch"
	]:
		var a = scene.world.fighters[0]
		a.clear_move()
		movement._begin_named(
			scene.world,
			a,
			move,
			(
				"leg_l"
				if move.contains("kick")
				else "arm_r"
			)
		)
		a.state = 3
		a.state_tick = a.startup_ticks
		scene._sync(false)
		for frame in 4:
			await process_frame
		if move == "pegasus_kick":
			var effects = get_first_node_in_group("gore_manager")
			effects.impact(scene._views[1].impact_point("torso"), false, false, 2)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/export_" + move + ".png")
	print("EXPORT_RENDER_OK")
	quit()
