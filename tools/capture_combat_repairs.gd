extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
		scene.match_config.fighter_ids.assign([id, "theron" if id != "theron" else "dorian"])
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.world.hazards_enabled = false
		var a = scene.world.fighters[0]
		var b = scene.world.fighters[1]
		a.x = -280
		b.x = 280
		SimMovement._begin_named(scene.world, a, id + "_signature", "arm_r")
		var saved := false
		for tick in 80:
			var events = scene.world.step([0, 0])
			scene._consume(events)
			scene._sync(false)
			if not saved and b.state == SimFighter.State.HITSTUN and scene._views[1].driver._reaction_age >= 5:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://build/combat2_" + id + "_hit.png")
				saved = true
		scene._match_tools.open_combos()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/combat2_" + id + "_menu.png")
		scene.free()
	print("COMBAT_REPAIRS_RENDER_OK")
	quit()
