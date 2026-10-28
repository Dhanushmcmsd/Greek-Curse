class_name MatchController
extends Node
## Owns the simulation. Reads input, calls step once per physics frame, then updates views.

signal match_completed(summary: Dictionary)
signal menu_requested
var managed: bool = false
var world: SimWorld
var match_config := MatchConfig.new()
var flow := RoundFlow.new()
var damage_dealt: Array = [0, 0]
var longest_combos: Array = [0, 0]
var _reported_result: bool = false
var _pause_menu: PauseMenu
var _results: ResultsStub
var _match_tools: MatchTools
var _camera: Camera3D
var _shake: float = 0.0
var _ai: Array = []
var _views: Array[FighterView] = []
var _hud: HudPrototype
var _debug: DebugOverlay
var _banner := "Round 1"
var _rules: Dictionary = {}
var _curves: Dictionary = {}
var _fighter_rows: Array = []
var _move_rows: Array = []
var _combat: Dictionary = {}
var _last_physics_frame := -1
var _autoplay := false
var _shot_path := ""
var _record_path := ""
var _recorded: Array = []
var _autoplay_ticks := 0
var _autoplay_limit := 90
var _ai_demo := false
var _players: Array[PlayerInput] = [PlayerInput.new(), PlayerInput.new()]
var _recorder := InputRecorder.new()
var _captions: CaptionSystem
var _model_override := ""


func _ready() -> void:
	_read_flags()
	_load_match()
	_setup_controllers()
	_build_input()
	_build_stage()
	world = _make_world()
	_match_tools.catalog = world.fighters[0].limbs.catalog
	_match_tools.populate_combos(world.moves)
	_sync(true)
	if "--results-demo" in OS.get_cmdline_user_args():
		for tick in 5000:
			if world.phase == SimWorld.PHASE_MATCH_OVER:
				break
			_consume(world.step(ProtoScript.inputs_at(world.tick)))
		flow.phase = "results"
		_results.show_results(world, damage_dealt, longest_combos)
	if "--limbs-demo" in OS.get_cmdline_user_args():
		_match_tools.open()


func _physics_process(_delta: float) -> void:
	var frame := Engine.get_physics_frames()
	if frame == _last_physics_frame:
		return
	_last_physics_frame = frame
	if (
		not (managed and match_config.mode == "career")
		and InputMap.has_action("proto_restart")
		and Input.is_action_just_pressed("proto_restart")
	):
		_restart()
	if InputMap.has_action("proto_debug") and Input.is_action_just_pressed("proto_debug"):
		_debug.set_enabled(not _debug.visible_boxes)
	var running := flow.advance()
	if world.phase == SimWorld.PHASE_FIGHTING and running:
		var masks := _read_inputs()
		if _record_path != "":
			_recorded.append(masks)
		var events: Array = world.step(masks)
		_recorder.record(world, masks)
		_consume(events)
	if managed and flow.phase == "results" and not _reported_result:
		_reported_result = true
		match_completed.emit(result_summary())
	if not managed and flow.phase == "results" and not _match_tools.chooser.visible:
		_results.show_results(world, damage_dealt, longest_combos)
	_sync(false)
	_maybe_finish_autoplay()


func _read_flags() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--autoplay":
			_autoplay = true
		elif arg == "--ai-demo":
			_ai_demo = true
			_autoplay = true
			match_config.controllers = ["ai_normal", "ai_hard"]
		elif arg.begins_with("--arena="):
			match_config.arena_id = arg.substr(8)
		elif arg.begins_with("--ticks="):
			_autoplay_limit = int(arg.substr(8))
		elif arg.begins_with("--shot="):
			_shot_path = arg.substr("--shot=".length())
		elif arg.begins_with("--record="):
			_record_path = arg.substr("--record=".length())
		elif arg.begins_with("--model="):
			_model_override = arg.substr("--model=".length())


func _load_match() -> void:
	var loader := DataLoader.new()
	_rules = _require(loader, "res://data/rules/match.json")
	_curves = _require(loader, "res://data/balance/stat_curves.json")
	_fighter_rows = [
		_require(loader, "res://data/fighters/%s.json" % match_config.fighter_ids[0]),
		_require(loader, "res://data/fighters/%s.json" % match_config.fighter_ids[1]),
	]
	for row in _fighter_rows:
		row["height_mm"] = 1800
	_move_rows = [
		_require(loader, "res://data/moves/jab_of_hermes.json"),
		_require(loader, "res://data/moves/cyclops_smash.json"),
		_require(loader, "res://data/moves/pegasus_kick.json"),
		_require(loader, "res://data/moves/grab.json"),
		_require(loader, "res://data/moves/muay_thai_flurry.json"),
		_require(loader, "res://data/moves/thunder_elbow_strike.json"),
		_require(loader, "res://data/moves/phantom_flurry.json"),
		_require(loader, "res://data/moves/phantom_ambush.json"),
		_require(loader, "res://data/moves/spartan_flurry.json"),
		_require(loader, "res://data/moves/divine_uppercut.json"),
		_require(loader, "res://data/moves/ghost_sweep_chain.json"),
		_require(loader, "res://data/moves/olympian_crusher.json"),
		_require(loader, "res://data/moves/lightning_jab_chain.json"),
		_require(loader, "res://data/moves/titan_combo_kick.json"),
		_require(loader, "res://data/moves/olympian_barrage.json"),
		_require(loader, "res://data/moves/spartan_cross.json"),
		_require(loader, "res://data/moves/sweeping_hydra.json"),
		_require(loader, "res://data/moves/satyr_dropkick.json"),
	]
	_combat = _require(loader, "res://data/balance/combat.json")
	for name in DirAccess.get_files_at("res://data/moves"):
		if name.begins_with("body_") and name.ends_with(".json"):
			_move_rows.append(_require(loader, "res://data/moves/" + name))


func _require(loader: DataLoader, path: String) -> Dictionary:
	var result := loader.load_json(path)
	if not result.ok:
		Log.error("match", result.error)
		return {}
	return result.value


func _make_world() -> SimWorld:
	return MatchLauncher.make_world(match_config)


func _restart() -> void:
	_reported_result = false
	_match_tools.chooser.hide()
	_setup_controllers()
	world = _make_world()
	flow = RoundFlow.new()
	damage_dealt = [0, 0]
	longest_combos = [0, 0]
	_results.visible = false
	_pause_menu.show_menu(false)
	_recorder = InputRecorder.new()
	_recorder.seed = match_config.seed
	_recorder.fighter_ids = match_config.fighter_ids.duplicate()
	_banner = "Round 1"
	for view in _views:
		view._flash_ticks = 0


func _build_stage() -> void:
	_captions = CaptionSystem.new()
	add_child(_captions)
	Audio.switch_music(match_config.arena_id)
	var camera := FightCamera.new()
	_camera = camera
	add_child(camera)
	var gore := GoreManager.new()
	gore.arena_id = match_config.arena_id
	add_child(gore)
	var arena := ArenaGreybox.new()
	arena.arena_id = match_config.arena_id
	add_child(arena)
	var colors := [Color(0.72, 0.38, 0.18), Color(0.18, 0.5, 0.32)]
	for index in _fighter_rows.size():
		var view := FighterView.new()
		var row: Dictionary = _fighter_rows[index]
		var model_ov: String = _model_override if index == 0 else ""
		view.setup(
			colors[index],
			int(row["height_mm"]),
			int(row["body_width_mm"]),
			str(row["id"]),
			model_ov
		)
		add_child(view)
		_views.append(view)
		if view.rig != null:
			view.rig.apply_palette(match_config.resolved_palettes()[index])
	_hud = CombatHud.new()
	add_child(_hud)
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.resume_requested.connect(_resume)
	_pause_menu.restart_requested.connect(_restart)
	_pause_menu.quit_requested.connect(_return_to_launcher)
	_results = ResultsStub.new()
	add_child(_results)
	_match_tools = MatchTools.new()
	for index in _views.size():
		if _views[index].rig != null:
			_match_tools.model_ids[index] = _views[index].rig.loaded_fighter_model_id
	add_child(_match_tools)
	_match_tools.new_match_requested.connect(_restart)
	_match_tools.replacement_requested.connect(_start_with_replacement)
	_match_tools.panel_changed.connect(_menu_changed)
	_results.new_match_requested.connect(_restart)
	_results.limbs_requested.connect(_match_tools.open)
	_debug = DebugOverlay.new()
	add_child(_debug)


func _build_input() -> void:
	var bindings := InputBindings.new()
	bindings.reset_defaults()
	var saved: Dictionary = Settings.values.get("bindings", {})
	if not saved.is_empty():
		bindings.import_bindings(saved)
	bindings.install()


func _read_inputs() -> Array:
	if _autoplay and not _ai_demo:
		return ProtoScript.inputs_at(world.tick)
	var masks: Array = []
	for index in 2:
		var controller: String = match_config.controllers[index]
		if controller.begins_with("ai_"):
			masks.append(_ai[index].decide(AIObservation.capture(world, index)))
		elif controller.begins_with("dummy_"):
			masks.append(DummyController.input_for(controller.substr(6), world.tick))
		else:
			var device := 0 if controller.ends_with("kb1") or controller.ends_with("pad0") else 1
			masks.append(
				_players[index].sample(device, "pad" if controller.contains("pad") else "keyboard")
			)
	return masks


func _setup_controllers() -> void:
	_ai = []
	for index in 2:
		var id: String = match_config.controllers[index]
		_ai.append(
			(
				MatchLauncher.make_ai(
					id.substr(3),
					match_config.seed + index + 10,
					(
						DataLoader
						. new()
						. load_json("res://data/fighters/%s.json" % match_config.fighter_ids[index])
						. value["ai_archetype"]
					)
				)
				if id.begins_with("ai_")
				else null
			)
		)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		flow.paused = not flow.paused
		_pause_menu.show_menu(flow.paused)
	if not managed and event.keycode in [KEY_1, KEY_2, KEY_3]:
		if event.keycode == KEY_1:
			match_config.controllers = ["human_kb1", "human_kb2"]
		elif event.keycode == KEY_2:
			match_config.controllers = ["human_kb1", "ai_normal"]
		else:
			match_config.controllers = ["ai_normal", "ai_hard"]
		_restart()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START:
		flow.paused = not flow.paused
		_pause_menu.show_menu(flow.paused)


func _consume(events: Array) -> void:
	Audio.consume(events)
	_captions.consume(events)
	flow.consume(events)
	(_hud as CombatHud).consume(events, world)
	for event in events:
		if event.kind == SimEvent.Kind.HIT or event.kind == SimEvent.Kind.BLOCK:
			var zone: String = str(event.payload.get("zone", "body"))
			var blocked: bool = event.kind == SimEvent.Kind.BLOCK
			var combo_hits: int = int(event.payload.get("chain_hits", 0))
			# Compute combo VFX tier for escalating visuals (Tekken 8 Heat style)
			var vfx_combo_tier := 0
			if combo_hits >= 15:
				vfx_combo_tier = 3
			elif combo_hits >= 10:
				vfx_combo_tier = 2
			elif combo_hits >= 6:
				vfx_combo_tier = 1
			_views[event.other].flash()
			_views[event.other].recoil(
				signf(_views[event.other].position.x - _views[event.actor].position.x), blocked
			)
			# Forward reactive hit info to defender's view for zone-specific reactions
			var move_name: String = str(event.payload.get("attacker_move", ""))
			_views[event.other].notify_hit(zone, blocked, combo_hits, move_name)
			var gore: GoreManager = (
				get_tree().get_first_node_in_group("gore_manager") as GoreManager
			)
			if gore != null:
				gore.burst(_views[event.other].impact_point(zone), blocked, false, vfx_combo_tier)
				# Wall-bounce VFX when fighter hits wall
				if bool(event.payload.get("wall_bounce", false)):
					gore.wall_splat_burst(_views[event.other].impact_point(zone))
			# Escalating camera impact based on combo
			var base_impact := 0.04 + minf(0.08, float(event.amount) * 0.0025)
			if combo_hits > 2:
				base_impact += minf(0.07, float(combo_hits) * 0.014)
			(_camera as FightCamera).impact(base_impact)
			var stop_att: int = int(event.payload.get("hitstop_attacker", world.hitstop_remaining))
			var stop_def: int = int(event.payload.get("hitstop_defender", world.hitstop_remaining))
			_views[event.actor].visual_stop = maxi(
				_views[event.actor].visual_stop,
				int(SettingsHooks.scale_amount(float(stop_att), "hitstop_percent"))
			)
			_views[event.other].visual_stop = maxi(
				_views[event.other].visual_stop,
				int(SettingsHooks.scale_amount(float(stop_def), "hitstop_percent"))
			)
			damage_dealt[event.actor] += event.amount
			# Escalating screen shake for combos
			var combo_shake := 0.04 if event.amount < 25 else 0.12
			if combo_hits > 2:
				combo_shake += minf(0.09, float(combo_hits) * 0.016)
			_shake = SettingsHooks.scale_amount(combo_shake, "shake_percent")
		elif event.kind == SimEvent.Kind.ABILITY:
			if event.payload["type"] in ["superpower", "ultimate"]:
				var gore_node: GoreManager = (
					get_tree().get_first_node_in_group("gore_manager") as GoreManager
				)
				if gore_node != null:
					gore_node.burst(_views[event.actor].position + Vector3(0, 1.3, 0), true)
				(_camera as FightCamera).impact(0.08, event.payload["type"] == "ultimate")
		elif event.kind == SimEvent.Kind.LIMB_SEVERED:
			# Dramatic sever: big camera impact + slowmo for all views
			(_camera as FightCamera).impact(0.18, true)
			for view in _views:
				view.visual_stop = maxi(view.visual_stop, 30)
			_shake = SettingsHooks.scale_amount(0.15, "shake_percent")
		elif event.kind == SimEvent.Kind.KO:
			_banner = "KO"
		elif event.kind == SimEvent.Kind.ROUND_START:
			_banner = "Round %d" % event.round_index
		elif event.kind == SimEvent.Kind.MATCH_END:
			_banner = "Winner: %s" % world.fighters[event.winner].display_name
		elif event.kind == SimEvent.Kind.COMBO_EXTENDED:
			longest_combos[event.actor] = maxi(
				longest_combos[event.actor], int(event.payload["chain_hits"])
			)


func _sync(_first: bool) -> void:
	var menu_visible := (
		_match_tools.chooser.visible or _results.visible or _pause_menu.panel.visible
	)
	_hud.visible = not menu_visible
	_captions.visible = not menu_visible
	_match_tools.bar.visible = not menu_visible and not (managed and match_config.mode == "career")
	for index in world.fighters.size():
		if _views[index].driver != null:
			_views[index].driver.preview_pose = (
				("victory" if world.wins[index] > world.wins[1 - index] else "defeat")
				if flow.phase == "results"
				else ""
			)
		_views[index].show_fighter(
			world.fighters[index], flow.paused or world.hitstop_remaining > 0
		)
	for view in _views:
		if view.driver != null and view.driver.caption != "":
			(_hud as CombatHud).credit_text = view.driver.caption
	_hud.show_match(world, flow.banner if flow.phase != "fight" else _banner)
	(_camera as FightCamera).track(world)
	for child in get_children():
		if child is ArenaBuilder:
			child.sync(world)
	_debug.refresh(world)


func _menu_changed(shown: bool) -> void:
	flow.paused = shown
	_results.visible = false
	_hud.visible = not shown and flow.phase != "results"


func _resume() -> void:
	flow.paused = false
	_pause_menu.show_menu(false)


func _start_with_replacement(player: int, slot: String, id: String) -> void:
	_restart()
	var limbs := world.fighters[player].limbs
	limbs.parts[slot].state = "severed"
	limbs.parts[slot].integrity = 0
	limbs.integrity[slot] = 0
	limbs.regrow(slot, id)
	_recorder.initial = world.export_limb_state()


func _return_to_launcher() -> void:
	if managed:
		menu_requested.emit()
		return
	match_config.controllers = ["human_kb1", "ai_normal"]
	_restart()
	flow.paused = true
	_banner = "Choose mode: 1 local / 2 vs AI / 3 watch"


func _maybe_finish_autoplay() -> void:
	if not _autoplay:
		return
	_autoplay_ticks += 1
	var finished := world.phase == SimWorld.PHASE_MATCH_OVER or _autoplay_ticks >= _autoplay_limit
	if not finished:
		return
	_autoplay = false
	_capture_and_quit()


func _exit_tree() -> void:
	_write_recording()


func _write_recording() -> void:
	if _record_path == "" or _recorder.inputs.is_empty():
		return
	if _recorder.save_to(_record_path, world) != OK:
		Log.error("match", "replay record failed")


func _capture_and_quit() -> void:
	await RenderingServer.frame_post_draw
	_write_recording()
	if _shot_path != "":
		var image := get_viewport().get_texture().get_image()
		var error := image.save_png(_shot_path)
		if error != OK:
			Log.error("match", "screenshot failed: %s" % _shot_path)
	get_tree().quit()


func result_summary() -> Dictionary:
	return {
		"won": world.wins[0] > world.wins[1],
		"rounds": world.wins.duplicate(),
		"damage": damage_dealt.duplicate(),
		"combo": longest_combos[0],
		"opponent": world.fighters[1].display_name,
		"limbs": world.fighters[0].limbs.export_state(),
		"amputations": world.amputations.duplicate(true),
		"date": Time.get_datetime_string_from_system()
	}
