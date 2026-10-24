class_name CareerSave
extends RefCounted
const VERSION := 2
var path: String = "user://career.json"
var recovery: String = ""


func validate(data: Variant) -> String:
	if (
		not data is Dictionary
		or not data.get("version") is float and not data.get("version") is int
	):
		return "Invalid save object"
	if int(data["version"]) not in [1, 2]:
		return "Unsupported save version"
	for key in ["fighter", "chronicle"]:
		if not data.get(key) is Dictionary:
			return "Invalid " + key
	if (
		not data.get("fallen") is Array
		or not (data.get("rng_seed_counter") is int or data.get("rng_seed_counter") is float)
	):
		return "Invalid archive or seed"
	for key in ["matches", "limbs_lost", "limbs_taken"]:
		if not data["chronicle"].get(key) is Array:
			return "Invalid Chronicle"
	var error := _metadata_error(data)
	return error if error != "" else _fighter_error(data["fighter"])


func _fighter_error(fighter: Dictionary) -> String:
	if fighter.is_empty():
		return ""
	if fighter.get("id", "") not in ["theron", "atalanta", "pyrrhus", "sibyl"]:
		return "Unknown fighter"
	for key in ["unlocked_abilities", "traded_abilities", "offers_state"]:
		if not fighter.get(key) is Array:
			return "Invalid ability pool"
	for key in ["limbs", "loadout"]:
		if not fighter.get(key) is Dictionary:
			return "Invalid " + key
	for key in ["win_count", "loss_count", "ladder_index"]:
		if not (fighter.get(key) is int or fighter.get(key) is float) or int(fighter[key]) < 0:
			return "Invalid counter"
	return _content_error(fighter)


func _content_error(fighter: Dictionary) -> String:
	var seen: Array = []
	var catalog := {}
	for id in fighter["unlocked_abilities"]:
		if id in seen or not FileAccess.file_exists("res://data/abilities/%s.json" % id):
			return "Invalid or duplicate ability"
		seen.append(id)
		catalog[id] = JSON.parse_string(
			FileAccess.get_file_as_string("res://data/abilities/%s.json" % id)
		)
	for id in Loadout.STARTER:
		if id not in seen:
			return "Missing starter ability"
	for slot in SimLimbs.LIMB_NAMES:
		var limb: Variant = fighter["limbs"].get(slot)
		if (
			not limb is Dictionary
			or limb.get("state", "") not in ["healthy", "bruised", "cracked", "severed"]
		):
			return "Invalid limb state"
		var error := _limb_error(slot, limb)
		if error != "":
			return error
	return Loadout.validate(fighter["loadout"], fighter["unlocked_abilities"], catalog)


func migrate(data: Dictionary) -> Dictionary:
	var result: Dictionary = _integers(data)
	if int(result["version"]) == 1:
		result["version"] = 2
		result["fresh_body_wins"] = int(result.get("fresh_body_wins", 0))
	return result


func save_data(data: Dictionary, interrupt_before_rename: bool = false) -> Error:
	if validate(data) != "":
		return ERR_INVALID_DATA
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if interrupt_before_rename:
		return ERR_BUSY
	if FileAccess.file_exists(path):
		var old: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if validate(old) == "":
			var backup := DirAccess.copy_absolute(path, path + ".bak")
			if backup != OK:
				return backup
	return DirAccess.rename_absolute(path + ".tmp", path)


func load_data() -> Dictionary:
	recovery = ""
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if validate(parsed) == "":
		return migrate(parsed)
	var corrupt := path + ".corrupt-" + str(int(Time.get_unix_time_from_system()))
	DirAccess.rename_absolute(path, corrupt)
	if FileAccess.file_exists(path + ".bak"):
		var backup: Variant = JSON.parse_string(FileAccess.get_file_as_string(path + ".bak"))
		if validate(backup) == "":
			recovery = "Recovered previous backup. Damaged file preserved: " + corrupt
			return migrate(backup)
	recovery = "No valid save. Damaged file preserved: " + corrupt
	return {}


func _integers(value: Variant) -> Variant:
	if value is float:
		return int(value)
	if value is Dictionary:
		var result := {}
		for key in value:
			result[key] = _integers(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(_integers(item))
		return result
	return value


func _metadata_error(data: Dictionary) -> String:
	var fighter: Dictionary = data["fighter"]
	if not fighter.is_empty():
		if not fighter.get("name") is String or not fighter.get("created") is String:
			return "Missing fighter identity"
		if fighter.get("palette", "") not in ["default", "ivory", "night"]:
			return "Invalid palette"
	if not _is_count(data["chronicle"].get("longest_combo")):
		return "Invalid Chronicle combo"
	if int(data["version"]) == 2 and not _is_count(data.get("fresh_body_wins")):
		return "Invalid Fresh Body counter"
	for record in data["chronicle"]["matches"]:
		if (
			not record is Dictionary
			or not record.get("date") is String
			or not record.get("opponent") is String
			or not record.get("won") is bool
			or not record.get("rounds") is Array
		):
			return "Invalid match history"
	return ""


func _is_count(value: Variant) -> bool:
	return (
		(value is int or value is float)
		and is_finite(float(value))
		and float(value) >= 0
		and float(value) == floor(float(value))
	)


func _limb_error(slot: String, limb: Dictionary) -> String:
	if not _is_count(limb.get("integrity")) or not _is_count(limb.get("max_integrity")):
		return "Invalid limb integrity"
	if int(limb["max_integrity"]) == 0 or int(limb["integrity"]) > int(limb["max_integrity"]):
		return "Invalid limb maximum"
	if not limb.get("regrown_id") is String:
		return "Invalid replacement id"
	if limb["regrown_id"] != "":
		var path := "res://data/limbs/%s.json" % limb["regrown_id"]
		if not FileAccess.file_exists(path):
			return "Unknown replacement"
		var row: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not slot.begins_with(row["slot"]):
			return "Incompatible replacement"
	return ""
