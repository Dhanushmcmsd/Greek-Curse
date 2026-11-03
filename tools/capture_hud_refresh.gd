extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func shot(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/hud_refresh_" + name + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.title = "Olympus - HUD input verification"
	var host = load("res://scenes/menus/main.tscn").instantiate()
	root.add_child(host)
	var router = root.get_node("Router")
	router.config.fighter_ids.assign(["pyrrhus", "theron"])
	router.config.controllers.assign(["human_kb1", "dummy_idle"])
	router.config.loadouts = [load("res://src/progression/loadout.gd").starter(), load("res://src/progression/loadout.gd").starter()]
	host._show("match")
	var scene = host.battle
	scene.set_physics_process(false)
	scene.world.hazards_enabled = false
	var a = scene.world.fighters[0]
	var b = scene.world.fighters[1]
	a.x = -800
	b.x = 800
	a.meter = 100
	a.super_charge = 100
	b.health = scene.world.max_health
	scene._sync(false)
	await shot("ready")
	if "--native-input" not in OS.get_cmdline_user_args():
		var press := InputEventKey.new()
		press.physical_keycode = KEY_I
		press.pressed = true
		scene._input(press)
	print("WAIT_INPUT_I")
	var inputs = scene._read_inputs()
	while not inputs[0] & SimInput.ULTIMATE:
		await process_frame
		inputs = scene._read_inputs()
	print("NORMAL_MENU_INPUT ", inputs)
	scene._consume(scene.world.step(inputs))
	assert(a.move_name == "zeus_wrath")
	var struck := false
	for tick in 90:
		scene._consume(scene.world.step(scene._read_inputs()))
		scene._sync(false)
		await process_frame
		if b.state == SimFighter.State.HITSTUN and not struck:
			struck = true
			await shot("ultimate")
	assert(struck)
	a.stamina = 100
	if "--native-input" not in OS.get_cmdline_user_args():
		var press := InputEventKey.new()
		press.physical_keycode = KEY_J
		press.pressed = true
		scene._input(press)
	print("WAIT_INPUT_J")
	inputs = scene._read_inputs()
	while not inputs[0] & SimInput.LIGHT:
		await process_frame
		inputs = scene._read_inputs()
	scene._consume(scene.world.step(inputs))
	print("NORMAL_MENU_ATTACK ", a.move_name)
	assert(a.move_name == "pyrrhus_lead")
	host.free()
	await process_frame
	print("HUD_MENU_INPUT_RENDER_OK")
	quit()
