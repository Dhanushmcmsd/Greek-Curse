extends TestBase


func test_four_models_have_working_limbs_and_stumps() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		assert_true(rig.load_fighter(id), "loads " + id)
		assert_true(rig.skeleton != null, "shared skeleton imported")
		if rig.skeleton.get_bone_count() > 15:
			assert_true(rig.skeleton.get_bone_count() >= 15, "rich deform skeleton >= 15 bones")
			for req_bone in FighterRig.REQUIRED_BONES:
				assert_true(
					rig.skeleton.find_bone(req_bone) >= 0, "required bone exists: " + req_bone
				)
		else:
			assert_eq(rig.skeleton.get_bone_count(), 15, "same skeleton bone count")
		var bone := rig.skeleton.find_bone("thigh.l")
		var rotation := rig.skeleton.get_bone_pose_rotation(bone)
		rig.pose_limb("leg_l", 0.0)
		assert_eq(
			rig.skeleton.get_bone_pose_rotation(bone),
			rotation,
			"zero motion preserves imported pose"
		)
		for slot in SimLimbs.LIMB_NAMES:
			rig.set_limb_visible(slot, false)
			rig.show_stump(slot, true)
			assert_true(not rig.groups[slot].visible, id + " hidden " + slot)
			assert_true(rig.stumps[slot].visible, id + " stump " + slot)
			assert_true(rig.limb_meshes[slot].size() >= 1, "rendered limb parts present")
			for mesh in rig.limb_meshes[slot]:
				assert_true(not mesh.visible, "imported skinned geometry hidden")
			for mesh in rig.stump_meshes[slot]:
				assert_eq(
					mesh.visible,
					str(mesh.name).begins_with("WOUND_"),
					"only recessed wound is shown"
				)
			rig.set_limb_visible(slot, true)
			rig.show_stump(slot, false)
		rig.free()


func test_three_arenas_load() -> void:
	for id in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
		var scene := load("res://assets/generated/models/arena_%s.glb" % id) as PackedScene
		assert_true(scene != null, "arena loads " + id)


func test_pipeline_fixture_has_socket_and_color_materials() -> void:
	var model := ModelLoader.load_model("res://assets/generated/models/pipeline_test.glb")
	assert_true(model.nodes.has("SOCKET_TEST"), "pipeline socket")
	var mesh: MeshInstance3D = model.nodes["BOX"]
	assert_true(
		mesh.get_surface_override_material(0).vertex_color_use_as_albedo, "vertex color enabled"
	)
	model.root.free()
