extends "res://src/debug/regrow_lab.gd"

var chosen: String = "idle"
var scrub: int = 0
var info: Label


func _ready() -> void:
	super._ready()
	var box := VBoxContainer.new()
	box.position = Vector2(455, 135)
	box.custom_minimum_size.x = 370
	_hud.add_child(box)
	var selector := OptionButton.new()
	var choices: Array = [
		"idle",
		"walk",
		"block",
		"dodge",
		"hitstun",
		"stagger",
		"ko",
		"grab",
		"grabbed",
		"victory",
		"defeat",
		"get_up",
		"crawl",
		"torso_scuttle",
		"torso_roll"
	]
	for move in world.moves:
		choices.append(move["id"])
	for name in choices:
		selector.add_item(name)
	selector.item_selected.connect(func(index: int): chosen = choices[index])
	box.add_child(selector)
	var ticks := HSlider.new()
	ticks.min_value = 0
	ticks.max_value = 90
	ticks.step = 1
	ticks.value_changed.connect(func(value: float): scrub = int(value))
	box.add_child(ticks)
	info = Label.new()
	info.add_theme_font_size_override("font_size", 14)
	box.add_child(info)
	_debug.set_enabled(true)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pose="):
			chosen = arg.substr(7)
		elif arg.begins_with("--state-tick="):
			scrub = int(arg.substr(13))
	selector.select(maxi(0, choices.find(chosen)))
	ticks.value = scrub


func _physics_process(delta: float) -> void:
	flow.paused = true
	super._physics_process(delta)
	var fighter := world.fighters[0]
	fighter.clear_move()
	fighter.blocking = chosen == "block"
	fighter.pose = SimBodyState.movement(fighter, world.body_rules)["pose"]
	fighter.state = maxi(0, SimFighter.STATE_NAMES.find(chosen))
	fighter.state_tick = scrub
	var driver := _views[0].driver
	driver.preview_pose = (
		chosen if driver.data["poses"].has(chosen) and chosen not in ["idle", "stagger"] else ""
	)
	for move in world.moves:
		if move["id"] == chosen:
			fighter.begin_move(1, move, 1, 1)
			fighter.state_tick = scrub
			var phase := PoseDriver.attack_phase(scrub, fighter.startup_ticks, fighter.active_ticks)
			fighter.state = (
				SimFighter.State.STARTUP
				if phase == "startup"
				else SimFighter.State.ACTIVE if phase == "active" else SimFighter.State.RECOVERY
			)
	_views[0].show_fighter(fighter)
	_debug.refresh(world)
	var rig: FighterRig = _views[0].rig
	var current_anim: String = ""
	var is_fallback: bool = true
	if rig.anim_player != null and rig.anim_player.is_playing():
		current_anim = rig.anim_player.current_animation
		is_fallback = false
	var source_str: String = (
		("Mixamo [" + current_anim + "]") if not is_fallback else "Procedural Fallback"
	)
	info.text = (
		"Tick %d | %s | %s | reach %d mm"
		% [scrub, driver.phase, source_str, driver.reach_mismatch_mm]
	)
