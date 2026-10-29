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
			if prefix != "":
				var basename: String = file.get_basename()
				var model_id: String = basename
				# For fighters, check the model_id field from JSON (may differ from filename)
				if folder == "fighters" and result.value is Dictionary:
					model_id = str(result.value.get("model_id", basename))
				var generated_path := "res://assets/generated/models/" + prefix + basename + ".glb"
				var mixamo_path := "res://assets/fighters_mixamo/" + prefix + model_id + ".glb"
				if (
					not ResourceLoader.exists(generated_path)
					and not FileAccess.file_exists(mixamo_path)
					and not ResourceLoader.exists(mixamo_path)
				):
					return "Missing model: " + prefix + basename
		if count != int({"fighters": 5, "arenas": 3, "abilities": 21, "limbs": 5}[folder]):
			return "Incomplete content directory: " + folder
	return ""
