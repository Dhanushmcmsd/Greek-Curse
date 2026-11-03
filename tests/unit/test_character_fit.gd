extends TestBase


func test_mesh_height_matches_every_model_skeleton() -> void:
	var dimensions: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/fighters_mixamo/model_dimensions.json")
	)
	for model_id in dimensions:
		var rig := FighterRig.new()
		assert_true(rig.load_fighter("theron", model_id), "loads " + model_id)
		var bounds := AABB()
		for mesh in rig.model.find_children("*", "MeshInstance3D", true, false):
			if mesh.skin != null:
				bounds = bounds.merge(mesh.get_aabb()) if bounds.has_volume() else mesh.get_aabb()
		var height: float = dimensions[model_id]["target_height_m"]
		assert_near(bounds.position.y, 0.0, 0.002, model_id + " feet rest on floor")
		assert_near(bounds.size.y, height, 0.002, model_id + " mesh is normalized exactly once")
		assert_near(rig.fighter_height, 1.8, 0.002, "common visual height")
		assert_near(
			bounds.size.y * rig.model.scale.y, 1.8, 0.002, "baked mesh scaled once to common height"
		)
		rig.free()


func test_retarget_preserves_rest_roll_even_with_equal_bone_counts() -> void:
	var source := Skeleton3D.new()
	source.add_bone("root")
	source.add_bone("hand.l")
	source.set_bone_parent(1, 0)
	source.set_bone_rest(0, Transform3D(Basis(Vector3.UP, 0.3), Vector3(0, 1, 0)))
	source.set_bone_rest(1, Transform3D(Basis(Vector3.UP, 0.7), Vector3(1, 0, 0)))
	source.rotation.x = PI / 2
	var target := Skeleton3D.new()
	target.add_bone("root")
	target.add_bone("hand.l")
	target.set_bone_parent(1, 0)
	target.set_bone_rest(0, Transform3D(Basis(Vector3.UP, -0.4), Vector3(0, 2, 0)))
	target.set_bone_rest(1, Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(2, 0, 0)))
	var clip := Animation.new()
	for bone in 2:
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Skeleton3D:" + source.get_bone_name(bone)))
		clip.rotation_track_insert_key(
			track, 0, source.get_bone_rest(bone).basis.get_rotation_quaternion()
		)
	var result := FighterRig.retarget_animation(clip, source, target)
	for track in result.get_track_count():
		if result.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			var bone := target.find_bone(result.track_get_path(track).get_concatenated_subnames())
			assert_true(
				(
					result.rotation_track_interpolate(track, 0).angle_to(
						target.get_bone_rest(bone).basis.get_rotation_quaternion()
					)
					< 0.001
				),
				"rest pose maps to target rest pose, not source bone roll"
			)
	source.free()
	target.free()


func test_current_glb_can_bind_without_any_imported_skin_cache() -> void:
	var pilot := ModelLoader.instantiate_scene(
		"res://build/pilot_gate_a/arissa_partitioned.glb", true
	)
	var target := pilot.find_child("Skeleton3D", true, false) as Skeleton3D
	for slot in ["arm_l", "leg_l"]:
		var path: String = "res://assets/limbs_elemental/elemental_atalanta_%s.glb" % slot
		var source := ModelLoader.instantiate_scene(path, true)
		var meshes := source.find_children("*", "MeshInstance3D", true, false)
		assert_false(meshes.is_empty(), "raw GLB contains visible geometry")
		for mesh in meshes:
			assert_true(
				FighterRig.adapt_mesh_skin_to_skeleton(mesh, target),
				"both indexed and named skins bind: " + slot
			)
		source.free()
	pilot.free()


func test_backward_walk_uses_forward_time_and_keeps_facing() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		rig.load_fighter(id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var driver := PoseDriver.new()
		driver.setup(rig)
		var config := MatchConfig.new()
		config.fighter_ids = [id, "atalanta"]
		var fighter := MatchLauncher.make_world(config).fighters[0]
		fighter.state = SimFighter.State.WALK
		for facing in [-1, 1]:
			fighter.facing = facing
			driver.walk_direction = -facing
			driver.update(fighter)
			assert_eq(
				driver.current_clip_id,
				"walking_back_walking_backwards",
				"straight backward walking, not turn or injury clip"
			)
			assert_true(
				rig.anim_player.speed_scale > 0, "a backward clip must not be played in reverse"
			)
			assert_true(
				rig.basis.z.x * facing > 0.99, "retreat preserves opponent-facing direction"
			)
		rig.free()


func test_cracked_limb_does_not_accumulate_rotation_during_hitstop() -> void:
	var rig := FighterRig.new()
	rig.load_fighter("theron")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	var driver := PoseDriver.new()
	driver.setup(rig)
	var fighter := ProtoFixture.world_with().fighters[0]
	fighter.limbs.parts["arm_l"].state = "cracked"
	driver.update(fighter)
	var bone := rig.skeleton.find_bone("upper_arm.l")
	var rotation := rig.skeleton.get_bone_pose_rotation(bone)
	for tick in 10:
		driver.update(fighter, true)
		assert_true(
			rotation.angle_to(rig.skeleton.get_bone_pose_rotation(bone)) < 0.001,
			"hitstop holds the damaged pose without twisting further"
		)
	rig.free()
