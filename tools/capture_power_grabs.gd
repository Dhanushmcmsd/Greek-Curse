extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + name + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	for id in ["theron", "pyrrhus", "atalanta", "sibyl", "dorian"]:
		var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
		scene.match_config.fighter_ids.assign([id, "dorian" if id != "dorian" else "theron"])
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.world.hazards_enabled = false
		var a = scene.world.fighters[0]
		var b = scene.world.fighters[1]
		a.x = -250
		b.x = 250
		a.super_charge = 100
		scene._sync(false)
		await shot("power_ready_" + id)
		var events = scene.world.step([SimInput.SUPER, 0])
		scene._consume(events)
		scene._sync(false)
		await shot("power_cast_" + id)
		for tick in 90:
			scene._consume(scene.world.step([0, 0]))
			scene._sync(false)
		a.x = -230
		b.x = 230
		a.stamina = 100
		for tick in 65:
			scene._consume(scene.world.step([PlayerInput.BITS.grab if tick == 0 else 0, 0]))
			scene._sync(false)
			if tick in [14, 30, 50]:
				await shot("grab_" + id + "_" + str(tick))
		a.stamina = 100
		a.x = -280
		b.x = 280
		SimMovement._begin_named(scene.world, a, id + "_counter", "arm_l")
		for tick in 25:
			scene._consume(scene.world.step([0, 0]))
			scene._sync(false)
		await shot("counter_" + id)
		scene.free()
		await process_frame
	print("POWER_GRAB_RENDER_OK")
	quit()
