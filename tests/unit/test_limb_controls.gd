extends TestBase


func test_each_limb_key_is_disabled_until_regrowth() -> void:
	var keys := [SimInput.LIGHT, SimInput.HEAVY, SimInput.KICK, SimInput.KICK_RIGHT]
	for index in 4:
		for facing in [-1, 1]:
			var world := ProtoFixture.world_with()
			var fighter := world.fighters[0]
			fighter.facing = facing
			var slot: String = SimLimbs.LIMB_NAMES[index]
			assert_eq(
				SimMoveAvailability.select(fighter, keys[index], world.body_rules).slot,
				slot,
				"explicit side"
			)
			fighter.limbs.parts[slot].state = "severed"
			for tick in 10:
				world.step([keys[index], 0])
			assert_eq(fighter.move_id, 0, "missing limb cannot start attack " + slot)
			var id := "hermes_sandal_leg" if index >= 2 else "rubber_chicken_arm"
			assert_true(fighter.limbs.regrow(slot, id), "regrow")
			world.step([0, 0])
			world.step([keys[index], 0])
			assert_true(fighter.move_id > 0, "regrown limb attacks")
			assert_eq(fighter.attack_slot, slot, "same side restored")


func test_loss_during_startup_cancels_hit_and_animation_state() -> void:
	for slot in SimLimbs.LIMB_NAMES:
		var world := ProtoFixture.world_with()
		var fighter := world.fighters[0]
		var key: int = [16, 32, 64, SimInput.KICK_RIGHT][SimLimbs.LIMB_NAMES.find(slot)]
		world.step([key, 0])
		assert_true(fighter.move_id > 0, "started")
		fighter.limbs.parts[slot].state = "severed"
		world.step([0, 0])
		assert_eq(fighter.move_id, 0, "interrupted strike cleared")
		assert_eq(fighter.hit_w, 0, "no phantom hitbox")


func test_one_leg_hop_and_kick_recovery_both_sides() -> void:
	var rig := FighterRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	assert_true(rig.load_fighter("theron"), "rig")
	var driver := PoseDriver.new()
	driver.setup(rig)
	for missing in ["leg_l", "leg_r"]:
		var world := ProtoFixture.world_with()
		var fighter := world.fighters[0]
		fighter.limbs.parts[missing].state = "severed"
		world.step([SimInput.LEFT, 0])
		driver.update(fighter)
		assert_eq(driver.current_action_name, "idle", "never two-legged walk")
		assert_eq(driver._one_leg.stage, "hop", "side-aware hop")
		var key := SimInput.KICK_RIGHT if missing == "leg_l" else SimInput.KICK
		world.step([key, 0])
		var total := fighter.startup_ticks + fighter.active_ticks + fighter.recovery_ticks
		var stages := {}
		for tick in total + 2:
			driver.update(fighter)
			stages[driver._one_leg.stage] = true
			assert_true(is_finite(rig.position.y), "finite grounding")
			world.step([0, 0])
		assert_true(
			stages.has("kick") and stages.has("fall") and stages.has("rise"),
			"complete kick fall rise"
		)
		assert_eq(fighter.move_id, 0, "normal timing completed")
	rig.free()


func test_severed_and_regrown_mesh_visibility_all_models() -> void:
	var models: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://assets/fighters_mixamo/model_dimensions.json")
	)
	for model_id in models:
		var rig := FighterRig.new()
		(Engine.get_main_loop() as SceneTree).root.add_child(rig)
		assert_true(rig.load_fighter("theron", model_id), "load " + model_id)
		var fighter := ProtoFixture.world_with().fighters[0]
		var driver := PoseDriver.new()
		driver.setup(rig)
		for slot in SimLimbs.LIMB_NAMES:
			fighter.limbs.parts[slot].state = "severed"
			var id := "hermes_sandal_leg" if slot.begins_with("leg") else "rubber_chicken_arm"
			assert_true(fighter.limbs.regrow(slot, id), "replacement")
			driver.update(fighter)
			assert_true(rig.replacements.has(slot), "one replacement exists")
			fighter.limbs.parts[slot].state = "severed"
			fighter.limbs.parts[slot].regrown_id = ""
			# A legacy clip must not override simulation-owned visibility.
			var animation := rig.anim_player.get_animation("theron_idle")
			for mesh in rig.limb_meshes[slot]:
				var track := animation.add_track(Animation.TYPE_VALUE)
				animation.track_set_path(
					track, NodePath(str(rig.model.get_path_to(mesh)) + ":visible")
				)
				animation.track_insert_key(track, 0.0, true)
			driver.update(fighter)
			assert_false(rig.replacements.has(slot), "no phantom replacement")
			for mesh in rig.limb_meshes[slot]:
				assert_false(
					mesh.is_visible_in_tree(), "no natural limb after re-sever " + model_id + slot
				)
			assert_true(rig.stumps[slot].visible, "wound visible")
		rig.free()


func test_new_bindings_merge_into_existing_settings_and_buffer() -> void:
	var bindings := InputBindings.new()
	assert_eq(
		bindings.import_bindings({"p1_kick": {"key": "L", "button": 0, "device": 0}}),
		"",
		"old save"
	)
	assert_eq(bindings.bindings.p1_kick_right.key, "O", "new right kick retained")
	assert_eq(bindings.bindings.p1_body.key, "B", "explicit fallback retained")
	var buffer := SimInputBuffer.new()
	buffer.push(SimInput.KICK_RIGHT, 1, 6)
	assert_true(buffer.has_edge(SimInput.KICK_RIGHT, 1, 6), "right kick buffered")
	buffer.consume(SimInput.KICK_RIGHT)
	assert_false(buffer.has_edge(SimInput.KICK_RIGHT, 1, 6), "right kick consumed")
