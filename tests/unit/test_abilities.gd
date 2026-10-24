extends TestBase


func _world() -> SimWorld:
	var config := MatchConfig.new()
	config.rules["hazards"] = false
	return MatchLauncher.make_world(config)


func test_all_twenty_one_abilities_have_valid_loadout_and_move_data() -> void:
	var world := _world()
	assert_eq(world.abilities.size(), 21, "locked roster")
	assert_eq(
		Loadout.validate(Loadout.full(), world.abilities.keys(), world.abilities),
		"",
		"full loadout"
	)
	assert_true(
		Loadout.validate(Loadout.full(), Loadout.STARTER, world.abilities) != "", "locked rejected"
	)
	for id in world.abilities:
		var row: Dictionary = world.abilities[id]
		if row["type"] != "passive":
			var test := _world()
			var fighter := test.fighters[0]
			fighter.meter = 100
			SimMovement._begin_named(
				test,
				fighter,
				id,
				(
					"body"
					if row["type"] in ["superpower", "ultimate"]
					else "leg_l" if row["type"] == "kick" else "arm_l"
				)
			)
			assert_eq(fighter.move_name, id, "starts " + id)
			assert_eq(fighter.meter, 100 - int(row["meter_cost"]), "meter " + id)
			assert_eq(
				int(fighter.ability_cooldowns[id]), int(row["cooldown_ticks"]), "cooldown " + id
			)


func test_ultimate_has_full_counterplay_window_and_spam_cannot_bypass_cooldown() -> void:
	var world := _world()
	var fighter := world.fighters[0]
	fighter.meter = 100
	SimMovement._begin_named(world, fighter, "zeus_wrath", "body")
	assert_eq(fighter.startup_ticks, 42, "0.7 seconds")
	assert_eq(fighter.meter, 0, "full meter spent")
	fighter.clear_move()
	fighter.state = SimFighter.State.IDLE
	SimMovement._begin_named(world, fighter, "zeus_bolt", "body")
	fighter.clear_move()
	fighter.state = SimFighter.State.IDLE
	SimMovement._begin_named(world, fighter, "zeus_bolt", "body")
	assert_eq(fighter.move_id, 0, "cooldown blocks spam")
	assert_eq(int(fighter.ability_cooldowns["zeus_bolt"]), 840, "14 seconds")


func test_shared_effects_exact_values_and_refresh() -> void:
	var world := _world()
	var a := world.fighters[0]
	var b := world.fighters[1]
	SimAbilities.apply(world, a, a, {"kind": "shield", "absorb": 40, "burst_damage": 12})
	assert_eq(a.shield, 40, "shield capacity")
	var start := a.x
	SimAbilities.apply(world, a, a, {"kind": "dash", "distance": 900, "invulnerable_ticks": 18})
	assert_eq(a.x, start + 900, "dash")
	assert_eq(a.invulnerable_until, 18, "iframe duration")
	var rage := {"kind": "buff_self", "duration": 360, "damage_percent": 125, "taken_percent": 115}
	SimAbilities.apply(world, a, a, rage)
	SimAbilities.apply(world, a, a, rage)
	assert_eq(a.modifiers.size(), 1, "refresh not stacking")
	assert_eq(SimModifier.percent_for(a, 0), 125, "rage damage")
	assert_eq(SimAbilities.incoming(a, 0, 100, false), 115, "rage drawback")
	assert_eq(SimModifier.percent_for(a, 360), 100, "half open expiry")
	SimAbilities.apply(world, a, b, {"kind": "force_limb_state"}, "leg_l")
	assert_eq(b.limbs.parts["leg_l"].state, "cracked", "guaranteed cracked")


func test_presentation_references_and_data_only_fixture() -> void:
	var world := _world()
	var poses: Dictionary = DataLoader.new().load_json("res://data/animation/poses.json").value
	var captions: Dictionary = DataLoader.new().load_json("res://data/ui/captions_en.json").value
	for row in world.abilities.values():
		assert_true(FileAccess.file_exists("res://assets/ui/icons/%s.svg" % row["icon_id"]), "icon")
		assert_true(captions.has(row["caption_id"]), "caption")
		if row["type"] != "passive":
			assert_true(poses["sets"].has(row["anim_set"]), "animation")
		for id in row["audio_ids"]:
			assert_true(FileAccess.file_exists("res://assets/audio/sfx/%s.wav" % id), "sound")
	var fixture: Dictionary = world.abilities["ares_rage"].duplicate(true)
	fixture["id"] = "test_fixture"
	world.abilities["test_fixture"] = fixture
	SimAbilities.apply(world, world.fighters[0], world.fighters[0], fixture["effects"][0])
	assert_eq(SimModifier.percent_for(world.fighters[0], 0), 125, "data-only copied primitive")
