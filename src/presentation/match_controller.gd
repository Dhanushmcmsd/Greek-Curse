class_name MatchController
extends Node
## Owns the simulation. Reads input, calls step once per physics frame, then updates views.

const KEYS := {
	"A": KEY_A,
	"D": KEY_D,
	"W": KEY_W,
	"S": KEY_S,
	"J": KEY_J,
	"K": KEY_K,
	"L": KEY_L,
	"SHIFT": KEY_SHIFT,
	"SPACE": KEY_SPACE,
	"LEFT": KEY_LEFT,
	"RIGHT": KEY_RIGHT,
	"UP": KEY_UP,
	"DOWN": KEY_DOWN,
	"KP_1": KEY_KP_1,
	"KP_2": KEY_KP_2,
	"KP_3": KEY_KP_3,
	"R": KEY_R,
	"F1": KEY_F1,
}
const JOY_BUTTONS := {
	"X": JOY_BUTTON_X,
	"Y": JOY_BUTTON_Y,
	"A": JOY_BUTTON_A,
	"B": JOY_BUTTON_B,
	"RB": JOY_BUTTON_RIGHT_SHOULDER,
}
const PLAYER_BITS := [
	["p1_left", SimInput.LEFT],
	["p1_right", SimInput.RIGHT],
	["p1_up", SimInput.UP],
	["p1_down", SimInput.DOWN],
	["p1_light", SimInput.LIGHT],
	["p1_heavy", SimInput.HEAVY],
	["p1_kick", SimInput.KICK],
	["p1_block", SimInput.BLOCK],
	["p1_dodge", SimInput.DODGE],
	["p2_left", SimInput.LEFT],
	["p2_right", SimInput.RIGHT],
	["p2_up", SimInput.UP],
	["p2_down", SimInput.DOWN],
	["p2_light", SimInput.LIGHT],
	["p2_heavy", SimInput.HEAVY],
	["p2_kick", SimInput.KICK],
	["p2_block", SimInput.BLOCK],
	["p2_dodge", SimInput.DODGE],
]

var world: SimWorld
var _views: Array[FighterView] = []
var _hud: HudPrototype
var _debug: DebugOverlay
var _banner := "Round 1"
var _rules: Dictionary = {}
var _curves: Dictionary = {}
var _fighter_rows: Array = []
var _move_rows: Array = []
var _last_physics_frame := -1
var _autoplay := false
var _shot_path := ""
var _autoplay_ticks := 0


func _ready() -> void:
	_read_flags()
	_load_match()
	_build_input()
	_build_stage()
	world = _make_world()
	_sync(true)


func _physics_process(_delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _last_physics_frame:
		return
	_last_physics_frame = frame
	if InputMap.has_action("proto_restart") and Input.is_action_just_pressed("proto_restart"):
		_restart()
	if InputMap.has_action("proto_debug") and Input.is_action_just_pressed("proto_debug"):
		_debug.set_enabled(not _debug.visible_boxes)
	if world.phase == SimWorld.PHASE_FIGHTING:
		var events: Array = world.step(_read_inputs())
		_consume(events)
	_sync(false)
	_maybe_finish_autoplay()


func _read_flags() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg.begins_with("--shot="):
			_shot_path = arg.substr("--shot=".length())


func _load_match() -> void:
	var loader := DataLoader.new()
	_rules = _require(loader, "res://data/rules/match.json")
	_curves = _require(loader, "res://data/balance/stat_curves.json")
	_fighter_rows = [
		_require(loader, "res://data/fighters/theron.json"),
		_require(loader, "res://data/fighters/atalanta.json"),
	]
	_move_rows = [
		_require(loader, "res://data/moves/jab_of_hermes.json"),
		_require(loader, "res://data/moves/cyclops_smash.json"),
		_require(loader, "res://data/moves/pegasus_kick.json"),
	]


func _require(loader: DataLoader, path: String) -> Dictionary:
	var result := loader.load_json(path)
	if not result.ok:
		Log.error("match", result.error)
		return {}
	return result.value


func _make_world() -> SimWorld:
	return SimWorld.from_data(_rules, _curves, _fighter_rows, _move_rows, 1)


func _restart() -> void:
	world = _make_world()
	_banner = "Round 1"
	for view in _views:
		view._flash_ticks = 0


func _build_stage() -> void:
	var camera := Camera3D.new()
	camera.position = Vector3(0.0, 1.7, 8.0)
	camera.current = true
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.1, 0.0))
	var arena := ArenaGreybox.new()
	add_child(arena)
	var colors := [Color(0.72, 0.38, 0.18), Color(0.18, 0.5, 0.32)]
	for index in _fighter_rows.size():
		var view := FighterView.new()
		var row: Dictionary = _fighter_rows[index]
		view.setup(colors[index], int(row["height_mm"]), int(row["body_width_mm"]))
		add_child(view)
		_views.append(view)
	_hud = HudPrototype.new()
	add_child(_hud)
	_debug = DebugOverlay.new()
	add_child(_debug)


func _build_input() -> void:
	var loader := DataLoader.new()
	var table := _require(loader, "res://data/input/prototype_bindings.json")
	for row in table["actions"]:
		var action_name := str(row["name"])
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		var key_name := str(row["key"])
		if KEYS.has(key_name):
			var key := InputEventKey.new()
			key.keycode = int(KEYS[key_name])
			InputMap.action_add_event(action_name, key)
		var joy_name := str(row.get("joy_button", ""))
		if JOY_BUTTONS.has(joy_name):
			var button := InputEventJoypadButton.new()
			button.button_index = int(JOY_BUTTONS[joy_name])
			button.device = int(row.get("device", 0))
			InputMap.action_add_event(action_name, button)


func _read_inputs() -> Array:
	if _autoplay:
		return ProtoScript.inputs_at(world.tick)
	var masks: Array[int] = [0, 0]
	for row in PLAYER_BITS:
		var action_name: String = row[0]
		var bit: int = row[1]
		var player := 0 if action_name.begins_with("p1_") else 1
		if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
			masks[player] = masks[player] | bit
		masks[player] = masks[player] | _axis_bit(action_name, bit)
	return [masks[0], masks[1]]


func _axis_bit(action_name: String, bit: int) -> int:
	if bit != SimInput.LEFT and bit != SimInput.RIGHT:
		return 0
	var device := 0 if action_name.begins_with("p1_") else 1
	var axis := Input.get_joy_axis(device, JOY_AXIS_LEFT_X)
	if bit == SimInput.LEFT and axis <= -0.5:
		return bit
	if bit == SimInput.RIGHT and axis >= 0.5:
		return bit
	return 0


func _consume(events: Array) -> void:
	for event in events:
		if event.kind == SimEvent.Kind.HIT:
			_views[event.other].flash()
		elif event.kind == SimEvent.Kind.KO:
			_banner = "KO"
		elif event.kind == SimEvent.Kind.ROUND_START:
			_banner = "Round %d" % event.round_index
		elif event.kind == SimEvent.Kind.MATCH_END:
			_banner = "Winner: %s" % world.fighters[event.winner].display_name


func _sync(_first: bool) -> void:
	for index in world.fighters.size():
		_views[index].show_fighter(world.fighters[index])
	_hud.show_match(world, _banner)
	_debug.refresh(world)


func _maybe_finish_autoplay() -> void:
	if not _autoplay:
		return
	_autoplay_ticks += 1
	var finished := world.phase == SimWorld.PHASE_MATCH_OVER or _autoplay_ticks >= 90
	if not finished:
		return
	_autoplay = false
	_capture_and_quit()


func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	if _shot_path != "":
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_shot_path)
		if error != OK:
			Log.error("match", "screenshot failed: %s" % _shot_path)
	get_tree().quit()
