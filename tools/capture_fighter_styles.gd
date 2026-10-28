extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	root.size = Vector2i(1280, 720)
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
		scene.match_config.fighter_ids.assign([id, "atalanta" if id != "atalanta" else "theron"])
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.world.fighters[0].x = -350
		scene.world.fighters[1].x = 350
		for suffix in ["lead", "power", "rise", "pressure"]:
			var a = scene.world.fighters[0]
			a.clear_move()
			a.stamina = 100
			SimMovement._begin_named(
				scene.world,
				a,
				id + "_" + suffix,
				"leg_l" if suffix == "rise" else ("arm_r" if suffix == "power" else "arm_l")
			)
			a.state = SimFighter.State.ACTIVE
			a.state_tick = a.startup_ticks
			scene._sync(false)
			for frame in 4:
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(
				"res://build/style_" + id + "_" + suffix + ".png"
			)
		scene.free()
	print("STYLE_RENDER_OK")
	quit()
