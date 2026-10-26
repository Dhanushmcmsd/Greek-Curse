extends TestBase


func test_actual_match_integration_and_fighter_visibility() -> void:
	var scene_res := load("res://scenes/match/match_prototype.tscn") as PackedScene
	assert_true(scene_res != null, "match_prototype.tscn loads")
	var match_ctrl := scene_res.instantiate() as MatchController
	assert_true(match_ctrl != null, "match_prototype.tscn instantiates")
	(Engine.get_main_loop() as SceneTree).root.add_child(match_ctrl)

	# 1. Inspect setup
	assert_eq(match_ctrl._views.size(), 2, "match contains exactly 2 fighter views")
	for i in range(2):
		var view: FighterView = match_ctrl._views[i]
		assert_true(view.is_visible_in_tree(), "view %d is visible in tree" % i)
		assert_true(view.rig != null, "view %d has loaded FighterRig" % i)
		assert_true(view.rig.skeleton != null, "view %d has Skeleton3D" % i)
		assert_true(view.rig.model != null, "view %d has model" % i)

		# Check rendered natural meshes and bounds
		for slot in SimLimbs.LIMB_NAMES:
			assert_true(view.rig.groups[slot].visible, "natural limb group %s is visible" % slot)
			for m: MeshInstance3D in view.rig.limb_meshes[slot]:
				assert_true(m.is_visible_in_tree(), "limb mesh %s is visible in tree" % m.name)
				var aabb: AABB = m.get_aabb()
				assert_true(aabb.size.length() > 0.1, "mesh %s has non-collapsed bounds" % m.name)

	# 2. Advance 10 physics frames and verify animated world bounds
	for f in range(10):
		match_ctrl._physics_process(1.0 / 60.0)

	for i in range(2):
		var view: FighterView = match_ctrl._views[i]
		assert_true(view.is_visible_in_tree(), "view %d remains visible after 10 ticks" % i)
		assert_true(view.position.is_finite(), "view %d position is finite" % i)
		assert_true(view.rig.position.is_finite(), "view %d rig position is finite" % i)

	# 3. Exercise replacement selection through actual match path
	var p1_rig: FighterRig = match_ctrl._views[0].rig
	var p2_rig: FighterRig = match_ctrl._views[1].rig

	# Test regrowth on both fighters simultaneously
	assert_true(p1_rig.attach_regrown("arm_l", "rubber_chicken_arm"), "P1 regrows arm_l")
	assert_true(p1_rig.attach_regrown("leg_l", "hermes_sandal_leg"), "P1 regrows leg_l")
	assert_true(p2_rig.attach_regrown("arm_r", "rubber_chicken_arm"), "P2 regrows arm_r")
	assert_true(p2_rig.attach_regrown("leg_r", "hermes_sandal_leg"), "P2 regrows leg_r")

	# Step 5 more frames with replacements attached
	for f in range(5):
		match_ctrl._physics_process(1.0 / 60.0)

	# Verify replacement node existence and valid skins
	for rig in [p1_rig, p2_rig]:
		for slot in rig.replacements.keys():
			var rep: Node = rig.replacements[slot]
			assert_true(rep != null, "replacement node exists for " + slot)
			var limb_meshes := rep.find_children("*", "MeshInstance3D", true, false)
			assert_false(limb_meshes.is_empty(), "replacement meshes found for " + slot)
			for lm in limb_meshes:
				var mi := lm as MeshInstance3D
				assert_true(mi.skin != null, "replacement mesh %s has Skin" % mi.name)
				assert_true(mi.skin.get_bind_count() > 0, "skin has non-zero bind count")

	# 4. Test failed attachment and severance
	p1_rig.show_stump("arm_l", true)
	p1_rig.set_limb_visible("arm_l", false)
	assert_true(p1_rig.stumps["arm_l"].visible, "stump visible after severing")
	assert_false(p1_rig.groups["arm_l"].visible, "natural arm_l hidden when severed")

	# 5. Clean up
	match_ctrl.get_parent().remove_child(match_ctrl)
	match_ctrl.free()
