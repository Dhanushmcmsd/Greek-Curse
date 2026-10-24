extends TestBase


func _grant(world: SimWorld, slot: String, id: String) -> SimFighter:
	var fighter := world.fighters[0]
	fighter.limbs.parts[slot].state = "severed"
	fighter.limbs.parts[slot].integrity = 0
	fighter.limbs.integrity[slot] = 0
	assert_true(fighter.limbs.regrow(slot, id), "regrow valid")
	return fighter


func test_regrow_requires_missing_compatible_slot_and_eighty_percent() -> void:
	var world := ProtoFixture.world_with()
	assert_true(
		not world.fighters[0].limbs.regrow("arm_l", "rubber_chicken_arm"), "healthy invalid"
	)
	var fighter := _grant(world, "arm_l", "rubber_chicken_arm")
	assert_eq(fighter.limbs.parts["arm_l"].integrity, 112, "80 percent of 140")
	fighter.limbs.parts["leg_l"].state = "severed"
	assert_true(not fighter.limbs.regrow("leg_l", "rubber_chicken_arm"), "wrong slot")
	assert_eq(fighter.modifiers.size(), 1, "modifier registered")


func test_chicken_reach_and_missed_heavy_stagger() -> void:
	var world := ProtoFixture.world_with()
	var fighter := _grant(world, "arm_l", "rubber_chicken_arm")
	world.step([16, 0])
	assert_eq(fighter.hit_x + fighter.hit_w, 780, "600 times 130 percent")
	world = ProtoFixture.world_with()
	fighter = _grant(world, "arm_l", "rubber_chicken_arm")
	world.step([32, 0])
	for tick in 100:
		if fighter.state == SimFighter.State.STAGGER:
			break
		world.step([0, 0])
	assert_eq(fighter.state, SimFighter.State.STAGGER, "whiff self-stagger")
	assert_eq(fighter.state_tick, 18, "exact duration")


func test_giant_hand_heavy_damage_and_larger_hurtbox() -> void:
	var world := ProtoFixture.world_with()
	var fighter := world.fighters[0]
	var before := fighter.limbs.world_boxes(0, 0, 500, 2050, "standing")
	_grant(world, "arm_l", "cyclops_giant_hand")
	var after := fighter.limbs.world_boxes(0, 0, 500, 2050, "standing")
	assert_eq(int(after[3]["rect"][2]), Fx.percent(int(before[3]["rect"][2]), 140), "wider arm")
	world.step([32, 0])
	assert_eq(
		fighter.attack_damage,
		Fx.percent(Fx.percent(int(world.moves[1]["damage"]), 130), 140),
		"heavy benefit"
	)


func test_marble_durability_damage_and_speed() -> void:
	var world := ProtoFixture.world_with()
	var fighter := _grant(world, "leg_l", "marble_statue_leg")
	assert_eq(fighter.limbs.parts["leg_l"].max_integrity, 210, "150 percent maximum")
	assert_eq(fighter.limbs.parts["leg_l"].integrity, 112, "80 percent of normal maximum")
	var start := fighter.x
	world.step([1, 0])
	assert_eq(start - fighter.x, 18, "speed 22 times 80 percent rounded")
	world.step([64, 0])
	assert_eq(
		fighter.attack_damage,
		Fx.percent(Fx.percent(int(world.moves[2]["damage"]), 130), 125),
		"heavier kick"
	)


func test_hermes_speed_dash_and_seeded_zoom() -> void:
	var world := ProtoFixture.world_with()
	var fighter := _grant(world, "leg_l", "hermes_sandal_leg")
	var start := fighter.x
	world.step([1, 0])
	assert_eq(start - fighter.x, 28, "125 percent rounded")
	start = fighter.x
	world.step([1 | 256, 0])
	assert_eq(start - fighter.x, 220, "40 normal dodge plus 180 dash")
	var a := ProtoFixture.world_with()
	var b := ProtoFixture.world_with()
	for item in [a, b]:
		_grant(item, "leg_l", "hermes_sandal_leg")
		item.fighters[0].limbs.catalog["hermes_sandal_leg"]["modifiers"]["zoom_chance"] = 100
		item.tick = 179
	var events := a.step([1, 0])
	b.step([1, 0])
	assert_eq(a.hash_state(), b.hash_state(), "seeded zoom")
	assert_eq(events[0].payload["quirk"], "zoom", "zoom event")


func test_claw_chip_hold_and_seeded_whiff() -> void:
	var world := ProtoFixture.world_with()
	var fighter := _grant(world, "arm_l", "crab_claw_arm")
	world.step([80, 0])
	assert_eq(fighter.attack_damage, 46, "double chip")
	fighter.limbs.catalog["crab_claw_arm"]["modifiers"]["grab_whiff_chance"] = 100
	fighter.attack_category = "grab"
	fighter.landed_hit = false
	assert_eq(SimRegrown.whiff(world, fighter), 30, "seeded pinch at guaranteed chance")
	fighter.landed_hit = true
	assert_eq(SimRegrown.whiff(world, fighter), 0, "landed grab never pinches")
	assert_eq(SimRegrown.effects(fighter, "arm_l")["grab_hold_ticks"], 30, "hold configured")
	var contact := ProtoFixture.world_with()
	_grant(contact, "arm_l", "crab_claw_arm")
	contact.fighters[0].x = 0
	contact.fighters[1].x = 430
	contact.moves[3]["startup_ticks"] = 0
	contact.moves[3]["hitstop_attacker"] = 0
	contact.step([SimInput.LIGHT | SimInput.KICK, SimInput.BLOCK])
	assert_eq(contact.fighters[1].state, SimFighter.State.GRABBED, "pincer lands through block")
	assert_eq(contact.fighters[1].state_tick, 30, "actual pincer hold")
	assert_eq(contact.fighters[1].health, 277, "actual pincer damage through block")


func test_resever_removes_modifier_and_preserves_credit_limit() -> void:
	var world := ProtoFixture.world_with()
	for i in 4:
		SimSeverance.hit(world, 0, 1, "arm_l", 50, [])
	assert_eq(world.amputations.size(), 1, "natural credit")
	assert_true(world.fighters[0].limbs.regrow("arm_l", "cyclops_giant_hand"), "regrows")
	for i in 4:
		SimSeverance.hit(world, 0, 1, "arm_l", 50, [])
	assert_eq(world.amputations.size(), 1, "no second credit")
	assert_eq(world.fighters[0].limbs.parts["arm_l"].state, "severed", "replacement severed")
	for modifier in world.fighters[0].modifiers:
		assert_true(modifier.id != "regrown:arm_l", "modifier removed")
