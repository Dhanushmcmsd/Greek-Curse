extends TestBase

func test_idle_and_block_guards_stay_below_head_and_apart() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var f := MatchLauncher.make_world(config).fighters[0]
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_true(rig.load_fighter(id), id)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for blocking in [false, true]:
			f.blocking = blocking
			for sample in 8:
				driver.update(f)
				var s := rig.skeleton
				var head := s.get_bone_global_pose(s.find_bone("head")).origin
				var l := s.get_bone_global_pose(s.find_bone("hand.l")).origin
				var r := s.get_bone_global_pose(s.find_bone("hand.r")).origin
				for hand in [l, r]:
					assert_true(hand.y < head.y + 0.04 and hand.y > head.y - 0.40, id + " face-height guard")
				assert_true(l.distance_to(r) > 0.16, id + " separate fists")
				rig.anim_player.advance(0.15)
		rig.free()


func test_fast_fighters_use_new_walk_and_wrists_remain_anatomical() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "theron"])
		var world := MatchLauncher.make_world(config)
		var f := world.fighters[0]
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		rig.load_fighter(id)
		var driver := PoseDriver.new()
		driver.setup(rig)
		f.state = SimFighter.State.WALK
		f.walk_speed = 55
		for direction in [f.facing, -f.facing]:
			driver.walk_direction = direction
			driver.update(f)
			assert_eq(driver.current_action_name, "walk_fwd" if direction == f.facing else "walk_back", "fast fighter uses authored walk")
		SimMovement._begin_named(world, f, id + "_signature", "arm_r")
		for frame in 80:
			world.step([0, 0])
			driver.update(f)
			for side in ["l", "r"]:
				var hand := rig.skeleton.find_bone("hand." + side)
				var rest := rig.skeleton.get_bone_rest(hand).basis.get_rotation_quaternion()
				assert_true(rest.angle_to(rig.skeleton.get_bone_pose_rotation(hand)) < 0.451, id + " wrist flexion")
		rig.free()


func test_authored_walks_and_blocks_are_bound_looping_resources() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]:
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_true(rig.load_fighter(id), id)
		for action in ["walk_fwd", "walk_back", "block"]:
			var baked := load("res://assets/animations/exported/" + id + "/action_" + action + ".res") as Animation
			var playing := rig.anim_player.get_animation(id + "_" + action)
			assert_true(baked == playing, "runtime binds exported " + id + action)
			assert_eq(playing.loop_mode, Animation.LOOP_LINEAR, "continuous locomotion/guard")
			assert_true(playing.length > 0.1, "nonempty clip")
		rig.free()
