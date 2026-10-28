extends RefCounted
## Align anatomical segments after rest-relative retargeting (A-pose / T-pose correction).
const CHAINS := {
	"upper_arm.l": ["LeftArm", "LeftForeArm", "forearm.l"],
	"forearm.l": ["LeftForeArm", "LeftHand", "hand.l"],
	"upper_arm.r": ["RightArm", "RightForeArm", "forearm.r"],
	"forearm.r": ["RightForeArm", "RightHand", "hand.r"],
	"thigh.l": ["LeftUpLeg", "LeftLeg", "shin.l"],
	"shin.l": ["LeftLeg", "LeftFoot", "foot.l"],
	"thigh.r": ["RightUpLeg", "RightLeg", "shin.r"],
	"shin.r": ["RightLeg", "RightFoot", "foot.r"]
}


static func correct(
	result: Animation, clip: Animation, source: Skeleton3D, target: Skeleton3D
) -> void:
	var source_basis: Quaternion = FighterRig._asset_basis(source)
	var target_basis: Quaternion = FighterRig._asset_basis(target)
	var rotation_tracks := {}
	for track in result.get_track_count():
		if result.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			var bone := target.find_bone(result.track_get_path(track).get_concatenated_subnames())
			rotation_tracks[bone] = track
	var frames := ceili(result.length * 30)
	for frame in frames + 1:
		var at := minf(float(frame) / 30.0, result.length)
		var source_poses: Array[Transform3D] = []
		for bone in source.get_bone_count():
			var local := source.get_bone_rest(bone)
			local.basis = Basis(clip.rotation_track_interpolate(bone, at))
			var parent := source.get_bone_parent(bone)
			source_poses.append(source_poses[parent] * local if parent >= 0 else local)
		var globals := {}
		for bone in target.get_bone_count():
			var parent := target.get_bone_parent(bone)
			var parent_rotation: Quaternion = (
				globals[parent] if parent >= 0 else Quaternion.IDENTITY
			)
			var rotation: Quaternion = (
				parent_rotation * result.rotation_track_interpolate(rotation_tracks[bone], at)
			)
			var name := target.get_bone_name(bone)
			if CHAINS.has(name):
				var chain: Array = CHAINS[name]
				var src := source.find_bone("mixamorig_" + chain[0])
				var end := source.find_bone("mixamorig_" + chain[1])
				var child := target.find_bone(chain[2])
				var wanted: Vector3 = (
					target_basis.inverse()
					* (source_basis * (source_poses[end].origin - source_poses[src].origin))
				)
				var rest := target.get_bone_global_rest(bone)
				var local_direction := (
					rest.basis.inverse() * (target.get_bone_global_rest(child).origin - rest.origin)
				)
				var actual := rotation * local_direction
				if wanted.length_squared() > 0.000001 and actual.length_squared() > 0.000001:
					rotation = Quaternion(actual.normalized(), wanted.normalized()) * rotation
			globals[bone] = rotation.normalized()
			result.rotation_track_insert_key(
				rotation_tracks[bone], at, parent_rotation.inverse() * rotation
			)
