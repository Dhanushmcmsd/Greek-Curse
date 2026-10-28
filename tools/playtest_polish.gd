extends SceneTree


func _initialize() -> void:
	call_deferred("run_match")


func run_match() -> void:
	root.size = Vector2i(1280, 720)
	Engine.max_fps = 60
	var scene = load("res://scenes/match/match_prototype.tscn").instantiate()
	scene.match_config.controllers.assign(["ai_normal", "ai_normal"])
	scene.match_config.rules = {"round_ticks": 600, "max_health": 180, "hazards": false}
	root.add_child(scene)
	var started := Time.get_ticks_msec()
	var awarded_at := -1
	var frames := 0
	while Time.get_ticks_msec() - started < 45000:
		await process_frame
		frames += 1
		if scene.world.amputations.size() > 1:
			push_error("multiple sever awards")
			quit(1)
			return
		if scene.world.match_sever_awarded and awarded_at < 0:
			awarded_at = Time.get_ticks_msec()
		if awarded_at >= 0 and Time.get_ticks_msec() - awarded_at > 1000:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/polish_live_match.png")
			var gore := get_first_node_in_group("gore_manager")
			print(
				"LIVE_MATCH_OK awards=",
				scene.world.amputations.size(),
				" round=",
				scene.world.round_index,
				" debris=",
				gore.chunks.size(),
				" rendered_frames=",
				frames
			)
			quit(0)
			return
	push_error("second-round award not reached during timed match")
	quit(1)
