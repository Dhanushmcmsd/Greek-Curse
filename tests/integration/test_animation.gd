extends TestBase


func test_all_fighters_states_masks_are_finite_grounded_and_hidden() -> void:
	var checks := 0
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		rig.load_fighter(id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for bone_name in driver.data["bones"]:
			assert_true(rig.skeleton.find_bone(bone_name) >= 0, "required bone exists")
		for mask in 16:
			var config := MatchConfig.new()
			config.fighter_ids = [id, "atalanta"]
			var world := MatchLauncher.make_world(config)
			var fighter := world.fighters[0]
			SimBodyState.apply_mask(fighter, mask)
			fighter.pose = SimBodyState.movement(fighter, world.body_rules)["pose"]
			for state in SimFighter.State.size():
				fighter.state = state
				driver.update(fighter)
				assert_true(rig.transform.is_finite(), "finite root")
				assert_true(abs(driver.floor_min) < 0.015, "floor contact")
				for bone in rig.skeleton.get_bone_count():
					assert_true(rig.skeleton.get_bone_global_pose(bone).is_finite(), "finite bone")
				for slot in SimLimbs.LIMB_NAMES:
					assert_eq(
						rig.limb_meshes[slot][0].visible,
						fighter.limbs.parts[slot].state != "severed",
						"hidden severed mesh"
					)
				checks += 1
		rig.free()
	assert_eq(checks, 768, "4 fighters x 12 states x 16 masks")


func test_facing_and_attack_phases_follow_sim() -> void:
	var rig := FighterRig.new()
	rig.load_fighter("theron")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	var driver := PoseDriver.new()
	driver.setup(rig)
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	for facing in [-1, 1]:
		fighter.facing = facing
		driver.update(fighter)
		assert_true(rig.basis.z.x * facing > 0.99, "model forward faces opponent")
	for move in world.moves:
		fighter.begin_move(1, move, 1, 1)
		for pair in [
			[fighter.startup_ticks - 1, "startup"],
			[fighter.startup_ticks, "active"],
			[fighter.startup_ticks + fighter.active_ticks, "recovery"]
		]:
			fighter.state_tick = pair[0]
			fighter.state = (
				SimFighter.State.STARTUP
				if pair[1] == "startup"
				else SimFighter.State.ACTIVE if pair[1] == "active" else SimFighter.State.RECOVERY
			)
			driver.update(fighter)
			assert_true(driver.phase.ends_with(pair[1]), "exact phase " + move["id"])
	rig.free()


func test_pose_never_mutates_sim_and_hitstop_freezes_time() -> void:
	var rig := FighterRig.new()
	rig.load_fighter("theron")
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	var driver := PoseDriver.new()
	driver.setup(rig)
	var world := ProtoFixture.world_with()
	var before := world.hash_state()
	driver.update(world.fighters[0])
	var time := driver.time
	driver.update(world.fighters[0], true)
	assert_eq(driver.time, time, "hitstop freezes procedural timer")
	assert_eq(world.hash_state(), before, "presentation leaves deterministic state untouched")
	rig.free()


func test_feet_touch_floor_in_standing_and_walk() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		rig.load_fighter(id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var driver := PoseDriver.new()
		driver.setup(rig)
		var config := MatchConfig.new()
		config.fighter_ids = [id, "atalanta"]
		var fighter := MatchLauncher.make_world(config).fighters[0]
		for state in [SimFighter.State.IDLE, SimFighter.State.WALK]:
			fighter.state = state
			for tick in 36:
				driver.update(fighter)
				var floor_y := INF
				for side in ["l", "r"]:
					var mesh: MeshInstance3D = rig.limb_meshes["leg_" + side][2]
					var bone := rig.skeleton.find_bone("foot." + side)
					var matrix := (
						rig.global_transform
						* rig.skeleton.get_bone_global_pose(bone)
						* rig.skeleton.get_bone_global_rest(bone).affine_inverse()
						* mesh.transform
					)
					for surface in mesh.mesh.get_surface_count():
						for vertex in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
							floor_y = minf(floor_y, (matrix * vertex).y)
				assert_true(abs(floor_y) <= 0.015, "actual foot vertices touch floor " + id)
		rig.free()


func test_match_buttons_reset_and_grant_replacements() -> void:
	var controller := MatchController.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(controller)
	controller.world.fighters[0].health = 1
	controller._match_tools.new_match_requested.emit()
	assert_eq(controller.world.fighters[0].health, 300, "visible new match resets health")
	controller._match_tools.replacement_requested.emit(0, "arm_l", "rubber_chicken_arm")
	assert_eq(
		controller.world.fighters[0].limbs.parts["arm_l"].regrown_id,
		"rubber_chicken_arm",
		"visible replacement action grants limb"
	)
	controller._results.new_match_requested.emit()
	assert_eq(
		controller.world.fighters[0].limbs.parts["arm_l"].regrown_id,
		"",
		"results new match restores fresh body"
	)
	controller.free()


func test_attack_pose_matrix_includes_body_fallbacks() -> void:
	var maximum_delta := 0
	var cases := 0
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var rig := FighterRig.new()
		rig.load_fighter(id)
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		var driver := PoseDriver.new()
		driver.setup(rig)
		for mask in 16:
			var config := MatchConfig.new()
			config.fighter_ids = [id, "atalanta"]
			var world := MatchLauncher.make_world(config)
			var fighter := world.fighters[0]
			SimBodyState.apply_mask(fighter, mask)
			fighter.pose = SimBodyState.movement(fighter, world.body_rules)["pose"]
			for move in world.moves:
				cases += 1
				fighter.begin_move(1, move, 1, 1)
				fighter.attack_slot = move["limb_side"]
				fighter.state = SimFighter.State.ACTIVE
				fighter.state_tick = fighter.startup_ticks
				driver.update(fighter)
				assert_true(rig.transform.is_finite(), "finite fallback attack " + move["id"])
				if fighter.attack_slot == "body" or fighter.limbs.usable(fighter.attack_slot):
					maximum_delta = maxi(maximum_delta, driver.reach_mismatch_mm)
					assert_true(
						(
							driver.reach_mismatch_mm
							<= int(driver.data["settings"]["reach_tolerance_mm"])
						),
						(
							"visual reach "
							+ id
							+ move["id"]
							+ str(mask)
							+ " delta="
							+ str(driver.reach_mismatch_mm)
						)
					)
		rig.free()
	print("ANIMATION_ATTACK_MATRIX cases=", cases, " maximum_reach_delta_mm=", maximum_delta)
