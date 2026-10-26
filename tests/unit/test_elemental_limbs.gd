extends TestBase

const MODEL_IDS: Array[String] = [
	"atalanta",
	"theron",
	"pyrrhus",
	"sibyl",
	"skin_ch39",
	"skin_ch40",
	"skin_demon",
	"skin_kachujin",
	"skin_nightshade",
	"vampire_stress",
]


func test_elemental_limbs_manifest_and_assets_exist() -> void:
	var manifest_path := "res://assets/limbs_elemental/limbs_manifest.json"
	assert_true(ResourceLoader.exists(manifest_path), "limbs_manifest.json exists")
	var manifest: Dictionary = DataLoader.new().load_json(manifest_path).value
	assert_eq(manifest.size(), 40, "40 elemental limb GLBs registered in manifest")

	for mid in MODEL_IDS:
		for limb_type in ["arm", "leg"]:
			for side in ["r", "l"]:
				var key := "elemental_%s_%s_%s" % [mid, limb_type, side]
				assert_true(manifest.has(key), "Manifest contains entry: " + key)
				var glb_path := "res://assets/limbs_elemental/%s.glb" % key
				assert_true(ResourceLoader.exists(glb_path), "GLB asset exists: " + glb_path)


func test_elemental_limbs_shared_skeleton_binding_on_atalanta_and_theron() -> void:
	# Test both Arissa/Atalanta and Paladin/Theron
	for fid in ["atalanta", "theron"]:
		var rig := FighterRig.new()
		assert_true(rig.load_fighter(fid), "load_fighter succeeds for " + fid)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)

		# Attach elemental arm and leg (left and right)
		for slot in SimLimbs.LIMB_NAMES:
			var limb_id := "rubber_chicken_arm" if slot.begins_with("arm") else "hermes_sandal_leg"
			var success := rig.attach_regrown(slot, limb_id)
			assert_true(success, "attach_regrown succeeds on slot %s for %s" % [slot, fid])
			assert_true(rig.replacements.has(slot), "replacement tracked for " + slot)

			var rep: Node = rig.replacements[slot]
			assert_true(rep != null, "replacement node exists for " + slot)
			assert_true(rep.get_meta("is_elemental", false), "is marked as elemental")
			var meshes: Array[MeshInstance3D] = []
			if rep is MeshInstance3D:
				meshes.append(rep as MeshInstance3D)
			else:
				for ch in rep.get_children():
					if ch is MeshInstance3D:
						meshes.append(ch as MeshInstance3D)
			assert_false(meshes.is_empty(), "contains MeshInstance3D for " + slot)
			for limb_mesh in meshes:
				assert_true(limb_mesh.skin != null, "has valid Skin for " + slot)
				assert_true(limb_mesh.skin.get_bind_count() > 0, "skin has binds for " + slot)

			# Verify natural mesh is hidden
			for nat_mesh: MeshInstance3D in rig.limb_meshes[slot]:
				assert_false(nat_mesh.visible, "natural mesh hidden on " + slot)
			assert_false(rig.stumps[slot].visible, "stump hidden on " + slot)

			# Detach and verify restoration
			rig.detach_regrown(slot)
			assert_false(rig.replacements.has(slot), "cleared replacement on " + slot)
			for nat_mesh: MeshInstance3D in rig.limb_meshes[slot]:
				assert_false(nat_mesh.visible, "detaching does not restore natural mesh on " + slot)

		rig.get_parent().remove_child(rig)
		rig.free()


func test_elemental_limbs_follow_skeleton_animation() -> void:
	var rig := FighterRig.new()
	assert_true(rig.load_fighter("atalanta"), "load_fighter succeeds for atalanta")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)

	# Attach right arm and right leg elemental replacements
	rig.attach_regrown("arm_r", "rubber_chicken_arm")
	rig.attach_regrown("leg_r", "hermes_sandal_leg")

	var arm_bone_idx := rig.skeleton.find_bone("upper_arm.r")
	var leg_bone_idx := rig.skeleton.find_bone("thigh.r")
	assert_true(arm_bone_idx >= 0, "upper_arm.r exists")
	assert_true(leg_bone_idx >= 0, "thigh.r exists")

	# Play actions and verify bone poses evaluate cleanly
	var test_acts: Array[String] = ["idle", "walk_fwd", "walk_back", "punch_jab", "kick_thrust"]
	for act in test_acts:
		var full_act: String = "atalanta_" + act
		if rig.anim_player.has_animation(full_act):
			rig.anim_player.play(full_act)
			var anim: Animation = rig.anim_player.get_animation(full_act)
			for step in 4:
				var t := (float(step) / 3.0) * anim.length
				rig.anim_player.seek(t, true)
				var arm_pose: Vector3 = rig.skeleton.get_bone_global_pose(arm_bone_idx).origin
				var leg_pose: Vector3 = rig.skeleton.get_bone_global_pose(leg_bone_idx).origin
				assert_true(arm_pose.is_finite(), "arm pose is finite in %s at %.2f" % [act, t])
				assert_true(leg_pose.is_finite(), "leg pose is finite in %s at %.2f" % [act, t])

	rig.detach_regrown("arm_r")
	rig.detach_regrown("leg_r")
	rig.get_parent().remove_child(rig)
	rig.free()
