class_name ObolTrade
extends RefCounted


static func options(
	fighter: Dictionary, slot: String, ability: String, catalog: Dictionary, seed: int
) -> Array:
	if (
		not fighter["limbs"].has(slot)
		or fighter["limbs"][slot]["state"] != "severed"
		or ability in Loadout.STARTER
		or ability not in fighter["unlocked_abilities"]
	):
		return []
	var pool: Array = []
	for id in catalog:
		if slot.begins_with(str(catalog[id]["slot"])):
			pool.append(id)
	pool.sort()
	var rng := SimRng.new(seed)
	var result: Array = []
	while not pool.is_empty() and result.size() < 3:
		var index := rng.range_i(0, pool.size())
		result.append(pool[index])
		pool.remove_at(index)
	return result


static func accept(
	fighter: Dictionary,
	slot: String,
	ability: String,
	limb_id: String,
	catalog: Dictionary,
	normal_integrity: int,
	seed: int
) -> bool:
	if limb_id not in options(fighter, slot, ability, catalog, seed):
		return false
	fighter["unlocked_abilities"].erase(ability)
	if ability not in fighter["traded_abilities"]:
		fighter["traded_abilities"].append(ability)
	for category in fighter["loadout"]:
		fighter["loadout"][category].erase(ability)
	var row: Dictionary = fighter["limbs"][slot]
	row["integrity"] = Fx.percent(normal_integrity, 80)
	row["max_integrity"] = Fx.percent(
		normal_integrity, int(catalog[limb_id]["modifiers"].get("integrity_max_percent", 100))
	)
	row["state"] = "healthy" if row["integrity"] * 100 / row["max_integrity"] > 50 else "bruised"
	row["regrown_id"] = limb_id
	row["zero_pending"] = false
	return true
