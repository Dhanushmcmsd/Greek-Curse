extends TestBase


func test_four_models_have_working_limbs_and_stumps() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		assert_true(rig.load_fighter(id), "loads " + id)
		for slot in SimLimbs.LIMB_NAMES:
			rig.set_limb_visible(slot, false)
			rig.show_stump(slot, true)
			assert_true(not rig.groups[slot].visible, id + " hidden " + slot)
			assert_true(rig.stumps[slot].visible, id + " stump " + slot)
			assert_eq(rig.limb_meshes[slot].size(), 3, "three rendered parts")
			for mesh in rig.limb_meshes[slot]:
				assert_true(not mesh.visible, "imported skinned geometry hidden")
			for mesh in rig.stump_meshes[slot]:
				assert_true(mesh.visible, "imported stump geometry shown")
			rig.set_limb_visible(slot, true)
			rig.show_stump(slot, false)
		rig.free()


func test_three_arenas_load() -> void:
	for id in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
		var scene := load("res://assets/generated/models/arena_%s.glb" % id) as PackedScene
		assert_true(scene != null, "arena loads " + id)
