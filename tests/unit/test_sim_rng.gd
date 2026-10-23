extends TestBase

const GOLDEN_SEED_1: Array[int] = [
	270369,
	67634689,
	2647435461,
	307599695,
	2398689233,
	745495504,
	632435482,
	435756210,
	2005365029,
	2916098932,
	2657092299,
	1495045943,
	3031976842,
	82049198,
	87470069,
	3385103793,
	891394312,
	3323190024,
	321008529,
	4283899417,
]


func test_seed_one_matches_golden_sequence() -> void:
	var rng := SimRng.new(1)
	for index in GOLDEN_SEED_1.size():
		assert_eq(rng.next_u32(), GOLDEN_SEED_1[index], "draw %d" % index)


func test_state_round_trip_repeats_the_sequence() -> void:
	var rng := SimRng.new(99)
	for _i in 5:
		rng.next_u32()
	var saved := rng.get_state()
	var upcoming: Array[int] = []
	for _j in 5:
		upcoming.append(rng.next_u32())
	rng.set_state(saved)
	for index in upcoming.size():
		assert_eq(rng.next_u32(), upcoming[index], "restored draw %d" % index)


func test_outputs_stay_inside_32_bits() -> void:
	var rng := SimRng.new(0x1FFFFFFFF)
	assert_eq(rng.get_state(), 0xFFFFFFFF, "high bits stripped from seed")
	for _i in 1000:
		var draw := rng.next_u32()
		assert_true(draw >= 0, "non-negative")
		assert_true(draw <= 0xFFFFFFFF, "32-bit mask")
		assert_eq(draw & 0xFFFFFFFF, draw, "mask is a no-op")


func test_zero_seed_becomes_one() -> void:
	var rng := SimRng.new(0)
	assert_eq(rng.get_state(), 1, "zero seed")
	assert_eq(rng.next_u32(), GOLDEN_SEED_1[0], "same first draw as seed 1")


func test_range_stays_inside_bounds() -> void:
	var rng := SimRng.new(7)
	for _i in 100000:
		var draw := rng.range_i(-3, 5)
		assert_true(draw >= -3 and draw < 5, "range %d" % draw)
	assert_eq(rng.range_i(4, 4), 4, "empty span")


func test_chance_edges_do_not_consume_state() -> void:
	var rng := SimRng.new(3)
	var before := rng.get_state()
	assert_false(rng.chance_percent(0), "zero percent")
	assert_true(rng.chance_percent(100), "full percent")
	assert_eq(rng.get_state(), before, "state unchanged")
	var rolled := rng.chance_percent(50)
	assert_true(rolled == true or rolled == false, "chance returns a bool")
