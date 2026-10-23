extends TestBase
## Stamina, dodge i-frames, and grab versus block or dodge.


func test_empty_bar_refuses_the_attack_and_staggers() -> void:
	var world := _pair()
	world.fighters[0].stamina = 0
	world.step([SimInput.LIGHT, 0])
	assert_eq(world.fighters[0].state, SimFighter.State.STAGGER, "no attack on empty")
	assert_eq(world.fighters[1].health, 300, "no damage")


func test_dodge_iframes_cover_the_data_range() -> void:
	var world := _pair()
	world.moves[0]["hitstop_attacker"] = 0
	world.moves[0]["hitstop_defender"] = 0
	world.step([0, SimInput.DODGE])
	assert_eq(world.fighters[1].state_tick, 1, "first dodge tick is inside the window")
	_arm_active(world.fighters[0])
	world.step([0, 0])
	assert_eq(world.fighters[1].health, 300, "iframe misses")
	while world.fighters[1].state == SimFighter.State.DODGE:
		world.step([0, 0])
	_arm_active(world.fighters[0])
	world.step([0, 0])
	assert_true(world.fighters[1].health < 300, "hit lands after the window")


func test_grab_beats_block_and_loses_to_dodge() -> void:
	var blocked := _pair()
	blocked.moves[3]["startup_ticks"] = 0
	blocked.moves[3]["hitstop_attacker"] = 0
	blocked.step([SimInput.LIGHT | SimInput.KICK, SimInput.BLOCK])
	assert_eq(blocked.fighters[1].health, 300 - 12, "grab ignores block")
	assert_true(blocked.fighters[0].x > blocked.fighters[1].x, "throw swaps positions")
	var dodged := _pair()
	dodged.moves[3]["startup_ticks"] = 0
	dodged.moves[3]["hitstop_attacker"] = 0
	dodged.step([0, SimInput.DODGE])
	dodged.step([SimInput.LIGHT | SimInput.KICK, 0])
	assert_eq(dodged.fighters[1].health, 300, "grab misses i-frames")


func _pair() -> SimWorld:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.fighters[0].facing = 1
	world.fighters[1].facing = -1
	return world


func _arm_active(fighter: SimFighter) -> void:
	fighter.state = SimFighter.State.ACTIVE
	fighter.move_age = 5
	fighter.startup_ticks = 1
	fighter.active_ticks = 8
	fighter.recovery_ticks = 4
	fighter.attack_hit_count = 1
	fighter.hits_done = 0
	fighter.has_hit = false
	fighter.next_hit_age = 0
	fighter.attack_damage = 30
	fighter.attack_limb_damage = 10
	fighter.attack_hitstun = 4
	fighter.hit_x = 0
	fighter.hit_y = 1100
	fighter.hit_w = 500
	fighter.hit_h = 150
