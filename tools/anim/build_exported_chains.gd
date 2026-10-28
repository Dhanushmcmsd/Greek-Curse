extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var path := "res://data/animation/mixamo_pack_map.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var shared := {
		"quick_fury": ["jab_of_hermes", "thunder_elbow_strike", "phantom_ambush"],
		"spartan_flurry": ["jab_of_hermes", "thunder_elbow_strike", "phantom_ambush"],
		"phantom_flurry": ["jab_of_hermes", "spartan_cross", "phantom_ambush"],
		"lightning_jab_chain":
		["jab_of_hermes", "jab_of_hermes", "thunder_elbow_strike", "phantom_ambush"],
		"muay_thai_flurry":
		["pegasus_kick", "thunder_elbow_strike", "satyr_dropkick", "phantom_ambush"],
		"titan_combo_kick": ["satyr_dropkick", "pegasus_kick", "titan_combo_kick"],
		"ghost_sweep_chain": ["ghost_sweep_chain", "pegasus_kick"],
		"sweeping_hydra": ["sweeping_hydra", "satyr_dropkick", "pegasus_kick"],
		"hoplite_sweep_chain": ["ghost_sweep_chain", "spartan_cross", "pegasus_kick"],
		"olympian_heel_chain": ["pegasus_kick", "satyr_dropkick"]
	}
	for id in mapping.fighters:
		var sequences: Dictionary = shared.duplicate()
		if "styles" in OS.get_cmdline_user_args():
			var styles: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string("res://data/animation/fighter_styles.json")
			)
			sequences = styles[id].chains
		var originals := {}
		var original_settings: Dictionary = mapping.fighters[id].actions.duplicate(true)
		for sequence in sequences.values():
			for part in sequence:
				originals[part] = load(
					"res://assets/animations/exported/" + id + "/" + part + ".res"
				)
		for move in sequences:
			if (
				not OS.get_cmdline_user_args().is_empty()
				and "styles" not in OS.get_cmdline_user_args()
				and move not in OS.get_cmdline_user_args()
			):
				continue
			var sequence: Array = sequences[move]
			var result := Animation.new()
			var cursor := 0.0
			var contacts: Array = []
			for part in sequence:
				var clip: Animation = originals[part]
				var settings: Dictionary = original_settings["move_" + part]
				var start := float(settings.start_seconds)
				var end := float(settings.end_seconds)
				var contact := lerpf(start, end, float(settings.contact_phase))
				start = maxf(start, contact - 0.16)
				end = minf(end, contact + 0.16)
				contacts.append(cursor + contact - start)
				if result.get_track_count() == 0:
					for track in clip.get_track_count():
						result.add_track(clip.track_get_type(track))
						result.track_set_path(track, clip.track_get_path(track))
				for track in clip.get_track_count():
					for frame in ceili((end - start) * 60) + 1:
						var age := minf(float(frame) / 60, end - start)
						if clip.track_get_type(track) == Animation.TYPE_ROTATION_3D:
							var q := clip.rotation_track_interpolate(track, start + age)
							if cursor > 0 and age < 0.06:
								q = result.rotation_track_interpolate(track, cursor - 0.001).slerp(
									q, age / 0.06
								)
							result.rotation_track_insert_key(track, cursor + age, q)
						elif clip.track_get_type(track) == Animation.TYPE_POSITION_3D:
							result.position_track_insert_key(
								track,
								cursor + age,
								clip.position_track_interpolate(track, start + age)
							)
				cursor += end - start
			result.length = cursor
			assert(
				(
					ResourceSaver.save(
						result, "res://assets/animations/exported/" + id + "/" + move + ".res"
					)
					== OK
				)
			)
			var action: Dictionary = mapping.fighters[id].actions["move_" + move]
			action.start_seconds = 0.0
			action.end_seconds = cursor
			action.contact_phases = []
			action.contact_slots = []
			for part in sequence:
				var move_row: Dictionary = JSON.parse_string(
					FileAccess.get_file_as_string("res://data/moves/" + part + ".json")
				)
				action.contact_slots.append(
					(
						("leg_" if move_row.category == "kick" else "arm_")
						+ str(original_settings["move_" + part].get("strike_side", "l"))
					)
				)
			for contact in contacts:
				action.contact_phases.append(float(contact) / cursor)
			action.export_source = " > ".join(sequence)
			action.strike_side = "l"
			print("CHAIN_OK ", id, " ", move, " contacts=", contacts.size())
	FileAccess.open(path, FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()
