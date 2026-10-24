extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings := root.get_node("Settings")
	settings.set_value("age_gate_accepted", true, false)
	settings.set_value("content_warning_seen", true, false)
	if "--large-text" in OS.get_cmdline_user_args():
		settings.set_value("ui_scale_percent", 200, false)
	var router := root.get_node("Router")
	var scene = load("res://scenes/menus/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	if router.career.data.get("fighter", {}).is_empty():
		router.career.create("theron", "Preview Hero", "default", "2026-10-24")
	router.career.data["fighter"]["unlocked_abilities"].append("zeus_bolt")
	router.career.data["fighter"]["offers_state"] = ["zeus_bolt"]
	router.career.data["fighter"]["limbs"]["arm_l"]["state"] = "severed"
	router.career.data["fighter"]["limbs"]["arm_l"]["integrity"] = 0
	router.result = {
		"won": true, "rounds": [2, 1], "damage": [600, 430], "combo": 7, "amputations": []
	}
	router.error_message = "Preview: missing-data errors are shown here."
	for state in [
		"age_gate",
		"content_warning",
		"main_menu",
		"fresh_body_setup",
		"versus_setup",
		"practice_setup",
		"loadout",
		"match_banner",
		"settings",
		"controls",
		"credits",
		"career_hub",
		"fighter_create",
		"offer",
		"obol",
		"chronicle",
		"retire",
		"results",
		"error"
	]:
		if state == "practice_setup":
			router.config.mode = "practice"
		print("PREVIEW ", state)
		router.state = state
		scene._show(state)
		for frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(
			(
				"res://build/menu_%s%s.png"
				% [state, "_large" if "--large-text" in OS.get_cmdline_user_args() else ""]
			)
		)
	print("MENU_PREVIEWS_OK")
	root.get_node("Audio").shutdown()
	quit(0)
