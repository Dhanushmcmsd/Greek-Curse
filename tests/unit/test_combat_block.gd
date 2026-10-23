extends TestBase
## Block keeps 30 percent of main damage and chips 25 percent of limb damage.


func test_block_reduction_and_chip_are_exact() -> void:
	var world := _pair()
	world.fighters[0].power_percent = 100
	world.moves[0]["damage"] = 100
	world.moves[0]["limb_damage"] = 80
	world.moves[0]["startup_ticks"] = 0
	world.moves[0]["hitbox"] = {"x": 0, "y": 1100, "w": 500, "h": 150}
	world.step([SimInput.LIGHT, SimInput.BLOCK])
	assert_eq(world.fighters[1].health, 285, "30 percent of the limb main hit")
	assert_eq(int(world.fighters[1].limbs.integrity["arm_l"]), 70, "25 percent chip")
	assert_eq(world.fighters[1].state, SimFighter.State.BLOCKSTUN, "blockstun")


func test_empty_stamina_on_block_staggers() -> void:
	var world := _pair()
	world.fighters[1].stamina = 0
	world.step([0, SimInput.BLOCK])
	assert_eq(world.fighters[1].state, SimFighter.State.STAGGER, "guard break")


func test_stamina_regenerates_one_per_idle_tick() -> void:
	var world := _pair()
	world.fighters[0].stamina = 40
	world.step([0, 0])
	assert_eq(world.fighters[0].stamina, 41, "regen")


func _pair() -> SimWorld:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 430
	world.fighters[0].facing = 1
	world.fighters[1].facing = -1
	return world
