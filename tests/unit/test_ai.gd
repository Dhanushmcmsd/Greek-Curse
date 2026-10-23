extends TestBase


func test_delay_and_observation_does_not_mutate_world() -> void:
	var world := ProtoFixture.world_with()
	var ai := MatchLauncher.make_ai("normal", 18)
	var before := world.hash_state()
	for tick in 12:
		var observed := AIObservation.capture(world, 0)
		observed["tick"] = tick
		assert_eq(ai.decide(observed), 0, "reaction delay")
	assert_eq(world.hash_state(), before, "observation immutable snapshot")


func test_ai_inputs_legal_for_every_body_mask() -> void:
	for mask in 16:
		var world := ProtoFixture.world_with()
		world.fighters[0].x = 0
		world.fighters[1].x = 400
		SimBodyState.apply_mask(world.fighters[0], mask)
		var ai := MatchLauncher.make_ai("hard", mask + 1)
		for tick in 100:
			world.tick = tick
			var input := ai.decide(AIObservation.capture(world, 0))
			if input & (16 | 32 | 64):
				assert_true(
					not (
						SimMoveAvailability
						. select(world.fighters[0], input, world.body_rules)
						. is_empty()
					),
					"legal"
				)


func test_same_seed_same_full_simulation() -> void:
	var a := ProtoFixture.world_with()
	var b := ProtoFixture.world_with()
	var agents := [
		MatchLauncher.make_ai("normal", 11),
		MatchLauncher.make_ai("hard", 12),
		MatchLauncher.make_ai("normal", 11),
		MatchLauncher.make_ai("hard", 12)
	]
	for tick in 500:
		a.step(
			[
				agents[0].decide(AIObservation.capture(a, 0)),
				agents[1].decide(AIObservation.capture(a, 1))
			]
		)
		b.step(
			[
				agents[2].decide(AIObservation.capture(b, 0)),
				agents[3].decide(AIObservation.capture(b, 1))
			]
		)
		assert_eq(a.hash_state(), b.hash_state(), "AI replay deterministic")


func test_dummies_and_config_validation() -> void:
	assert_eq(DummyController.input_for("block_always", 99), 128, "block dummy")
	assert_eq(DummyController.input_for("attack_on_interval", 90), 16, "attack dummy")
	assert_eq(DummyController.input_for("attack_on_interval", 91), 0, "interval")
	var config := MatchConfig.new()
	assert_eq(config.validate(), "", "valid")
	config.controllers = ["human_kb1", "human_kb1"]
	assert_true(config.validate() != "", "duplicate device")
	config.fighter_ids = ["unknown", "theron"]
	assert_true(config.validate() != "", "unknown fighter")


func test_future_move_is_read_from_data() -> void:
	var world := ProtoFixture.world_with()
	world.moves[0]["id"] = "fixture_new_move"
	world.body_rules["default_moves"]["light"] = "fixture_new_move"
	var observation := AIObservation.capture(world, 0)
	var found := false
	for option in observation["options"]:
		if option["id"] == "fixture_new_move":
			found = true
	assert_true(found, "new data move available without AI edit")
