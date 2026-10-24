class_name ContentCheck
extends RefCounted


static func verify() -> String:
	for folder in ["fighters", "arenas", "abilities", "limbs"]:
		var count := 0
		for file in DirAccess.get_files_at("res://data/" + folder):
			if not file.ends_with(".json"):
				continue
			count += 1
			var result := DataLoader.new().load_json("res://data/" + folder + "/" + file)
			if not result.ok:
				return result.error
			var prefix: String = {"fighters": "fighter_", "arenas": "arena_", "limbs": "limb_"}.get(
				folder, ""
			)
			if (
				prefix != ""
				and not ResourceLoader.exists(
					"res://assets/generated/models/" + prefix + file.get_basename() + ".glb"
				)
			):
				return "Missing model: " + prefix + file.get_basename()
		if count != int({"fighters": 4, "arenas": 3, "abilities": 21, "limbs": 5}[folder]):
			return "Incomplete content directory: " + folder
	return ""
