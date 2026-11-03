extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
	scene.match_config.mode = "career"
	scene.match_config.career_styles = true
	scene.match_config.fighter_ids.assign(["dorian", "theron"])
	scene.match_config.loadouts = [Loadout.starter(), Loadout.starter()]
	root.add_child(scene)
	scene.set_physics_process(false)
	var manager = get_first_node_in_group("gore_manager")
	for tick in 180:
		if tick % 3 == 0:
			for index in 8:
				manager.fighter_tint = manager.palette("dorian")
				manager.impact(Vector3(0, 1.2, 0), tick % 2 == 0, false, 2)
		await process_frame
		if manager.particles.size() > int(manager.config.particle_cap):
			push_error("VFX pool cap exceeded")
			quit(1)
			return
	if scene.world.fighters[0].moveset_aliases.is_empty():
		push_error("Career style missing")
		quit(1)
		return
	print("CAREER_VFX_STRESS_OK 480 impacts, bounded pool, Dorian career style")
	scene.free()
	await process_frame
	quit()
