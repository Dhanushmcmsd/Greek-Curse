extends TestBase
## Lane movement, bounds, and push-apart for the stage 05 simulation.


func test_walk_speed_matches_the_curve() -> void:
	var world := ProtoFixture.world_with()
	var theron := world.fighters[0]
	var before := theron.x
	world.fighters[1].x = 2000
	world.step([SimInput.RIGHT, 0])
	assert_eq(theron.x, before + theron.walk_speed, "theron speed")
	assert_eq(theron.walk_speed, 22, "speed stat 2")
	assert_eq(world.fighters[1].walk_speed, 46, "speed stat 5")


func test_bodies_stay_inside_the_arena() -> void:
	var world := ProtoFixture.world_with()
	var theron := world.fighters[0]
	theron.x = world.arena_max_x
	world.fighters[1].x = world.arena_min_x
	world.step([SimInput.RIGHT, SimInput.LEFT])
	assert_true(theron.x <= world.arena_max_x - theron.half_width(), "right bound")
	var atalanta := world.fighters[1]
	assert_true(atalanta.x >= world.arena_min_x + atalanta.half_width(), "left bound")


func test_push_apart_removes_overlap() -> void:
	var world := ProtoFixture.world_with()
	world.fighters[0].x = 0
	world.fighters[1].x = 0
	world.step([0, 0])
	assert_false(_overlaps(world), "stacked bodies")
	world.fighters[0].x = world.arena_max_x
	world.fighters[1].x = world.arena_max_x
	world.step([0, 0])
	assert_false(_overlaps(world), "wall bodies")
	assert_true(world.fighters[0].x <= world._high(world.fighters[0]), "still inside")
	assert_true(world.fighters[1].x <= world._high(world.fighters[1]), "partner inside")


func _overlaps(world: SimWorld) -> bool:
	var left := world.fighters[0]
	var right := world.fighters[1]
	if left.x > right.x:
		var swap := left
		left = right
		right = swap
	return right.x - left.x < left.half_width() + right.half_width()
