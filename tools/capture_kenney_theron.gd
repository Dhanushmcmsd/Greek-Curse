extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/kenney_" + label + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var host = load("res://scenes/menus/main.tscn").instantiate()
	root.add_child(host)
	host._show("main_menu")
	await shot("main_menu")
	host._show("practice_setup")
	await shot("setup")
	host.free()
	await process_frame
	var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
	scene.match_config.fighter_ids.assign(["theron", "dorian"])
	root.add_child(scene)
	scene.set_physics_process(false)
	scene.world.hazards_enabled = false
	var a = scene.world.fighters[0]
	var b = scene.world.fighters[1]
	a.x = -500
	b.x = 900
	scene._sync(false)
	await shot("theron_idle")
	for move in ["lead", "power", "rise", "low", "counter", "breaker", "finisher", "signature"]:
		a.clear_move()
		a.state = SimFighter.State.IDLE
		a.stamina = 100
		SimMovement._begin_named(scene.world, a, "theron_" + move, "arm_r" if move in ["power", "finisher"] else "leg_l" if move in ["low", "rise"] else "arm_l")
		for tick in maxi(1, a.startup_ticks - 1):
			scene.world.step([0, 0])
			scene._sync(false)
			await process_frame
		await shot("theron_" + move)
	scene.free()
	await process_frame
	print("KENNEY_THERON_RENDER_OK")
	quit()
