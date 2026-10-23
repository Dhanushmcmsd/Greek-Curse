extends TestBase
## Zone priority, one zone per swing, and the main/limb split.


func test_head_beats_torso_and_limb_ties_use_order() -> void:
	var order: Array = ["head", "arm_l", "arm_r", "leg_l", "leg_r", "torso"]
	var hit := [0, 0, 100, 100]
	var both: Array = [
		{"name": "torso", "rect": [0, 0, 100, 100]},
		{"name": "head", "rect": [0, 0, 40, 40]},
	]
	assert_eq(SimHitResolver.choose_zone(hit, both, order), "head", "head wins")
	var limbs: Array = [
		{"name": "arm_r", "rect": [0, 0, 80, 80]},
		{"name": "arm_l", "rect": [0, 0, 80, 80]},
	]
	assert_eq(SimHitResolver.choose_zone(hit, limbs, order), "arm_l", "tie uses order")


func test_torso_hit_keeps_full_main_and_skips_integrity() -> void:
	var world := _pair()
	var before := int(world.fighters[1].limbs.integrity["arm_l"])
	_swing(world, SimInput.LIGHT, int(world.moves[0]["startup_ticks"]))
	assert_eq(world.fighters[1].health, 300 - 21, "torso main damage")
	assert_eq(int(world.fighters[1].limbs.integrity["arm_l"]), before, "torso skips limbs")


func test_arm_hit_deals_less_main_and_more_limb() -> void:
	var world := _pair()
	world.fighters[0].power_percent = 100
	world.moves[0]["damage"] = 100
	world.moves[0]["limb_damage"] = 80
	world.moves[0]["startup_ticks"] = 0
	world.moves[0]["hitbox"] = {"x": 0, "y": 1424, "w": 500, "h": 150}
	world.step([SimInput.LIGHT, 0])
	assert_eq(world.fighters[1].health, 250, "half main on a limb")
	assert_eq(int(world.fighters[1].limbs.integrity["arm_l"]), 10, "full limb damage")


func test_multi_hit_interval_lands_twice() -> void:
	var world := _pair()
	world.moves[0]["startup_ticks"] = 0
	world.moves[0]["active_ticks"] = 6
	world.moves[0]["hit_count"] = 2
	world.moves[0]["hit_interval"] = 2
	world.moves[0]["hitstop_attacker"] = 0
	world.moves[0]["hitstop_defender"] = 0
	world.step([SimInput.LIGHT, 0])
	assert_eq(world.fighters[1].health, 279, "first hit of two")
	world.step([0, 0])
	assert_eq(world.fighters[1].health, 279, "interval has not elapsed")
	world.step([0, 0])
	assert_eq(world.fighters[1].health, 258, "second hit")


func _pair() -> SimWorld:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.fighters[0].facing = 1
	world.fighters[1].facing = -1
	return world


func _swing(world: SimWorld, button: int, startup: int) -> void:
	for _i in startup:
		world.step([button, 0])
	world.step([0, 0])
