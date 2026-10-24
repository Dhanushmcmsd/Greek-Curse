class_name Loadout
extends RefCounted
const STARTER := ["jab_of_hermes", "cyclops_smash", "pegasus_kick"]
const COUNTS := {"light": 2, "heavy": 2, "kick": 2, "superpower": 1, "passive": 1, "ultimate": 1}


static func validate(slots: Dictionary, unlocked: Array, catalog: Dictionary) -> String:
	var seen: Array = []
	for kind in slots:
		if (
			not COUNTS.has(kind)
			or not slots[kind] is Array
			or slots[kind].size() > int(COUNTS[kind])
		):
			return "Invalid slot count"
		for id in slots[kind]:
			if (
				id in seen
				or id not in unlocked
				or not catalog.has(id)
				or catalog[id]["type"] != kind
			):
				return "Invalid or locked ability: " + str(id)
			seen.append(id)
	return ""


static func starter() -> Dictionary:
	return {"light": [STARTER[0]], "heavy": [STARTER[1]], "kick": [STARTER[2]]}


static func full(index: int = 0) -> Dictionary:
	return {
		"light": ["jab_of_hermes", "spartan_cross" if index % 2 == 0 else "quick_fury"],
		"heavy": ["cyclops_smash", "gorgon_backfist" if index % 2 == 0 else "minotaur_haymaker"],
		"kick": ["pegasus_kick", "achilles_heel_snap"],
		"superpower":
		[["zeus_bolt", "hermes_dash", "ares_rage", "hephaestus_forge_shield"][index % 4]],
		"passive": [["iron_skin", "blood_frenzy", "stoneheart"][index % 3]],
		"ultimate": ["zeus_wrath" if index % 2 == 0 else "olympian_barrage"]
	}
