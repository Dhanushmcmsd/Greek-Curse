extends TestBase


func test_severance_replay_matches() -> void:
	assert_eq(
		ReplayCheck.verify("res://tests/golden/severance_01.replay.json"), "", "severance replay"
	)


## The stored prototype replay still reaches the same hashes.


func test_prototype_replay_matches() -> void:
	var error := ReplayCheck.verify("res://tests/golden/proto_match_01.replay.json")
	assert_eq(error, "", error)
