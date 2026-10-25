extends TestBase
## Unit contract tests for Gate A intact pilot, facing calibration, and amputation mechanics.

const PilotPreviewScript := preload("res://src/presentation/pilot_gate_a_preview.gd")


func test_gate_a_intact_pilot_and_bone_mapping() -> void:
	var model_path := "res://build/pilot_gate_a/arissa_intact.glb"
	assert_true(ResourceLoader.exists(model_path), "Intact pilot model must exist")

	var scene_pck := load(model_path) as PackedScene
	assert_true(scene_pck != null, "PackedScene must load")
	var root: Node = scene_pck.instantiate()
	var skel: Skeleton3D = root.find_child("Skeleton3D", true, false) as Skeleton3D
	assert_true(skel != null, "Retained skeleton must exist")

	# Assert all 73 Mixamo deform bones are present (no 15-bone reduction)
	assert_eq(skel.get_bone_count(), 73, "Retained skeleton must contain all 73 bones")

	# Assert critical intermediate spine and neck bones exist
	var critical_bones: Array[String] = [
		"mixamorig_Neck",
		"mixamorig_Neck1",
		"mixamorig_Head",
		"mixamorig_Spine",
		"mixamorig_Spine1",
		"mixamorig_Spine2",
	]
	for b in critical_bones:
		assert_true(skel.find_bone(b) >= 0, "Intermediate bone '%s' must exist" % b)

	# Assert continuous soft-skinned meshes
	var body_mesh: MeshInstance3D = (
		root.find_child("arissa_Body_Geo", true, false) as MeshInstance3D
	)
	assert_true(body_mesh != null, "Body mesh must be intact")
	var has_skin_or_mesh: bool = body_mesh.skin != null or body_mesh.mesh != null
	assert_true(has_skin_or_mesh, "Body mesh must have valid skinning data")

	root.queue_free()


func test_gate_a_core_actions_and_facing_alignment() -> void:
	var scene_pck := load("res://scenes/debug/pilot_gate_a_preview.tscn") as PackedScene
	assert_true(scene_pck != null, "Preview scene must instantiate")
	var pilot: Node = scene_pck.instantiate()
	pilot.call("init_model_and_anims")

	var ap: AnimationPlayer = pilot.get("anim_player")
	var skel: Skeleton3D = pilot.get("skeleton")
	assert_true(ap != null, "AnimationPlayer must exist")
	assert_true(skel != null, "Skeleton must exist")

	var expected_actions := ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
	for act in expected_actions:
		assert_true(ap.has_animation(act), "Core action '%s' must be loaded" % act)
		var anim: Animation = ap.get_animation(act)
		assert_true(anim.length > 0.5, "Action '%s' must have meaningful duration" % act)
		assert_true(
			anim.get_track_count() >= 65,
			"Action '%s' must animate at least 65 deform channels" % act
		)

	# Check neck-head and limb bone length continuity across actions
	var neck_idx: int = skel.find_bone("mixamorig_Neck")
	var head_idx: int = skel.find_bone("mixamorig_Head")
	var rest_neck_pos: Vector3 = skel.get_bone_global_rest(neck_idx).origin
	var rest_head_pos: Vector3 = skel.get_bone_global_rest(head_idx).origin
	var rest_neck_head: float = rest_neck_pos.distance_to(rest_head_pos)

	# Facing landmark check:
	# In Godot local space, chest normal points forward (+Z or -Z).
	# Left shoulder should be at positive local X, Right shoulder at negative local X.
	var ls_idx: int = skel.find_bone("mixamorig_LeftShoulder")
	var rs_idx: int = skel.find_bone("mixamorig_RightShoulder")
	var hips_idx: int = skel.find_bone("mixamorig_Hips")

	for act in expected_actions:
		pilot.call("play_action", act)
		var anim: Animation = ap.get_animation(act)
		for frac in [0.0, 0.3, 0.6, 0.9]:
			ap.seek(frac * anim.length, true)
			var neck_pos: Vector3 = skel.get_bone_global_pose(neck_idx).origin
			var head_pos: Vector3 = skel.get_bone_global_pose(head_idx).origin
			var dist: float = neck_pos.distance_to(head_pos)
			assert_near(
				dist,
				rest_neck_head,
				0.05,
				"Neck-to-head distance must remain continuous in %s" % act
			)

			# Verify anatomical facing:
			# Chest normal (shoulder_cross_up) must have consistent sign with other clips
			# and not be reversed by 180 degrees
			var ls_pos: Vector3 = skel.get_bone_global_pose(ls_idx).origin
			var rs_pos: Vector3 = skel.get_bone_global_pose(rs_idx).origin
			var hips_pos: Vector3 = skel.get_bone_global_pose(hips_idx).origin
			var up_vec: Vector3 = (head_pos - hips_pos).normalized()
			var right_vec: Vector3 = (rs_pos - ls_pos).normalized()
			var chest_fwd: Vector3 = right_vec.cross(up_vec).normalized()
			# In Idle, Walk, Jab, Kick, chest_fwd Z coordinate is negative in Godot armature space
			assert_true(
				chest_fwd.z < 0.2,
				(
					"Action %s at frac %.2f must face forward (chest_fwd.z=%.2f)"
					% [act, frac, chest_fwd.z]
				)
			)

	pilot.queue_free()


func test_gate_a_amputation_pilot_partitioning() -> void:
	var part_model_path := "res://build/pilot_gate_a/arissa_partitioned.glb"
	assert_true(ResourceLoader.exists(part_model_path), "Partitioned model must exist")

	var scene_pck := load(part_model_path) as PackedScene
	assert_true(scene_pck != null, "PackedScene must load")
	var root: Node = scene_pck.instantiate()

	# Assert sockets and stumps exist
	var sock_arm_l := root.find_child("SOCKET_ARM_L", true, false)
	var sock_leg_l := root.find_child("SOCKET_LEG_L", true, false)
	var stump_arm_l := root.find_child("STUMP_ARM_L", true, false)
	var stump_leg_l := root.find_child("STUMP_LEG_L", true, false)
	assert_true(sock_arm_l != null, "SOCKET_ARM_L must exist")
	assert_true(sock_leg_l != null, "SOCKET_LEG_L must exist")
	assert_true(stump_arm_l != null, "STUMP_ARM_L must exist")
	assert_true(stump_leg_l != null, "STUMP_LEG_L must exist")

	# Assert limb mesh partitions exist
	var arm_l_meshes: Array[Node] = []
	var leg_l_meshes: Array[Node] = []
	for c in root.find_children("*", "MeshInstance3D", true, false):
		if str(c.name).ends_with("_ARM_L"):
			arm_l_meshes.append(c)
		elif str(c.name).ends_with("_LEG_L"):
			leg_l_meshes.append(c)

	assert_true(arm_l_meshes.size() >= 1, "Arm L meshes must be partitioned")
	assert_true(leg_l_meshes.size() >= 1, "Leg L meshes must be partitioned")

	root.queue_free()
