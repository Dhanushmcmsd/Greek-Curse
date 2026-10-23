class_name MatchConfig
extends RefCounted

var fighter_ids: Array[String] = ["theron", "atalanta"]
var controllers: Array[String] = ["human_kb1", "ai_normal"]
var arena_id: String = "mount_olympus"
var mode: String = "practice"
var seed: int = 1
var rules: Dictionary = {}
var loadouts: Array = []


func validate() -> String:
	if fighter_ids.size() != 2 or controllers.size() != 2:
		return "Exactly two fighters and controllers required"
	for id in fighter_ids:
		if id not in ["theron", "atalanta", "pyrrhus", "sibyl"]:
			return "Unknown fighter " + id
	for controller in controllers:
		if (
			controller
			not in [
				"human_kb1",
				"human_kb2",
				"human_pad0",
				"human_pad1",
				"ai_easy",
				"ai_normal",
				"ai_hard",
				"dummy_idle",
				"dummy_block_always",
				"dummy_walk_back_forth",
				"dummy_attack_on_interval",
				"dummy_regen_reset"
			]
		):
			return "Unknown controller " + controller
	if controllers[0] == controllers[1] and controllers[0].begins_with("human"):
		return "Human controllers must be distinct"
	if (
		arena_id not in ["mount_olympus", "athens_colosseum", "tartarus_pits"]
		or mode not in ["practice", "versus", "fresh_body", "career"]
	):
		return "Unknown arena or mode"
	return ""
