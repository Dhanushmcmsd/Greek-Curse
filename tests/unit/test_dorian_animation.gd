extends TestBase


func test_roster_has_authored_stances_and_block_reactions() -> void:
	var signatures: Array[String] = []
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_true(rig.load_fighter(id), "rig " + id)
		for action in ["idle", "block", "block_impact"]:
			var clip := rig.anim_player.get_animation(id + "_" + action)
			assert_true(clip != null, id + " " + action)
			assert_eq(clip.loop_mode, Animation.LOOP_NONE if action == "block_impact" else Animation.LOOP_LINEAR, "correct loop mode")
		var digest := FileAccess.get_md5("res://assets/animations/exported/" + id + "/action_idle.res")
		assert_true(digest not in signatures, "distinct retargeted stance " + id)
		signatures.append(digest)
		rig.free()


func test_johnny_four_buttons_select_distinct_limbs() -> void:
	var config := MatchConfig.new()
	config.fighter_ids.assign(["dorian", "theron"])
	var world := MatchLauncher.make_world(config)
	for down in [0, SimInput.DOWN]:
		var left := SimMoveAvailability.select(world.fighters[0], down | SimInput.KICK, world.body_rules)
		var right := SimMoveAvailability.select(world.fighters[0], down | SimInput.KICK_RIGHT, world.body_rules)
		assert_eq(left.slot, "leg_l", "left kick")
		assert_eq(right.slot, "leg_r", "right kick")
		assert_true(left.id != right.id, "different authored kicks")


func test_all_johnny_moves_load_exported_motion_without_stretching() -> void:
	var rig := FighterRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	assert_true(rig.load_fighter("dorian"), "complete modular Johnny rig")
	var row: Dictionary = DataLoader.new().load_json("res://data/fighters/dorian.json").value
	for move in row.moves:
		var path: String = "res://assets/animations/exported/dorian/" + move + ".res"
		assert_true(ResourceLoader.exists(path), "baked source " + move)
		var name: String = "dorian_move_" + move
		assert_true(rig.anim_player.has_animation(name), "bound " + move)
		var clip := rig.anim_player.get_animation(name)
		rig.anim_player.play(name)
		for fraction in [0.0, 0.25, 0.5, 0.75, 1.0]:
			rig.anim_player.seek(clip.length * fraction, true)
			for bone in rig.skeleton.get_bone_count():
				assert_true(rig.skeleton.get_bone_pose_rotation(bone).is_finite(), "finite rotation")
				assert_true(rig.skeleton.get_bone_pose_position(bone).distance_to(rig.skeleton.get_bone_rest(bone).origin) < 0.0001, "joint offset preserved " + move)
	rig.free()


func test_repeated_hit_restarts_and_hitstop_holds_reaction() -> void:
	var config := MatchConfig.new()
	config.fighter_ids.assign(["dorian", "theron"])
	var fighter := MatchLauncher.make_world(config).fighters[0]
	var rig := FighterRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	assert_true(rig.load_fighter("dorian"), "Johnny loads")
	var driver := PoseDriver.new()
	driver.setup(rig)
	fighter.state = SimFighter.State.HITSTUN
	fighter.state_tick = 12
	assert_true(driver._drive_clip(fighter, false), "hit uses clip")
	assert_eq(driver.current_action_name, "hit_light", "body reaction mapped")
	assert_near(rig.anim_player.current_animation_position, 0.0, 0.001, "reaction starts at zero")
	fighter.state_tick = 6
	driver._drive_clip(fighter, false)
	assert_near(rig.anim_player.current_animation_position, 0.1, 0.001, "countdown produces forward motion")
	driver._drive_clip(fighter, true)
	assert_near(rig.anim_player.current_animation_position, 0.1, 0.001, "hitstop")
	driver.on_hit("arm_l", false, 2)
	fighter.state_tick = 12
	driver._drive_clip(fighter, false)
	assert_near(rig.anim_player.current_animation_position, 0.0, 0.001, "consecutive hit restarts")
	rig.free()
