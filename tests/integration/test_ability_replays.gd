extends TestBase


func test_all_ability_replays_match() -> void:
	for file in DirAccess.get_files_at("res://tests/golden"):
		if file.begins_with("ability_") and file.ends_with(".replay.json"):
			assert_eq(ReplayCheck.verify("res://tests/golden/" + file), "", file)
