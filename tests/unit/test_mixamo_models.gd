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
			for part in ["CUT_", "BONE_"]:
				var mesh: Node = rig.model.find_child(part + type + side, true, false)
				if mesh != null:
					rig.stump_meshes[slot].append(mesh)

			assert_eq(rig.limb_meshes[slot].size(), 3, "three limb meshes for " + slot)
			assert_eq(rig.stump_meshes[slot].size(), 2, "two stump meshes for " + slot)

			# Prove hiding limb hides actual rendered meshes
			rig.set_limb_visible(slot, false)
			rig.show_stump(slot, true)
			assert_false(rig.groups[slot].visible, "group hidden " + slot)
			assert_true(rig.stumps[slot].visible, "stump shown " + slot)
			for mesh: MeshInstance3D in rig.limb_meshes[slot]:
				assert_false(mesh.visible, "rendered mesh hidden " + mesh.name)
			for mesh: MeshInstance3D in rig.stump_meshes[slot]:
				assert_true(mesh.visible, "stump mesh shown " + mesh.name)

			# Restore
			rig.set_limb_visible(slot, true)
			rig.show_stump(slot, false)

		# Test regrown limb attachment
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var attached: bool = rig.attach_regrown("arm_l", "rubber_chicken_arm")
		assert_true(attached, "rubber chicken arm attaches to " + model_info["id"])
		assert_true(rig.replacements.has("arm_l"), "replacement exists")
		for mesh: MeshInstance3D in rig.limb_meshes["arm_l"]:
			assert_false(mesh.visible, "natural limb hidden with replacement " + mesh.name)
		assert_false(rig.stumps["arm_l"].visible, "stump hidden with replacement")

		rig.detach_regrown("arm_l")
		assert_false(rig.replacements.has("arm_l"), "replacement detached")
		for mesh: MeshInstance3D in rig.limb_meshes["arm_l"]:
			assert_true(mesh.visible, "natural limb restored " + mesh.name)

		rig.free()
