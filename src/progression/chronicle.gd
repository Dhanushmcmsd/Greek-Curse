class_name Chronicle
extends RefCounted


static func record(chronicle: Dictionary, result: Dictionary) -> void:
	chronicle["matches"].append(result.duplicate(true))
	chronicle["longest_combo"] = maxi(int(chronicle["longest_combo"]), int(result.get("combo", 0)))
	for credit in result.get("amputations", []):
		chronicle["limbs_lost" if int(credit["victim"]) == 0 else "limbs_taken"].append(
			credit.duplicate(true)
		)
