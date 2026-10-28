class_name MatchLauncher
extends RefCounted
## Config-to-world boundary used by menus, controllers, and headless tools.


static func make_world(config: MatchConfig) -> SimWorld:
	if config.validate() != "":
		push_error(config.validate())
		return null
	var loader := DataLoader.new()
	var rules: Dictionary = loader.load_json("res://data/rules/match.json").value.duplicate(true)
	var arena: Dictionary = loader.load_json("res://data/arenas/%s.json" % config.arena_id).value
	rules["arena_min_x"] = int(arena["bounds"][0])
	rules["arena_max_x"] = int(arena["bounds"][1])
	rules["spawn_x"] = arena["spawn_x"]
	rules.merge(config.rules, true)
	rules["match_mode"] = true
	var fighters: Array = []
	for id in config.fighter_ids:
		var row: Dictionary = loader.load_json("res://data/fighters/%s.json" % id).value.duplicate(
			true
		)
		row["height_mm"] = 1800
		fighters.append(row)
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
	for index in world.fighters.size():
		SimBodyStats.apply(
			world.fighters[index],
			SimBodyStats.derive(
				fighters[index], loader.load_json("res://data/balance/stat_curves.json").value
			)
		)
	world.body_rules = loader.load_json("res://data/balance/body_states.json").value
	SimHazards.configure(
		world, arena, bool(config.rules.get("hazards", arena["hazards_default_on"])), config.seed
	)
	LimbCatalog.install(world)
	world.limb_rules["match_mode"] = true
	world.combat["edge_attacks"] = true
	_install_abilities(world, config, loader)
	world.setup({"initial_limb_states": config.initial_limbs})
	for index in mini(config.initial_limbs.size(), world.fighters.size()):
		var fighter := world.fighters[index]
		for slot in SimLimbs.LIMB_NAMES:
			var limb: SimLimb = fighter.limbs.parts[slot]
			var effect := SimRegrown.effects(fighter, slot)
			var maximum := Fx.percent(
				fighter.limbs.max_integrity, int(effect.get("integrity_max_percent", 100))
			)
			limb.integrity = Fx.mul_div(limb.integrity, maximum, maxi(1, limb.max_integrity))
			limb.max_integrity = maximum
			limb.refresh(world.limb_rules)
			fighter.limbs.integrity[slot] = limb.integrity
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


static func _install_abilities(world: SimWorld, config: MatchConfig, loader: DataLoader) -> void:
	for file in DirAccess.get_files_at("res://data/abilities"):
		if not file.ends_with(".json"):
			continue
		var row: Dictionary = loader.load_json("res://data/abilities/" + file).value
		world.abilities[row["id"]] = row
		if row["move_id"] != "":
			var exists := false
			for move in world.moves:
				if move["id"] == row["move_id"]:
					exists = true
			if not exists:
				world.moves.append(
					loader.load_json("res://data/moves/%s.json" % row["move_id"]).value
				)
	# Directional combo commands are available regardless of equipped basic attacks.
	for file in DirAccess.get_files_at("res://data/moves"):
		if not file.ends_with(".json"):
			continue
		var row: Dictionary = loader.load_json("res://data/moves/" + file).value
		var exists := false
		for move in world.moves:
			exists = exists or move["id"] == row["id"]
		if not exists:
			world.moves.append(row)
	for index in world.fighters.size():
		var fighter := world.fighters[index]
		var selected: Dictionary = (
			config.loadouts[index]
			if index < config.loadouts.size()
			else Loadout.full(["theron", "atalanta", "pyrrhus", "sibyl"].find(fighter.fighter_id))
		)
		var error := Loadout.validate(selected, world.abilities.keys(), world.abilities)
		if error != "":
			Log.error("loadout", error)
			selected = Loadout.starter()
		fighter.loadout = selected.duplicate(true)
		SimAbilities.passive(world, fighter)
