extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/cinematic_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var timings: Array[float] = []
	var frame_times: Array[float] = []
	for id in ["theron", "pyrrhus", "atalanta", "sibyl", "dorian"]:
		var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
		scene.match_config.fighter_ids.assign([id, id])
		root.add_child(scene)
		scene.set_physics_process(false)
		scene.world.hazards_enabled = false
		var a = scene.world.fighters[0]
		var b = scene.world.fighters[1]
		a.x = -1200
		b.x = 1000
		b.health = 1000
		a.meter = 100
		SimMovement._begin_named(scene.world, a, "zeus_wrath", "arm_l")
		var captured := false
		for tick in 140:
			var start := Time.get_ticks_usec()
			scene._consume(scene.world.step([0, 0]))
			scene._sync(false)
			if tick > 5:
				timings.append(float(Time.get_ticks_usec() - start) / 1000.0)
			await process_frame
			if tick > 5:
				frame_times.append(float(Time.get_ticks_usec() - start) / 1000.0)
			if b.state == SimFighter.State.HITSTUN and not captured:
				await shot(id + "_thunder")
				print("THUNDER_HIT ", id, " stun_ticks=", b.state_tick)
				captured = true
		assert(captured, "ultimate must connect")
		for slot in ["arm_l", "leg_l", "leg_r"]:
			b.limbs.parts[slot].state = "severed"
			b.state = SimFighter.State.HITSTUN
			b.state_tick = 40
			for tick in 22:
				scene._consume(scene.world.step([0, 0]))
				scene._sync(false)
				await process_frame
			await shot(id + "_" + slot)
			print("SEVER_CLIP ", id, " ", slot, " ", scene._views[1].driver.current_action_name)
		scene.free()
		await process_frame
	timings.sort()
	frame_times.sort()
	print("MATCH_CPU_MS median=", timings[timings.size() / 2], " p95=", timings[int(timings.size() * 0.95)])
	print("RENDER_FRAME_MS median=", frame_times[frame_times.size() / 2], " p95=", frame_times[int(frame_times.size() * 0.95)])
	print("CINEMATIC_RENDER_OK")
	quit()
