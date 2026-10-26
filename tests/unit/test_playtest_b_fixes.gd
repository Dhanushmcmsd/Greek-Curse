extends TestBase


func test_normal_jabs_sever_an_arm_without_fixture_overrides() -> void:
	for id in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		var config := MatchConfig.new()
		config.fighter_ids = ["theron", id]
		var world := MatchLauncher.make_world(config)
		world.fighters[0].x = 0
		world.fighters[1].x = 430
		var severed := false
		for tick in 480:
			var gap := absi(world.fighters[1].x - world.fighters[0].x)
			world.step([SimInput.RIGHT if gap > 550 else SimInput.LIGHT, 0])
			if world.fighters[1].limbs.losses > 0:
				severed = true
				break
		assert_true(severed, "ordinary punches sever arm on " + id)


func test_normal_kick_hits_leg_integrity() -> void:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	for tick in 20:
		world.step([SimInput.KICK, 0])
	var limbs := world.fighters[1].limbs
	assert_true(
		int(limbs.integrity["leg_l"]) < 90 or int(limbs.integrity["leg_r"]) < 90,
		"kick damages a leg"
	)


func test_throw_updates_facing_on_same_tick() -> void:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.moves[3]["startup_ticks"] = 0
	world.step([SimInput.LIGHT | SimInput.KICK, 0])
	assert_true(world.fighters[0].x > world.fighters[1].x, "throw crosses players")
	assert_eq(world.fighters[0].facing, -1, "faces opponent immediately through hitstop")
	assert_eq(world.fighters[1].facing, 1, "opponent faces back")


func test_visible_match_tools_offer_all_five_replacements() -> void:
	var ui := MatchTools.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(ui)
	ui.catalog = ProtoFixture.world_with().fighters[0].limbs.catalog
	ui.open()
	assert_eq(ui.limb.item_count, 3, "three arm choices")
	ui.slot.select(2)
	ui._populate(2)
	assert_eq(ui.limb.item_count, 2, "two leg choices")
	var emitted: Array = []
	ui.replacement_requested.connect(
		func(player: int, slot: String, id: String): emitted.append([player, slot, id])
	)
	ui._apply()
	assert_eq(emitted.size(), 1, "button starts configured new match")
	assert_eq(emitted[0][1], "leg_l", "selected slot")
	ui.free()
