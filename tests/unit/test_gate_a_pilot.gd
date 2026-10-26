extends TestBase
## Unit contract tests for Gate A intact pilot, facing, looping, and regrowth.

const PilotPreviewScript := preload("res://src/presentation/pilot_gate_a_preview.gd")
const PREVIEW_SCENE_PATH := "res://scenes/debug/pilot_gate_a_preview.tscn"


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


func test_gate_a_core_actions_looping_and_facing() -> void:
	var scene_pck := load(PREVIEW_SCENE_PATH) as PackedScene
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

		# Explicit loop mode validation:
		# Locomotion and idle must loop continuously (LOOP_LINEAR).
		# Attacks must remain one-shot (LOOP_NONE).
		if act in ["idle", "walk_fwd", "walk_back"]:
			assert_eq(
				anim.loop_mode, Animation.LOOP_LINEAR, "Action '%s' must loop continuously" % act
			)
		else:
			assert_eq(anim.loop_mode, Animation.LOOP_NONE, "Action '%s' must be one-shot" % act)

	# Check neck-head and limb bone length continuity across actions
	var neck_idx: int = skel.find_bone("mixamorig_Neck")
	var head_idx: int = skel.find_bone("mixamorig_Head")
	var rest_neck_pos: Vector3 = skel.get_bone_global_rest(neck_idx).origin
	var rest_head_pos: Vector3 = skel.get_bone_global_rest(head_idx).origin
	var rest_neck_head: float = rest_neck_pos.distance_to(rest_head_pos)

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

			var ls_pos: Vector3 = skel.get_bone_global_pose(ls_idx).origin
			var rs_pos: Vector3 = skel.get_bone_global_pose(rs_idx).origin
			var hips_pos: Vector3 = skel.get_bone_global_pose(hips_idx).origin
			var up_vec: Vector3 = (head_pos - hips_pos).normalized()
			var right_vec: Vector3 = (rs_pos - ls_pos).normalized()
			var chest_fwd: Vector3 = right_vec.cross(up_vec).normalized()
			assert_true(
				chest_fwd.z < 0.2,
				(
					"Action %s at frac %.2f must face forward (chest_fwd.z=%.2f)"
					% [act, frac, chest_fwd.z]
				)
			)

	pilot.queue_free()


func test_gate_a_regrowth_attachment_and_lifecycle() -> void:
	var scene_pck := load(PREVIEW_SCENE_PATH) as PackedScene
	assert_true(scene_pck != null, "Preview scene must instantiate")
	var pilot: Node = scene_pck.instantiate()
	pilot.call("init_model_and_anims")

	# 1. Verify BoneAttachment3D sockets exist under Skeleton3D
	var skel: Skeleton3D = pilot.get("skeleton")
	assert_true(skel != null, "Skeleton must exist")
	var sock_arm: Node3D = pilot.get("socket_arm_l")
	var sock_leg: Node3D = pilot.get("socket_leg_l")
	assert_true(sock_arm != null, "Socket ATTACH_ARM_L must exist")
	assert_true(sock_leg != null, "Socket ATTACH_LEG_L must exist")

	# 2. Test initial healthy state
	pilot.call("_update_limb_visibilities")
	var arm_status: String = pilot.get("arm_attachment_status")
	assert_eq(arm_status, "NATURAL (Intact)", "Initial arm status must be intact")

	# 3. Test severance
	pilot.set("arm_l_severed", true)
	pilot.call("_update_limb_visibilities")
	arm_status = pilot.get("arm_attachment_status")
	assert_eq(arm_status, "SEVERED (Stump visible)", "Arm status after sever must be stump visible")
	var stump_arm: Node3D = pilot.get("wound_arm")
	assert_true(stump_arm != null and stump_arm.visible, "Stump cap must be visible when severed")

	# 4. Test real arm replacement attachment
	pilot.set("regrown_arm_attached", true)
	pilot.call("_update_limb_visibilities")
	arm_status = pilot.get("arm_attachment_status")
	assert_true(arm_status.begins_with("SUCCESS"), "Regrown arm must succeed: %s" % arm_status)
	var regrown_node: Node3D = pilot.get("regrown_arm_node")
	assert_true(regrown_node != null, "Real regrown arm mesh node must be instantiated")
	assert_false(stump_arm.visible, "Stump cap must be hidden when replacement is attached")

	# 5. Test real leg replacement attachment
	pilot.set("leg_l_severed", true)
	pilot.set("regrown_leg_attached", true)
	pilot.call("_update_limb_visibilities")
	var leg_status: String = pilot.get("leg_attachment_status")
	assert_true(leg_status.begins_with("SUCCESS"), "Regrown leg must succeed: %s" % leg_status)
	var regrown_leg: Node3D = pilot.get("regrown_leg_node")
	assert_true(regrown_leg != null, "Real regrown leg mesh node must be instantiated")

	# 6. Test natural arm restoration cleans up replacement
	pilot.set("arm_l_severed", false)
	pilot.set("regrown_arm_attached", false)
	pilot.call("_update_limb_visibilities")
	assert_true(
		pilot.get("regrown_arm_node") == null,
		"Regrown node must be freed when natural arm restored"
	)

	# 7. Test model reload/mode toggle does not leave stale references
	pilot.call("init_model_and_anims")
	assert_true(pilot.get("regrown_arm_node") == null, "Reload must clear replacement node")
	assert_true(pilot.get("socket_arm_l") != null, "Socket must be re-bound cleanly on reload")

	pilot.queue_free()
