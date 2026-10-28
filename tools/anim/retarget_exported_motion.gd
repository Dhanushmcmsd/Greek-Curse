extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var rig_script = load("res://src/presentation/fighter_rig.gd")
	var mapping: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/animation/mixamo_pack_map.json")
	)
	var shared := {
		"jab_of_hermes": "FrontPunch_1",
		"achilles_heel_snap": "DuckFrontKick_1",
		"hammer_of_hephaestus": "BackPunch_2",
		"spartan_cross": "BackPunch_1",
		"pegasus_kick": "FrontKick_1",
		"thunder_elbow_strike": "FrontPunch_1_2ndBackPunch",
		"phantom_ambush": "FrontPunch_1_3rdBackPunch",
		"divine_uppercut": "DuckBackPunch_1",
		"cyclops_smash": "BackPunch_3",
		"minotaur_haymaker": "BackPunch_2",
		"bronze_knuckle": "BackPunch_1",
		"gorgon_backfist": "BackPunch_3",
		"satyr_dropkick": "BackKick_1",
		"sweeping_hydra": "DuckFrontKick_1",
		"olympian_crusher": "BackKick_3_2ndBackPunch",
		"ghost_sweep_chain": "DuckFrontKick_1",
		"titan_combo_kick": "BackKick_3_3rdFrontKick",
		"muay_thai_flurry": "FrontKick_2_2ndFrontPunch"
	}
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var selected: Dictionary = shared.duplicate()
		if id == "theron":
			selected["jab_of_hermes"] = "FrontPunch_1_2ndBackPunch"
		var styles: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/animation/fighter_styles.json")
		)
		if "styles" in OS.get_cmdline_user_args():
			selected = styles[id].sources
		var rig = rig_script.new()
		root.add_child(rig)
		rig.load_fighter(id)
		DirAccess.make_dir_recursive_absolute("res://assets/animations/exported/" + id)
		for move in selected:
			if (
				not OS.get_cmdline_user_args().is_empty()
				and "styles" not in OS.get_cmdline_user_args()
				and move not in OS.get_cmdline_user_args()
			):
				continue
			var data: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string(
					"res://build/exported_motion/" + selected[move] + ".json"
				)
			)
			var source := Skeleton3D.new()
			source.rotation.x = -PI / 2
			for bone in data.bones:
				source.add_bone("mixamorig_" + str(bone.name))
			for index in data.bones.size():
				var bone: Dictionary = data.bones[index]
				if int(bone.parent) >= 0:
					source.set_bone_parent(index, int(bone.parent))
				var q: Array = bone.q
				var p: Array = bone.p
				source.set_bone_rest(
					index,
					Transform3D(
						Basis(Quaternion(q[0], q[1], q[2], q[3]).normalized().inverse()),
						Vector3(p[0], p[1], p[2]) * 0.01
					)
				)
			var clip := Animation.new()
			clip.length = float(data.frames - 1) / float(data.fps)
			for bone in data.bones.size():
				var track := clip.add_track(Animation.TYPE_ROTATION_3D)
				clip.track_set_path(track, NodePath("Skeleton3D:" + source.get_bone_name(bone)))
				for frame in data.frames:
					var q: Array = data.rotations[frame][bone]
					clip.rotation_track_insert_key(
						track,
						float(frame) / float(data.fps),
						(
							Quaternion(q[0], q[1], q[2], q[3]).normalized()
							if bone == 0
							else Quaternion(q[0], q[1], q[2], q[3]).normalized().inverse()
						)
					)
			var result: Animation = rig_script.retarget_animation(clip, source, rig.skeleton)
			load("res://tools/anim/exported_limb_alignment.gd").correct(
				result, clip, source, rig.skeleton
			)
			rig._bind_animation_to_skeleton(result, selected[move])
			var path: String = "res://assets/animations/exported/" + id + "/" + move + ".res"
			assert(ResourceSaver.save(result, path) == OK)
			print("RETARGET_OK ", id, " ", move, " tracks=", result.get_track_count())
			source.free()
			var action: Dictionary = mapping.fighters[id].actions["move_" + move]
			action["start_seconds"] = 0.0
			action["end_seconds"] = result.length
			action["contact_phase"] = 0.35
			action["export_source"] = selected[move]
			action.erase("contact_phases")
		rig.free()
	FileAccess.open("res://data/animation/mixamo_pack_map.json", FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()
