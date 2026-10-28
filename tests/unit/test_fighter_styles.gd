extends TestBase


func test_roster_commands_have_distinct_attacks_and_contact_counts() -> void:
	var seen: Array = []
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		world.hazards_enabled = false
		var a := world.fighters[0]
		var b := world.fighters[1]
		var lead := SimMoveAvailability.select(a, SimInput.LIGHT, world.body_rules)
		assert_true(lead.id not in seen, "unique lead " + id)
		seen.append(lead.id)
		assert_eq(lead.id, id + "_lead", "signature basic")
		for facing in [-1, 1]:
			for command in [
				SimInput.LIGHT,
				SimInput.HEAVY,
				SimInput.KICK,
				SimInput.KICK_RIGHT,
				SimInput.DOWN | SimInput.LIGHT,
				SimInput.DOWN | SimInput.KICK,
				(SimInput.RIGHT if facing == 1 else SimInput.LEFT) | SimInput.LIGHT,
				(SimInput.LEFT if facing == 1 else SimInput.RIGHT) | SimInput.LIGHT
			]:
				world._reset_bodies()
				a.x = -225 * facing
				b.x = 225 * facing
				a.facing = facing
				var selected := SimMoveAvailability.select(a, command, world.body_rules)
				var row: Dictionary = {}
				for move in world.moves:
					if move.id == selected.id:
						row = move
				assert_true(str(selected.id).begins_with(id + "_"), "roster command")
				assert_true(
					SimMovement._begin_named(world, a, selected.id, selected.slot),
					"start " + selected.id
				)
				var hits := 0
				for tick in 120:
					for event in world.step([0, 0]):
						if event.kind == SimEvent.Kind.HIT:
							hits += 1
				assert_eq(
					hits, int(row.get("hit_count", 1)), selected.id + " facing " + str(facing)
				)


func test_custom_loadouts_keep_equipped_moves() -> void:
	var config := MatchConfig.new()
	config.loadouts = [Loadout.starter()]
	var world := MatchLauncher.make_world(config)
	assert_eq(
		SimMoveAvailability.select(world.fighters[0], SimInput.LIGHT, world.body_rules).id,
		"jab_of_hermes",
		"explicit equipment wins"
	)
	assert_true(not world.fighters[1].moveset_aliases.is_empty(), "default opponent has identity")


func test_corrected_arms_keep_lengths_and_guard_through_attack_frames() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		var fighter := world.fighters[0]
		var rig := FighterRig.new()
		tree.root.add_child(rig)
		rig.load_fighter(id)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for facing in [-1, 1]:
			fighter.facing = facing
			for suffix in [
				"lead", "power", "rise", "low", "pressure", "pursuit", "retreat", "sweep"
			]:
				fighter.clear_move()
				fighter.stamina = 100
				SimMovement._begin_named(
					world,
					fighter,
					id + "_" + suffix,
					(
						"arm_r"
						if suffix == "power"
						else ("leg_l" if suffix in ["rise", "low", "sweep"] else "arm_l")
					)
				)
				for age in range(
					3, fighter.startup_ticks + fighter.active_ticks + fighter.recovery_ticks, 3
				):
					fighter.state_tick = age
					fighter.state = SimFighter.State.ACTIVE
					driver.update(fighter)
					rig.skeleton.force_update_all_bone_transforms()
					for side in ["l", "r"]:
						var upper := rig.skeleton.find_bone("upper_arm." + side)
						var lower := rig.skeleton.find_bone("forearm." + side)
						var hand := rig.skeleton.find_bone("hand." + side)
						var a := rig.skeleton.get_bone_global_pose(upper).origin
						var b := rig.skeleton.get_bone_global_pose(lower).origin
						var c := rig.skeleton.get_bone_global_pose(hand).origin
						var rest_a := rig.skeleton.get_bone_global_rest(upper).origin
						var rest_b := rig.skeleton.get_bone_global_rest(lower).origin
						var rest_c := rig.skeleton.get_bone_global_rest(hand).origin
						assert_true(c.is_finite(), id + " finite wrist")
						assert_true(
							absf(a.distance_to(b) - rest_a.distance_to(rest_b)) < 0.01,
							id + " upper arm length"
						)
						assert_true(
							absf(b.distance_to(c) - rest_b.distance_to(rest_c)) < 0.01,
							id + " forearm length"
						)
						assert_true(c.z > a.z + 0.06, id + " wrist stays in front of shoulder")
						assert_true(absf(c.y - a.y) < 0.25, id + " no overhead wrist inversion")
		rig.free()


func test_retarget_corrects_different_limb_rest_directions() -> void:
	var source := Skeleton3D.new()
	var target := Skeleton3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(target)
	var clip := Animation.new()
	clip.length = 0.1
	for index in 3:
		source.add_bone(["mixamorig_LeftArm", "mixamorig_LeftForeArm", "mixamorig_LeftHand"][index])
		target.add_bone(["upper_arm.l", "forearm.l", "hand.l"][index])
		if index > 0:
			source.set_bone_parent(index, index - 1)
			target.set_bone_parent(index, index - 1)
			source.set_bone_rest(index, Transform3D(Basis.IDENTITY, Vector3(0.3, 0, 0)))
			target.set_bone_rest(index, Transform3D(Basis.IDENTITY, Vector3(0, -0.3, 0)))
		var track := clip.add_track(Animation.TYPE_ROTATION_3D)
		clip.track_set_path(track, NodePath("Skeleton3D:" + source.get_bone_name(index)))
		clip.rotation_track_insert_key(track, 0, Quaternion.IDENTITY)
	target.reset_bone_poses()
	var result := FighterRig.retarget_animation(clip, source, target)
	load("res://tools/anim/exported_limb_alignment.gd").correct(result, clip, source, target)
	for track in result.get_track_count():
		if result.track_get_type(track) == Animation.TYPE_ROTATION_3D:
			var bone := target.find_bone(result.track_get_path(track).get_concatenated_subnames())
			target.set_bone_pose_rotation(bone, result.rotation_track_interpolate(track, 0))
	target.force_update_all_bone_transforms()
	var upper := target.get_bone_global_pose(0).origin
	var elbow := target.get_bone_global_pose(1).origin
	var wrist := target.get_bone_global_pose(2).origin
	assert_true(
		(elbow - upper).normalized().dot(Vector3.RIGHT) > 0.99, "upper arm follows source direction"
	)
	assert_true(
		(wrist - elbow).normalized().dot(Vector3.RIGHT) > 0.99, "forearm follows source direction"
	)
	source.free()
	target.free()
