extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var path := "res://data/animation/mixamo_pack_map.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for id in mapping.fighters:
		for move in ["spartan_flurry", "phantom_flurry", "lightning_jab_chain"]:
			var sequence := ["jab_of_hermes", "thunder_elbow_strike", "phantom_ambush"]
			if move == "lightning_jab_chain":
				sequence.insert(1, "jab_of_hermes")
			var result := Animation.new()
			var cursor := 0.0
			var contacts: Array = []
			for part in sequence:
				var clip := (
					load("res://assets/animations/exported/" + id + "/" + part + ".res")
					as Animation
				)
				var settings: Dictionary = mapping.fighters[id].actions["move_" + part]
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
			for contact in contacts:
				action.contact_phases.append(float(contact) / cursor)
			action.export_source = "FrontPunch_1 > FrontPunch_1_2ndBackPunch > FrontPunch_1_3rdBackPunch"
			action.strike_side = "l"
			print("CHAIN_OK ", id, " ", move, " contacts=", contacts.size())
	FileAccess.open(path, FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()
