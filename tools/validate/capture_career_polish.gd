extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.size = Vector2i(1280, 720)
	var host = load("res://scenes/menus/main.tscn").instantiate()
	root.add_child(host)
	host._show("fighter_create")
	var selector = host.body.find_children("*", "OptionButton", true, false)[0]
	selector.select(4)
	selector.item_selected.emit(4)
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/dorian_career_create.png")
	print("DORIAN_CAREER_MENU_OK")
	host.free()
	quit()
