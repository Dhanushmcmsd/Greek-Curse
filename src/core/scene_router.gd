extends Node
signal changed(state: String)
var state: String = "boot"
var stack: Array[String] = []
var graph: Dictionary = {}
var config := MatchConfig.new()
var career := CareerService.new()
var result: Dictionary = {}
var error_message: String = ""
var loadout_player: int = 0
var loadout_origin: String = "career_hub"


func _ready() -> void:
	graph = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/navigation.json"))
	error_message = ContentCheck.verify()
	if error_message == "":
		career.setup(Settings.path.get_base_dir())


func start() -> void:
	if error_message != "":
		transition("error")
		return
	transition(
		(
			"age_gate"
			if not Settings.values["age_gate_accepted"]
			else "content_warning" if not Settings.values["content_warning_seen"] else "main_menu"
		)
	)


func transition(target: String, remember: bool = true) -> bool:
	if target != "error" and target not in graph.get(state, []):
		error_message = "Invalid navigation: %s -> %s" % [state, target]
		return false
	if remember:
		stack.append(state)
	state = target
	changed.emit(state)
	return true


func back() -> void:
	if stack.is_empty():
		return
	var target: String = stack.pop_back()
	if target in graph.get(state, []):
		transition(target, false)
	elif state not in ["age_gate", "boot", "match"]:
		transition(str(graph[state][-1]), false)


func fail(message: String) -> void:
	error_message = message
	Log.error("router", message)
	transition("error")


func setup_mode(mode: String) -> void:
	config = MatchConfig.new()
	config.mode = mode
	config.controllers = ["human_kb1", "human_kb2" if mode == "versus" else "ai_normal"]
	transition(mode + "_setup")


func prepare_career() -> void:
	var fighter: Dictionary = career.data["fighter"]
	var ladder: Array = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/ladder/career_ladder.json")
	)
	var opponent: Dictionary = ladder[mini(int(fighter["ladder_index"]), ladder.size() - 1)]
	config = MatchConfig.new()
	config.mode = "career"
	config.fighter_ids = [fighter["id"], opponent["fighter"]]
	config.controllers = ["human_kb1", "ai_" + opponent["difficulty"]]
	config.palettes = [fighter["palette"], opponent["palette"]]
	config.arena_id = opponent["arena"]
	config.rules["hazards"] = opponent["hazards"]
	config.loadouts = [
		fighter["loadout"].duplicate(true), Loadout.full(int(opponent["loadout_index"]))
	]
	config.initial_limbs = [fighter["limbs"].duplicate(true)]
	config.seed = int(career.data["rng_seed_counter"])
	transition("match_banner")


func finish(summary: Dictionary) -> void:
	result = summary.duplicate(true)
	var error := career.apply_match_result(result, config.mode)
	if error != "":
		fail(error)
		return
	transition("results")


func result_continue() -> void:
	if not career.data.get("fighter", {}).get("offers_state", []).is_empty():
		transition("offer")
	else:
		transition("career_hub" if config.mode == "career" else "main_menu")
