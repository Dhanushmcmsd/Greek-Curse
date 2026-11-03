extends TestBase

func test_short_keyboard_taps_are_consumed_once_and_ignored_when_paused() -> void:
	var bindings := InputBindings.new()
	bindings.reset_defaults()
	bindings.install()
	var controller := MatchController.new()
	controller.match_config.controllers.assign(["human_kb1", "dummy_idle"])
	controller.world = MatchLauncher.make_world(controller.match_config)
	var press := InputEventKey.new()
	press.physical_keycode = KEY_I
	press.pressed = true
	controller._input(press)
	assert_true(bool(controller._read_inputs()[0] & SimInput.ULTIMATE), "short I tap survives key release before polling")
	assert_eq(controller._read_inputs()[0], 0, "edge consumed once")
	controller.flow.paused = true
	controller._input(press)
	assert_eq(controller._read_inputs()[0], 0, "pause does not queue an ultimate")
	controller.free()

func test_starter_career_has_a_usable_native_ultimate_without_mutating_save() -> void:
	var config := MatchConfig.new()
	config.mode = "career"
	config.loadouts = [Loadout.starter(), Loadout.starter()]
	var world := MatchLauncher.make_world(config)
	var fighter := world.fighters[0]
	fighter.meter = 100
	assert_eq(SimMoveAvailability.select(fighter, SimInput.ULTIMATE, world.body_rules).id, "zeus_wrath", "I resolves even without an equipment unlock")
	world.step([SimInput.ULTIMATE, 0])
	assert_eq(fighter.move_name, "zeus_wrath", "normal ultimate input activates")
	assert_eq(fighter.meter, 0, "activation spends ultimate charge")
	assert_false(fighter.loadout.has("ultimate"), "native fallback does not rewrite inventory")

func test_ultimate_hit_stuns_for_one_second_but_guard_does_not() -> void:
	for blocked in [false, true]:
		var world := MatchLauncher.make_world(MatchConfig.new())
		var a := world.fighters[0]
		var b := world.fighters[1]
		a.meter = 100
		b.health = 1000
		b.blocking = blocked
		SimMovement._begin_named(world, a, "zeus_wrath", "arm_l")
		SimCombat._connect(world, a, b, 0, "torso", [])
		assert_eq(b.state_tick, a.attack_blockstun if blocked else 60, "confirmed lightning stuns; guard has ordinary blockstun")
		assert_true(b.health < 1000, "strike deals damage")


func test_cinematic_sources_play_and_severed_limbs_stay_hidden() -> void:
	for id in ["theron", "pyrrhus", "atalanta", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "dorian"])
		var fighter := MatchLauncher.make_world(config).fighters[0]
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		rig.load_fighter(id)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for action in ["zeus_wrath", "olympian_barrage", "hit_electric", "sever_arm", "sever_leg_l", "sever_leg_r", "knockdown"]:
			assert_true(rig.anim_player.has_animation(id + "_" + action), id + " imported " + action)
		for slot in ["arm_l", "leg_l", "leg_r"]:
			fighter.limbs.parts[slot].state = "severed"
			fighter.state = SimFighter.State.HITSTUN
			fighter.state_tick = 30
			driver.on_sever(slot)
			driver.update(fighter)
			assert_eq(driver.current_action_name, "sever_" + (slot if slot.begins_with("leg") else "arm"), "slot-specific imported brutality")
			for mesh in rig.limb_meshes[slot]:
				assert_false(mesh.visible, "animation cannot restore missing limb")
		rig.free()


func test_all_state_transitions_blend_and_hold_during_hitstop() -> void:
	var rig := FighterRig.new()
	rig.skeleton = Skeleton3D.new()
	rig.add_child(rig.skeleton)
	rig.skeleton.add_bone("root")
	var driver := PoseDriver.new()
	driver.rig = rig
	var fighter := SimFighter.new()
	for action in ["idle", "walk_fwd", "walk_back", "block", "hit_light", "grabbed", "zeus_wrath", "knockdown"]:
		driver._previous_pose.assign([Quaternion.IDENTITY])
		driver.current_action_name = action
		rig.skeleton.set_bone_pose_rotation(0, Quaternion(Vector3.RIGHT, 1.0))
		driver._blend_pose(fighter, false, true)
		assert_true(rig.skeleton.get_bone_pose_rotation(0).angle_to(Quaternion.IDENTITY) < 0.001, action + " starts from outgoing pose")
		var age := driver._transition_age
		driver._blend_pose(fighter, true, true)
		assert_eq(driver._transition_age, age, "hitstop freezes transition")
		for frame in 8:
			rig.skeleton.set_bone_pose_rotation(0, Quaternion(Vector3.RIGHT, 1.0))
			driver._blend_pose(fighter, false, true)
		assert_true(rig.skeleton.get_bone_pose_rotation(0).angle_to(Quaternion(Vector3.RIGHT, 1.0)) < 0.001, action + " completes without old clip overlay")
	rig.free()


func test_contact_cache_is_bounded_and_tracks_full_skin_floor() -> void:
	for id in ["theron", "pyrrhus", "atalanta", "sibyl", "dorian"]:
		var config := MatchConfig.new()
		config.fighter_ids.assign([id, "dorian"])
		var world := MatchLauncher.make_world(config)
		var fighter := world.fighters[0]
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		rig.load_fighter(id)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for move in [id + "_counter", id + "_breaker", "zeus_wrath"]:
			SimMovement._begin_named(world, fighter, move, "arm_l")
			for tick in [0, 10, 25, 40]:
				fighter.state_tick = tick
				driver.update(fighter)
				for item in driver._bounds:
					var mesh: MeshInstance3D = item[0]
					if mesh.skin == null:
						continue
					var sampled := driver._skinned_floor(mesh)
					var entries: Array = driver._skin_vertices[mesh.mesh.get_instance_id()]
					var saved: Array = []
					for entry in entries:
						assert_true(entry[1].size() <= 384, "bounded surface contact count")
						saved.append(entry[1])
						entry[1] = PackedInt32Array(range(entry[0][Mesh.ARRAY_VERTEX].size()))
					var exact := driver._skinned_floor(mesh)
					for i in entries.size():
						entries[i][1] = saved[i]
					assert_true(absf(sampled - exact) < 0.045, id + " weighted floor error below 4.5cm: " + str(sampled - exact))
		rig.free()
