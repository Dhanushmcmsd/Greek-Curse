extends TestBase


func test_most_damage_then_lowest_attacker_id() -> void:
	var chain := ChainRecord.new()
	chain.note(0, 90, "arm_l", 20, 8)
	chain.note(1, 90, "arm_l", 40, 3)
	chain.note(2, 90, "arm_l", 20, 8)
	assert_eq(chain.credit_for("arm_l", 9), 3, "equal contribution lowest id wins")
	chain.note(3, 90, "arm_l", 1, 8)
	assert_eq(chain.credit_for("arm_l", 9), 8, "largest contribution wins")
	chain.note(94, 90, "arm_l", 2, 7)
	assert_eq(chain.credit_for("arm_l", 9), 7, "old chain contributions cleared")


func test_credit_once_per_limb() -> void:
	var world := ProtoFixture.world_with()
	for i in 8:
		SimSeverance.hit(world, 1, 0, "arm_l", 40, [])
	assert_eq(world.amputations.size(), 1, "one credit")
	assert_eq(world.amputations[0]["attacker"], 0, "attacker recorded")
	assert_eq(world.amputations[0]["chain_hits"], 3, "chain recorded")
