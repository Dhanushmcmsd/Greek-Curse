class_name SimLimb
extends RefCounted
## The four integrity states. Zero attached integrity remains cracked.

var integrity: int = 100
var max_integrity: int = 100
var state: String = "healthy"
var zero_pending: bool = false
var credited: bool = false
var cap_blocked: bool = false
var regrown_id: String = ""


func refresh(rules: Dictionary) -> void:
	if state == "severed":
		integrity = 0
		return
	integrity = clampi(integrity, 0, max_integrity)
	var percent := integrity * 100 / maxi(1, max_integrity)
	if percent > int(rules.get("healthy_above", 50)):
		state = "healthy"
	elif percent >= int(rules.get("bruised_min", 26)):
		state = "bruised"
	else:
		state = "cracked"


func export_state() -> Dictionary:
	return {
		"integrity": integrity,
		"max_integrity": max_integrity,
		"state": state,
		"zero_pending": zero_pending,
		"credited": credited,
		"cap_blocked": cap_blocked,
		"regrown_id": regrown_id
	}


func hash_values() -> Array:
	return [
		integrity,
		max_integrity,
		["healthy", "bruised", "cracked", "severed"].find(state),
		int(zero_pending),
		int(credited),
		int(cap_blocked),
		StateHash.hash_string(regrown_id)
	]
