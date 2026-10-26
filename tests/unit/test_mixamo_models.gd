extends TestBase


func test_mixamo_atalanta_and_vampire_limbs_stumps_and_regrown() -> void:
	for model_info in [
		{
			"path": "res://assets/fighters_mixamo/fighter_atalanta.glb",
			"id": "atalanta",
			"height": 1.78,
			"width": 0.39
		},
		{
			"path": "res://assets/fighters_mixamo/fighter_vampire_stress.glb",
			"id": "vampire_stress",
			"height": 2.05,
			"width": 0.50
		}
	]:
		var scene: PackedScene = load(model_info["path"])
		assert_true(scene != null, "loads " + model_info["id"])
		var rig := FighterRig.new()
		rig.model = scene.instantiate()
		rig.add_child(rig.model)
		rig.fighter_height = model_info["height"]
		rig.fighter_width = model_info["width"]
		rig.skeleton = rig.model.find_child("Skeleton3D", true, false) as Skeleton3D
		assert_true(rig.skeleton != null, "skeleton found " + model_info["id"])
		var is_rich_deform: bool = rig.skeleton.get_bone_count() > 15
		if is_rich_deform:
			assert_true(
				rig.skeleton.get_bone_count() >= 15,
				"rich deform rig has >= 15 bones: " + model_info["id"]
			)
			for req_bone in FighterRig.REQUIRED_BONES:
				assert_true(
					rig.skeleton.find_bone(req_bone) >= 0,
					(
						"required mapped bone '%s' exists on skeleton for %s"
						% [req_bone, model_info["id"]]
					)
				)
		else:
			assert_eq(rig.skeleton.get_bone_count(), 15, "15 shared bones " + model_info["id"])

		for slot in SimLimbs.LIMB_NAMES:
			var suffix := slot.to_upper()
			rig.groups[slot] = rig.model.find_child("LIMB_" + suffix, true, false)
			rig.stumps[slot] = rig.model.find_child("STUMP_" + suffix, true, false)
			rig.sockets[slot] = rig.model.find_child("SOCKET_" + suffix, true, false)
			assert_true(rig.groups[slot] != null, "group " + slot)
			assert_true(rig.stumps[slot] != null, "stump " + slot)
			assert_true(rig.sockets[slot] != null, "socket " + slot)

			rig.limb_meshes[slot] = []
			rig.stump_meshes[slot] = []
			var type: String = suffix.substr(0, 3)
			var side: String = suffix.right(1)
			for part in ["UPPER", "LOWER", "END"]:
				var mesh: Node = rig.model.find_child(type + "_" + part + "_" + side, true, false)
				if mesh != null:
					rig.limb_meshes[slot].append(mesh)
			if rig.limb_meshes[slot].is_empty():
				var target_tag := "LIMB_" + suffix
				var target_suffix := "_" + suffix
				for child in rig.model.find_children("*", "MeshInstance3D", true, false):
					if (
						child.has_meta("limb_group")
						and str(child.get_meta("limb_group")) == target_tag
					):
						rig.limb_meshes[slot].append(child)
					elif str(child.name).ends_with(target_suffix):
						rig.limb_meshes[slot].append(child)
			for part in ["CUT_", "BONE_"]:
				var mesh: Node = rig.model.find_child(part + type + side, true, false)
				if mesh != null:
					rig.stump_meshes[slot].append(mesh)

			assert_true(rig.limb_meshes[slot].size() >= 1, "at least one limb mesh for " + slot)
			assert_eq(rig.stump_meshes[slot].size(), 2, "two stump meshes for " + slot)

			rig.stump_meshes[slot].append(LimbFinish.wound(rig.skeleton, slot))
			# Prove hiding limb hides actual rendered meshes
			rig.set_limb_visible(slot, false)
			rig.show_stump(slot, true)
			assert_false(rig.groups[slot].visible, "group hidden " + slot)
			assert_true(rig.stumps[slot].visible, "stump shown " + slot)
			for mesh: MeshInstance3D in rig.limb_meshes[slot]:
				assert_false(mesh.visible, "rendered mesh hidden " + mesh.name)
			for mesh: MeshInstance3D in rig.stump_meshes[slot]:
				assert_eq(
					mesh.visible,
					str(mesh.name).begins_with("WOUND_"),
					"only wound shown " + mesh.name
				)

			# Restore
			rig.set_limb_visible(slot, true)
			rig.show_stump(slot, false)

		# 40-case attachment matrix test: 5 regrown limb types across compatible sockets
		# 3 arm types x 2 arm sockets = 6 cases; 2 leg types x 2 leg sockets = 4 cases.
		# 10 cases per model x 2 models = 20 valid attachments + 20 cross-slot rejections = 40 checks.
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var regrown_limbs := [
			{"id": "rubber_chicken_arm", "slot_type": "arm"},
			{"id": "crab_claw_arm", "slot_type": "arm"},
			{"id": "cyclops_giant_hand", "slot_type": "arm"},
			{"id": "hermes_sandal_leg", "slot_type": "leg"},
			{"id": "marble_statue_leg", "slot_type": "leg"}
		]
		for limb_data in regrown_limbs:
			var limb_id: String = limb_data["id"]
			var valid_slot_prefix: String = limb_data["slot_type"]
			for slot in SimLimbs.LIMB_NAMES:
				var is_compatible: bool = slot.begins_with(valid_slot_prefix)
				var success: bool = rig.attach_regrown(slot, limb_id)
				if is_compatible:
					assert_true(
						success,
						(
							"attaching "
							+ limb_id
							+ " to compatible slot "
							+ slot
							+ " on "
							+ model_info["id"]
						)
					)
					assert_true(rig.replacements.has(slot), "replacement tracked in slot " + slot)
					for mesh: MeshInstance3D in rig.limb_meshes[slot]:
						assert_false(
							mesh.visible, "natural mesh hidden when attached: " + mesh.name
						)
					assert_false(rig.stumps[slot].visible, "stump hidden when attached: " + slot)
					rig.detach_regrown(slot)
					assert_false(
						rig.replacements.has(slot), "replacement cleared after detach: " + slot
					)
					for mesh: MeshInstance3D in rig.limb_meshes[slot]:
						assert_false(
							mesh.visible, "natural mesh stays hidden after detach: " + mesh.name
						)
				else:
					assert_false(
						success,
						"reject incompatible " + limb_id + " on " + slot + " on " + model_info["id"]
					)
					assert_false(
						rig.replacements.has(slot),
						"incompatible slot should have no replacement: " + slot
					)

		rig.get_parent().remove_child(rig)
		rig.free()
