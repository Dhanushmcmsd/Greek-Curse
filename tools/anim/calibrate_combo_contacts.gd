extends SceneTree


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	var rig = load("res://src/presentation/fighter_rig.gd").new()
	root.add_child(rig)
	rig.load_fighter("theron")
	var path := "res://data/animation/mixamo_pack_map.json"
	var mapping: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	for action in mapping.fighters.theron.actions:
		var entry: Dictionary = mapping.fighters.theron.actions[action]
		if not entry.has("contact_phases"):
			continue
		var count: int = entry.contact_phases.size()
		var animation: Animation = rig.anim_player.get_animation("theron_" + action)
		rig.anim_player.play("theron_" + action)
		var move: Dictionary = JSON.parse_string(
			FileAccess.get_file_as_string(
				"res://data/moves/" + str(action).trim_prefix("move_") + ".json"
			)
		)
		var tip := "foot." if str(move.limb_side).begins_with("leg") else "hand."
		var contacts: Array = []
		var duration := minf(animation.length, 6.0)
		for hit in count:
			var low := duration * (0.08 + 0.84 * float(hit) / count)
			var high := duration * (0.08 + 0.84 * float(hit + 1) / count)
			var best := -INF
			var time := low
			for frame in 31:
				var sample := lerpf(low, high, float(frame) / 30.0)
				rig.anim_player.seek(sample, true)
				rig.skeleton.force_update_all_bone_transforms()
				for side in ["l", "r"]:
					var bone: int = rig.skeleton.find_bone(tip + side)
					var point: Vector3 = rig.skeleton.get_bone_global_pose(bone).origin
					if point.z > best:
						best = point.z
						time = sample
			contacts.append(time)
		var start := maxf(0, float(contacts[0]) - 0.22)
		var end := minf(animation.length, float(contacts[-1]) + 0.3)
		for fighter in mapping.fighters.values():
			var target: Dictionary = fighter.actions[action]
			target.start_seconds = start
			target.end_seconds = end
			target.contact_phases = []
			for contact in contacts:
				target.contact_phases.append((float(contact) - start) / (end - start))
		print(action, " contacts_seconds=", contacts)
	FileAccess.open(path, FileAccess.WRITE).store_string(
		JSON.stringify(mapping, "  ", false) + "\n"
	)
	quit()
