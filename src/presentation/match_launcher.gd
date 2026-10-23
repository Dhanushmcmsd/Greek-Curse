class_name MatchLauncher
extends RefCounted
## Config-to-world boundary used by menus, controllers, and headless tools.


static func make_world(config: MatchConfig) -> SimWorld:
	if config.validate() != "":
		push_error(config.validate())
		return null
	var loader := DataLoader.new()
	var rules: Dictionary = loader.load_json("res://data/rules/match.json").value.duplicate(true)
	rules.merge(config.rules, true)
	var fighters: Array = []
	for id in config.fighter_ids:
		fighters.append(loader.load_json("res://data/fighters/%s.json" % id).value)
	var moves: Array = []
	for id in ["jab_of_hermes", "cyclops_smash", "pegasus_kick", "grab"]:
		moves.append(loader.load_json("res://data/moves/%s.json" % id).value)
	for file in DirAccess.get_files_at("res://data/moves"):
		if file.begins_with("body_") and file.ends_with(".json"):
			moves.append(loader.load_json("res://data/moves/" + file).value)
	var world := SimWorld.from_data(
		rules,
		loader.load_json("res://data/balance/stat_curves.json").value,
		fighters,
		moves,
		loader.load_json("res://data/balance/combat.json").value,
		config.seed,
		loader.load_json("res://data/balance/limbs.json").value
	)
	world.body_rules = loader.load_json("res://data/balance/body_states.json").value
	return world


static func make_ai(difficulty: String, seed: int, archetype: String = "balanced") -> FighterAI:
	var loader := DataLoader.new()
	var controller := FighterAI.new()
	controller.setup(
		loader.load_json("res://data/ai/difficulty.json").value[difficulty],
		loader.load_json("res://data/ai/archetypes.json").value[archetype],
		seed
	)
	return controller
