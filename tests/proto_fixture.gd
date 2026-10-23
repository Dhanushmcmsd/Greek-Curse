class_name ProtoFixture
extends RefCounted
## Loads the prototype JSON into a SimWorld. Not a test file.


static func world_with(rules_override: Dictionary = {}, seed_value: int = 1) -> SimWorld:
	var loader := DataLoader.new()
	var rules: Dictionary = _dict(loader, "res://data/rules/match.json").duplicate(true)
	for key in rules_override.keys():
		rules[key] = rules_override[key]
	var curves := _dict(loader, "res://data/balance/stat_curves.json")
	var fighters: Array = [
		_dict(loader, "res://data/fighters/theron.json"),
		_dict(loader, "res://data/fighters/atalanta.json"),
	]
	var moves: Array = [
		_dict(loader, "res://data/moves/jab_of_hermes.json"),
		_dict(loader, "res://data/moves/cyclops_smash.json"),
		_dict(loader, "res://data/moves/pegasus_kick.json"),
		_dict(loader, "res://data/moves/grab.json"),
	]
	var combat := _dict(loader, "res://data/balance/combat.json")
	var limbs := _dict(loader, "res://data/balance/limbs.json")
	return SimWorld.from_data(rules, curves, fighters, moves, combat, seed_value, limbs)


static func move_dict(resource_path: String) -> Dictionary:
	return _dict(DataLoader.new(), resource_path)


static func _dict(loader: DataLoader, resource_path: String) -> Dictionary:
	var result := loader.load_json(resource_path)
	if not result.ok:
		push_error(result.error)
		return {}
	return result.value
