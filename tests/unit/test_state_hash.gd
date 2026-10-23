extends TestBase

const STREAM_LO := 1577918213
const STREAM_HI := 3660315426


func test_same_stream_matches_golden_fnv() -> void:
	var hash := StateHash.hash_ints([1, 2, 3])
	assert_eq(hash & 0xFFFFFFFF, STREAM_LO, "low 32")
	assert_eq((hash >> 32) & 0xFFFFFFFF, STREAM_HI, "high 32")
	assert_eq(StateHash.hash_ints([1, 2, 3]), hash, "repeat")


func test_order_changes_the_hash() -> void:
	assert_true(StateHash.hash_ints([1, 2, 3]) != StateHash.hash_ints([3, 2, 1]), "order")


func test_empty_stream_is_the_offset_basis() -> void:
	var hash := StateHash.hash_ints([])
	assert_eq(hash & 0xFFFFFFFF, 0x84222325, "offset low")
	assert_eq((hash >> 32) & 0xFFFFFFFF, 0xCBF29CE4, "offset high")


func test_negative_one_is_not_zero() -> void:
	assert_true(StateHash.hash_ints([-1]) != StateHash.hash_ints([0]), "sign bits")
