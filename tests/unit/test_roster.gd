extends TestBase


func test_body_stats_and_cosmetic_neutrality() -> void:
	var loader := DataLoader.new()
	var curves: Dictionary = loader.load_json("res://data/balance/stat_curves.json").value
	var row: Dictionary = loader.load_json("res://data/fighters/theron.json").value
	var stats := SimBodyStats.derive(row, curves)
	assert_eq(stats["speed"], 18, "22 at 84 percent")
	assert_eq(stats["power"], 133, "muscle delta once")
	assert_eq(stats["knockback_percent"], 75, "mass resistance")
	var cosmetic: Dictionary = row.duplicate(true)
	cosmetic["body"]["cloth_color"] = [0, 0, 0]
	cosmetic["body"]["costume"] = "oracle"
	cosmetic["gender"] = "other"
	assert_eq(SimBodyStats.derive(cosmetic, curves), stats, "cosmetics never affect combat")


func test_mirror_palette_and_names() -> void:
	var config := MatchConfig.new()
	config.fighter_ids = ["theron", "theron"]
	assert_eq(config.resolved_palettes(), ["default", "ivory"], "distinct mirror palettes")
	assert_eq(NameFilter.clean("  The  Hero  ", [])["name"], "The Hero", "trim whitespace")
	assert_true(NameFilter.clean("Étoile", [])["ok"], "accented letters")
	assert_false(NameFilter.clean("badname", ["bad"])["ok"], "local blocked list")
	assert_false(NameFilter.clean("<script>", [])["ok"], "unsupported symbols")
	assert_false(NameFilter.clean("", [])["ok"], "empty")


func test_ladder_ramp_and_loadouts() -> void:
	var ladder: Array = DataLoader.new().load_json("res://data/ladder/career_ladder.json").value
	var previous := 0
	var world := MatchLauncher.make_world(MatchConfig.new())
	assert_eq(ladder.size(), 6, "six trials")
	for row in ladder:
		var difficulty: int = ["easy", "normal", "hard"].find(row["difficulty"])
		assert_true(difficulty >= previous, "monotonic difficulty")
		previous = difficulty
		assert_eq(
			Loadout.validate(
				Loadout.full(row["loadout_index"]), world.abilities.keys(), world.abilities
			),
			"",
			"ladder loadout"
		)
