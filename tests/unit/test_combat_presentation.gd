extends TestBase


func test_effect_pools_and_accessibility() -> void:
	var saved := SettingsHooks.values.duplicate(true)
	SettingsHooks.values["gore"] = "off"
	SettingsHooks.values["flash_reduction"] = true
	var manager := GoreManager.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(manager)
	for index in 30:
		manager.burst(Vector3(1, 1, 0), index % 2 == 0, true)
		manager.ooze(Vector3.UP)
	assert_eq(manager.chunks.size(), 0, "no placeholder chunks or gore when disabled")
	assert_eq(manager.floor_splats.size(), 0, "no blood stains when disabled")
	assert_true(
		manager.particles.size() <= int(manager.config["particle_cap"]), "bounded effect pool"
	)
	for node in manager.particles:
		assert_true(
			node.global_position.distance_to(Vector3(1, 1, 0)) < 0.2, "effects originate at contact"
		)
		if node is CPUParticles3D and node.mesh is QuadMesh:
			assert_eq(node.amount, 12, "reduced flash uses fewer sparks")
		assert_false(node is RigidBody3D, "no chunky placeholder geometry")
		node.set_meta("expires", 0)
	manager._process(0.016)
	assert_eq(manager.particles.size(), 0, "expired particles are released")
	manager.free()
	SettingsHooks.values = saved


func test_recessed_wounds_for_all_models() -> void:
	var dimensions: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/fighters_mixamo/model_dimensions.json")
	)
	for id in dimensions:
		var model := ModelLoader.instantiate_scene(
			"res://assets/fighters_mixamo/fighter_%s.glb" % id
		)
		var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
		for slot in SimLimbs.LIMB_NAMES:
			var wound := LimbFinish.wound(skeleton, slot)
			assert_true(wound != null, "wound fits " + id + " " + slot)
			assert_true(wound.get_parent() is BoneAttachment3D, "wound follows joint")
			assert_true(wound.scale.y < 0.1, "thin recessed surface, no protruding bone")
			assert_true(wound.material_override is ShaderMaterial, "textured wound material")
		model.free()


func test_regrowth_bridge_preserves_skin_and_feathers_in_rest_space() -> void:
	var rig := FighterRig.new()
	assert_true(rig.load_fighter("atalanta"), "loads character")
	for slot in ["arm_l", "leg_l"]:
		var id := "crab_claw_arm" if slot == "arm_l" else "hermes_sandal_leg"
		assert_true(rig.attach_regrown(slot, id), "attaches replacement")
		var seams: Array = rig.replacements[slot].find_children(
			"SEAM_*", "MeshInstance3D", true, false
		)
		assert_true(not seams.is_empty(), "natural proximal surface bridges the join")
		for seam in seams:
			assert_true(seam.skin != null, "bridge retains skin deformation")
			var colors: PackedColorArray = seam.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
			var low := 1.0
			var high := 0.0
			for color in colors:
				low = minf(low, color.r)
				high = maxf(high, color.r)
			assert_true(low < 0.7 and high > 0.99, "bridge fades before distal limb")
		rig.detach_regrown(slot)
	rig.free()


func test_camera_retains_stronger_sever_impact() -> void:
	var camera := FightCamera.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(camera)
	camera.impact(0.13, true)
	var strong := camera.kick
	var zoom := camera.sever_zoom
	camera.impact(0.02)
	assert_eq(camera.kick, strong, "weaker simultaneous hit does not cancel shake")
	assert_eq(camera.sever_zoom, zoom, "weaker hit does not cancel sever camera push")
	camera.free()
