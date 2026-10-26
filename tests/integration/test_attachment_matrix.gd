extends TestBase


func test_selected_fighter_visual_data_matches_sim() -> void:
	var controller := MatchController.new()
	controller.match_config.fighter_ids = ["pyrrhus", "sibyl"]
	controller._load_match()
	var world := controller._make_world()
	assert_eq(controller._fighter_rows[0]["id"], "pyrrhus", "selected visual model")
	assert_eq(
		int(controller._fighter_rows[0]["height_mm"]), world.fighters[0].height_mm, "same size"
	)
	controller.free()


func test_all_forty_attachments() -> void:
	var count := 0
	var world := ProtoFixture.world_with()
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		rig.load_fighter(id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		for limb in world.fighters[0].limbs.catalog.values():
			for side in ["l", "r"]:
				var slot: String = limb["slot"] + "_" + side
				assert_true(rig.attach_regrown(slot, limb["id"]), "attaches")
				var replacement: Node3D = rig.replacements[slot]
				assert_true(replacement.global_transform.origin.is_finite(), "finite transform")
				assert_true(replacement.position.length() < 0.001, "socket origin exact")
				for mesh in replacement.find_children("*", "MeshInstance3D", true, false):
					var box: AABB = mesh.global_transform * mesh.get_aabb()
					assert_true(box.position.y >= -0.015, "not below floor " + id + limb["id"])
				rig.detach_regrown(slot)
				assert_false(rig.groups[slot].visible, "detach keeps natural limb hidden")
				rig.sync(world.fighters[0])
				assert_true(rig.groups[slot].visible, "healthy simulation restores natural limb")
				count += 1
		rig.free()
	assert_eq(count, 40, "all compatible combinations")
