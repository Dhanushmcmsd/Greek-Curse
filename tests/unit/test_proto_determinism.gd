extends TestBase
## The same input log produces the same hash, including the recorded golden match.


func test_two_runs_match_every_tick() -> void:
	var first := ProtoFixture.world_with()
	var second := ProtoFixture.world_with()
	for tick in 200:
		var inputs := ProtoScript.inputs_at(tick)
		first.step(inputs)
		second.step(inputs)
		assert_eq(first.hash_state(), second.hash_state(), "tick %d" % tick)


func test_golden_final_hash() -> void:
	var world := _play_until_end(ProtoFixture.world_with())
	assert_eq(world.phase, SimWorld.PHASE_MATCH_OVER, "scripted match ends")
	var result := DataLoader.new().load_json("res://tests/golden/proto_match_01.json")
	assert_true(result.ok, result.error)
	if not result.ok:
		return
	assert_eq(str(world.hash_state()), str(result.value["final_hash"]), "golden hash")
	assert_eq(world.wins[0], int(result.value["wins"][0]), "golden wins")


func _play_until_end(world: SimWorld) -> SimWorld:
	var tick := 0
	while world.phase == SimWorld.PHASE_FIGHTING and tick < 5000:
		world.step(ProtoScript.inputs_at(tick))
		tick += 1
	return world
