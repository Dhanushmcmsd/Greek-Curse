extends RefCounted

static func apply(animation: Animation, skeleton: Skeleton3D, action: String) -> void:
	if action.begins_with("hit_") or action.begins_with("reaction_") or action.begins_with("sever_") or action in ["knockdown", "lose", "crawl", "torso_scuttle", "torso_roll", "get_up", "grabbed"]:
		return
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var bone_name := str(animation.track_get_path(track).get_concatenated_subnames())
		var bone := skeleton.find_bone(bone_name)
		var lower := bone_name.to_lower()
		if bone < 0 or not (lower == "root" or lower.contains("spine") or lower.contains("chest")):
			continue
		var rest := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion()
		var limit := deg_to_rad(10.0 if lower == "root" else 18.0)
		for key in animation.track_get_key_count(track):
			var rotation: Quaternion = animation.track_get_key_value(track, key)
			var angle := rest.angle_to(rotation)
			if angle > limit:
				animation.track_set_key_value(track, key, rest.slerp(rotation, limit / angle))
