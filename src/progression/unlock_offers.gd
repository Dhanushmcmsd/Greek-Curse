class_name UnlockOffers
extends RefCounted


static func choose(catalog: Dictionary, unlocked: Array, win: int, seed: int) -> Array:
	var pool: Array = []
	var result: Array = []
	var rng := SimRng.new(seed)
	for id in catalog:
		if id not in unlocked and id not in Loadout.STARTER:
			pool.append(id)
	pool.sort()
	var guaranteed: String = {1: "superpower", 3: "passive", 5: "ultimate"}.get(win, "")
	if guaranteed != "":
		var candidates := pool.filter(func(id): return catalog[id]["type"] == guaranteed)
		if not candidates.is_empty():
			var selected: String = candidates[rng.range_i(0, candidates.size())]
			result.append(selected)
			pool.erase(selected)
	while result.size() < 3 and not pool.is_empty():
		var index := rng.range_i(0, pool.size())
		result.append(pool[index])
		pool.remove_at(index)
	return result
