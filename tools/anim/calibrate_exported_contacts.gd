extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var path := "res://data/animation/mixamo_pack_map.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for id in (["theron", "atalanta", "pyrrhus", "sibyl", "dorian"] if "combos" in OS.get_cmdline_user_args() else (["dorian"] if "johnny" in OS.get_cmdline_user_args() else ["theron", "atalanta", "pyrrhus", "sibyl"])):
		if "theron_boxer" in OS.get_cmdline_user_args() and id != "theron":
			continue
		_calibrate(id, mapping)
	FileAccess.open(path, FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()


func _calibrate(id: String, mapping: Dictionary) -> void:
	var rig = load("res://src/presentation/fighter_rig.gd").new()
	root.add_child(rig)
	rig.load_fighter(id)
	for action in mapping.fighters[id].actions:
		var combos := "combos" in OS.get_cmdline_user_args()
		if combos and action != "move_" + id + "_finisher":
			continue
		if (
			not str(action).begins_with("move_")
			or (not combos and "theron_boxer" not in OS.get_cmdline_user_args() and str(action).begins_with("move_" + id + "_"))
			or not mapping.fighters[id].actions[action].has("export_source")
			or mapping.fighters[id].actions[action].has("contact_phases")
		):
			continue
		var move: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://data/moves/%s.json" % str(action).trim_prefix("move_")
			)
		)
		var is_kick: bool = move.category == "kick" or str(move.get("limb_side", "")).begins_with("leg_")
		if "theron_boxer" in OS.get_cmdline_user_args() and int(move.get("hit_count", 1)) > 1:
			continue
		var tip: String = "foot." if is_kick else "hand."
		var animation: Animation = rig.anim_player.get_animation(id + "_" + action)
		var length := minf(animation.length, 6.0)
		var peak := -INF
		var peak_time := 0.0
		var side := "l"
		rig.anim_player.play(id + "_" + action)
		rig.anim_player.seek(0.0, true)
		rig.skeleton.force_update_all_bone_transforms()
		var initial := {}
		for candidate in ["l", "r"]:
			initial[candidate] = rig.skeleton.get_bone_global_pose(rig.skeleton.find_bone(tip + candidate)).origin
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
				if "theron_boxer" in OS.get_cmdline_user_args():
					score = position.z - initial[candidate].z
				if score > peak:
					peak = score
					peak_time = time
					side = candidate
		var start := maxf(0.0, peak_time - (0.5 if move.category == "heavy" else 0.3))
		var end := minf(animation.length, peak_time + (0.5 if is_kick else 0.35))
		for fighter in [mapping.fighters[id]]:
			fighter.actions[action]["start_seconds"] = start
			fighter.actions[action]["end_seconds"] = end
			fighter.actions[action]["contact_phase"] = (
				(peak_time - start) / maxf(0.001, end - start)
			)
			fighter.actions[action]["strike_side"] = side
		print(action, " ", start, " -> ", peak_time, " -> ", end, " side=", side, " reach=", peak)
	rig.free()
