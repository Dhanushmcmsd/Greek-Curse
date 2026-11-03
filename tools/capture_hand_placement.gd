extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1500, 500)
	var row := HBoxContainer.new()
	root.add_child(row)
	var previews: Array = []
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var column := VBoxContainer.new()
		row.add_child(column)
		var title := Label.new()
		title.text = id
		column.add_child(title)
		var preview = load("res://src/ui/model_preview.gd").new()
		column.add_child(preview)
		preview.setup(id)
		preview.custom_minimum_size = Vector2(285, 440)
		previews.append(preview)
	for action in ["idle", "walk_fwd", "walk_back", "block"]:
		for preview in previews:
			preview.fighter.state = SimFighter.State.WALK if action.begins_with("walk") else SimFighter.State.IDLE
			preview.fighter.blocking = action == "block"
			preview.view.driver.walk_direction = -1 if action == "walk_back" else 1
		for frame in 20:
			await process_frame
		await RenderingServer.frame_post_draw
		for preview in previews:
			preview.texture.get_image().save_png("res://build/hands_" + preview.fighter.fighter_id + "_" + action + ".png")
		root.get_texture().get_image().save_png("res://build/hands_" + action + ".png")
	row.free()
	print("HAND_PREVIEWS_OK")
	quit()
