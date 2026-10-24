class_name CareerService
extends RefCounted
var data: Dictionary = {}
var catalog: Dictionary = {}
var limbs: Dictionary = {}
var save: CareerSave = CareerSave.new()


func setup(directory: String = "user://") -> void:
	save.path = directory.path_join("career.json")
	var loader := DataLoader.new()
	for file in DirAccess.get_files_at("res://data/abilities"):
		if file.ends_with(".json"):
			var row: Dictionary = loader.load_json("res://data/abilities/" + file).value
			catalog[row["id"]] = row
	for file in DirAccess.get_files_at("res://data/limbs"):
		if file.ends_with(".json"):
			var row: Dictionary = loader.load_json("res://data/limbs/" + file).value
			limbs[row["id"]] = row
	data = save.load_data()


func create(id: String, name: String, palette: String, created: String) -> String:
	if (
		id not in ["theron", "atalanta", "pyrrhus", "sibyl"]
		or palette not in ["default", "ivory", "night"]
	):
		return "Invalid fighter or palette"
	if not data.get("fighter", {}).is_empty():
		return "Retire your living fighter before creating another."
	var blocked: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/ui/blocked_words.json")
	)
	var checked := NameFilter.clean(name, blocked)
	if not checked["ok"]:
		return checked["error"]
	var config := MatchConfig.new()
	config.fighter_ids = [id, "atalanta"]
	config.loadouts = [Loadout.starter(), Loadout.starter()]
	var world := MatchLauncher.make_world(config)
	var prior := data.duplicate(true)
	data = {
		"version": 2,
		"fighter":
		{
			"id": id,
			"name": checked["name"],
			"palette": palette,
			"created": created,
			"unlocked_abilities": Loadout.STARTER.duplicate(),
			"traded_abilities": [],
			"loadout": Loadout.starter(),
			"win_count": 0,
			"loss_count": 0,
			"limbs": world.fighters[0].limbs.export_state(),
			"ladder_index": 0,
			"offers_state": []
		},
		"chronicle": {"matches": [], "limbs_lost": [], "limbs_taken": [], "longest_combo": 0},
		"fallen": data.get("fallen", []),
		"rng_seed_counter": 1,
		"fresh_body_wins": 0
	}
	return "" if _commit(prior) else "Could not save Career."


func apply_match_result(result: Dictionary, mode: String) -> String:
	if data.get("fighter", {}).is_empty():
		return ""
	var prior := data.duplicate(true)
	var fighter: Dictionary = data["fighter"]
	if mode == "career":
		fighter["limbs"] = result["limbs"].duplicate(true)
		var key := "win_count" if result["won"] else "loss_count"
		fighter[key] += 1
		if result["won"]:
			fighter["ladder_index"] = mini(6, int(fighter["ladder_index"]) + 1)
		Chronicle.record(data["chronicle"], result)
	elif mode == "fresh_body" and result["won"]:
		data["fresh_body_wins"] += 1
	else:
		return ""
	var offer_due: bool = (
		result["won"] and (mode == "career" or int(data["fresh_body_wins"]) % 3 == 0)
	)
	if offer_due and fighter["offers_state"].is_empty():
		fighter["offers_state"] = UnlockOffers.choose(
			catalog,
			fighter["unlocked_abilities"],
			int(fighter["win_count"]),
			int(data["rng_seed_counter"])
		)
		data["rng_seed_counter"] += 1
	return "" if _commit(prior) else "Could not save match result."


func pick_offer(id: String) -> bool:
	var prior := data.duplicate(true)
	var fighter: Dictionary = data["fighter"]
	if id not in fighter["offers_state"]:
		return false
	fighter["unlocked_abilities"].append(id)
	fighter["traded_abilities"].erase(id)
	fighter["offers_state"] = []
	return _commit(prior)


func retire() -> bool:
	var prior := data.duplicate(true)
	if data.get("fighter", {}).is_empty():
		return false
	data["fallen"].append(
		{"fighter": data["fighter"].duplicate(true), "chronicle": data["chronicle"].duplicate(true)}
	)
	data["fighter"] = {}
	return _commit(prior)


func _commit(prior: Dictionary) -> bool:
	if save.save_data(data) == OK:
		return true
	data = prior
	return false
