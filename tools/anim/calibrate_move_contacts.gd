extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var rig = load("res://src/presentation/fighter_rig.gd").new()
	root.add_child(rig)
	rig.load_fighter("theron")
	var path := "res://data/animation/mixamo_pack_map.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for action in mapping.fighters.theron.actions:
		if not str(action).begins_with("move_"):
			continue
		var move: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://data/moves/%s.json" % str(action).trim_prefix("move_")
			)
		)
		var tip: String = "foot." if move.category == "kick" else "hand."
		var animation: Animation = rig.anim_player.get_animation("theron_" + action)
		var length := minf(animation.length, 6.0)
		var peak := -INF
		var peak_time := 0.0
		var side := "l"
		rig.anim_player.play("theron_" + action)
		for frame in int(length * 30) + 1:
			var time := minf(float(frame) / 30.0, length)
			rig.anim_player.seek(time, true)
			rig.skeleton.force_update_all_bone_transforms()
			for candidate in ["l", "r"]:
				if action == "move_spartan_cross" and candidate != "r":
					continue
				var bone: int = rig.skeleton.find_bone(tip + candidate)
				var position: Vector3 = rig.skeleton.get_bone_global_pose(bone).origin
				var score := (
					absf(position.x) * 0.8 + position.z * 0.2
					if action == "move_minotaur_haymaker"
					else position.z
				)
				if score > peak:
					peak = score
					peak_time = time
					side = candidate
		var start := maxf(0.0, peak_time - (0.5 if move.category == "heavy" else 0.3))
		var end := minf(animation.length, peak_time + (0.5 if move.category == "kick" else 0.35))
		for fighter in mapping.fighters.values():
			fighter.actions[action]["start_seconds"] = start
			fighter.actions[action]["end_seconds"] = end
			fighter.actions[action]["contact_phase"] = (
				(peak_time - start) / maxf(0.001, end - start)
			)
			fighter.actions[action]["strike_side"] = side
		print(action, " ", start, " -> ", peak_time, " -> ", end, " side=", side, " reach=", peak)
	FileAccess.open(path, FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()
