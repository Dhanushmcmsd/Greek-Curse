class_name FighterAI
extends RefCounted
## Delayed-observation utility controller. Returns input only.

var difficulty: Dictionary = {}
var weights: Dictionary = {}
var history: Array = []
var next_decision: int = 0
var last_mask: int = 0
var rng := SimRng.new(1)


func setup(config: Dictionary, archetype: Dictionary, seed: int) -> void:
	difficulty = config.duplicate(true)
	weights = archetype.duplicate(true)
	rng = SimRng.new(seed)
	history = []
	next_decision = 0
	last_mask = 0


func decide(observation: Dictionary) -> int:
	history.append(observation.duplicate(true))
	var tick := int(observation["tick"])
	var delay := int(difficulty["reaction_ticks"])
	while history.size() > delay + 2:
		history.pop_front()
	if tick < next_decision:
		var held := last_mask
		for bit in SimInput.ATTACK_BITS:
			held &= ~bit
		return held
	var seen: Dictionary = {}
	for row in history:
		if int(row["tick"]) <= tick - delay:
			seen = row
	if seen.is_empty():
		return 0
	next_decision = tick + int(difficulty["decision_interval"])
	last_mask = _choose(seen)
	return last_mask


func _choose(seen: Dictionary) -> int:
	var toward := SimInput.RIGHT if int(seen["other_x"]) > int(seen["x"]) else SimInput.LEFT
	var away := SimInput.LEFT if toward == SimInput.RIGHT else SimInput.RIGHT
	var distance := absi(int(seen["other_x"]) - int(seen["x"]))
	var options: Array = seen["options"]
	var best_mask := 0
	var best_score := -100000
	var max_range := 0
	var pressure := false
	for limb in seen["other_limbs"].values():
		if limb["state"] == "bruised" or limb["state"] == "cracked":
			pressure = true
	for move in options:
		max_range = maxi(max_range, int(move["range"]))
		if int(move["cost"]) > int(seen["stamina"]) or distance > int(move["range"]):
			continue
		var score := int(move["damage"]) * int(weights["damage"]) - int(move["startup"]) * 2
		if pressure:
			score += int(move["limb_damage"]) * int(weights["limb_pressure"])
		if move["grab"]:
			score += int(weights["grab"]) * (10 if seen["other_blocking"] else 1)
		if int(seen["other_state"]) == SimFighter.State.RECOVERY:
			score += int(difficulty["punish_accuracy"])
		score += rng.range_i(0, int(difficulty["choice_noise"]) + 1)
		if score > best_score:
			best_score = score
			best_mask = int(move["mask"])
	if distance > max_range - int(difficulty["spacing_tolerance"]):
		return toward
	if seen["can_block"] and int(seen["other_state"]) == SimFighter.State.STARTUP:
		if rng.range_i(0, 100) < int(difficulty["block_percent"]):
			return SimInput.BLOCK
	if rng.range_i(0, 100) < int(difficulty["aggression_percent"]):
		return best_mask
	if int(seen["stamina"]) < 15:
		return away
	return 0
