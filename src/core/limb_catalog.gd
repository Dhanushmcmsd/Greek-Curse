class_name LimbCatalog
extends RefCounted


static func install(world: SimWorld) -> void:
	var catalog := {}
	var loader := DataLoader.new()
	for file in DirAccess.get_files_at("res://data/limbs"):
		if file.ends_with(".json"):
			var result := loader.load_json("res://data/limbs/" + file)
			if result.ok:
				catalog[result.value["id"]] = result.value
	for fighter in world.fighters:
		fighter.limbs.catalog = catalog
