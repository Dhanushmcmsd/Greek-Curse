extends TestBase


func test_regrown_replays_match() -> void:
	for id in [
		"rubber_chicken_arm",
		"cyclops_giant_hand",
		"crab_claw_arm",
		"marble_statue_leg",
		"hermes_sandal_leg"
	]:
		assert_eq(ReplayCheck.verify("res://tests/golden/regrown_%s.replay.json" % id), "", id)


func test_severance_replay_matches() -> void:
	assert_eq(
		ReplayCheck.verify("res://tests/golden/severance_01.replay.json"), "", "severance replay"
	)


func test_body_state_replays_match() -> void:
	for mask in 16:
		assert_eq(
			ReplayCheck.verify("res://tests/golden/body_%02d.replay.json" % mask),
			"",
			"body replay %d" % mask
		)


## The stored prototype replay still reaches the same hashes.


func test_prototype_replay_matches() -> void:
	var error := ReplayCheck.verify("res://tests/golden/proto_match_01.replay.json")
	assert_eq(error, "", error)
