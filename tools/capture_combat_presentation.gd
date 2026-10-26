extends SceneTree


func _initialize() -> void:
	call_deferred("capture")


func capture() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	var match_scene := load("res://scenes/match/match_prototype.tscn") as PackedScene
	var match_node := match_scene.instantiate()
	root.add_child(match_node)
	match_node.set_physics_process(false)
	match_node.world.fighters[0].x = -480
	match_node.world.fighters[1].x = 480
	match_node._sync(true)
	for frame in 8:
		await process_frame
	var folder := "res://docs/playtest/combat_presentation"
	DirAccess.make_dir_recursive_absolute(folder)
	match_node._match_tools.open()
	for frame in 8:
		await process_frame
	await shot(folder + "/forge.png")
	match_node._match_tools.close_panel()
	match_node._sync(true)
	var attacker: Node3D = match_node._views[0]
	var defender: Node3D = match_node._views[1]
	attacker.rig.anim_player.play("theron_punch_jab")
	attacker.rig.anim_player.seek(0.35, true)
	var event := SimEvent.make(SimEvent.Kind.HIT, 0, 1, 28, 1, -1)
	event.payload = {"zone": "head", "material": "flesh"}
	print("CONTACT ", defender.impact_point(str(event.payload.zone)))
	match_node._consume([event])
	for frame in 1:
		match_node._camera.track(match_node.world)
		await process_frame
	await shot(folder + "/hit.png")
	await create_timer(0.8).timeout
	defender.rig.anim_player.play("atalanta_block")
	defender.rig.anim_player.seek(0.2, true)
	event.kind = SimEvent.Kind.BLOCK
	event.payload.zone = "arm_l"
	print("CONTACT ", defender.impact_point(str(event.payload.zone)))
	match_node._consume([event])
	for frame in 1:
		match_node._camera.track(match_node.world)
		await process_frame
	await shot(folder + "/block.png")
	await create_timer(0.8).timeout
	match_node.world.fighters[1].limbs.parts["arm_l"].state = "severed"
	match_node._sync(true)
	match_node._camera.impact(0.13, true)
	for frame in 1:
		match_node._camera.track(match_node.world)
		await process_frame
	await shot(folder + "/sever.png")
	await create_timer(0.8).timeout
	var gore := get_first_node_in_group("gore_manager")
	gore.ooze(defender.rig.sockets["arm_l"].global_position)
	for frame in 8:
		await process_frame
	await shot(folder + "/wound.png")
	quit()


func shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
	print("CAPTURED ", path)
