extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router = root.get_node("Router")
	var settings = root.get_node("Settings")
	router.start()
	if router.state != "main_menu" or router.career.data.get("fighter", {}).is_empty():
		push_error("Saved first-launch flags or Career missing after process restart")
		quit(1)
		return
	router.transition("career_hub")
	var fighter: Dictionary = router.career.data["fighter"]
	if fighter["limbs"]["arm_l"]["regrown_id"] == "" or int(fighter["win_count"]) != 1:
		push_error("Trade or win did not survive restart")
		quit(1)
		return
	router.prepare_career()
	var world = load("res://src/presentation/match_launcher.gd").make_world(router.config)
	if world.fighters[0].limbs.parts["arm_l"].regrown_id != fighter["limbs"]["arm_l"]["regrown_id"]:
		quit(1)
		return
	print("CONTINUE_RELAUNCH_OK profile=", settings.path.get_base_dir())
	quit(0)
