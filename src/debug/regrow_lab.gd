extends "res://src/debug/body_state_lab.gd"

var _limb_picker: OptionButton
var _grant_slot: String = "arm_l"
var _tooltip: Label
var _model_picker: OptionButton
var _model_id: String = ""


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fighter="):
			match_config.fighter_ids[0] = arg.substr(10)
		elif arg.begins_with("--model="):
			_model_id = arg.substr(8)
	super._ready()
	match_config.controllers = ["human_kb1", "dummy_idle"]
	_setup_controllers()
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 270)
	panel.custom_minimum_size.x = 310
	_hud.add_child(panel)
	var roster := OptionButton.new()
	for name in ["Theron", "Atalanta", "Pyrrhus", "Sibyl"]:
		roster.add_item(name)
	panel.add_child(roster)
	roster.item_selected.connect(_pick_fighter)
	_model_picker = OptionButton.new()
	var models: Array = [
		"default",
		"theron",
		"atalanta",
		"pyrrhus",
		"sibyl",
		"skin_ch39",
		"skin_ch40",
		"skin_demon",
		"skin_kachujin",
		"skin_nightshade",
		"vampire_stress"
	]
	for m in models:
		_model_picker.add_item("Model: " + m)
		_model_picker.set_item_metadata(_model_picker.item_count - 1, "" if m == "default" else m)
	panel.add_child(_model_picker)
	_model_picker.item_selected.connect(_pick_model)
	var slots := OptionButton.new()
	for slot in SimLimbs.LIMB_NAMES:
		slots.add_item(slot)
	panel.add_child(slots)
	slots.item_selected.connect(_pick_slot)
	_limb_picker = OptionButton.new()
	panel.add_child(_limb_picker)
	_limb_picker.item_selected.connect(_describe)
	var grant := Button.new()
	grant.text = "Sever selected slot + grant limb to P1"
	panel.add_child(grant)
	grant.pressed.connect(_grant)
	_tooltip = Label.new()
	_tooltip.custom_minimum_size = Vector2(310, 130)
	_tooltip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip.add_theme_font_size_override("font_size", 14)
	panel.add_child(_tooltip)
	_pick_slot(0)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--limb="):
			var id := arg.substr(7)
			_pick_slot(2 if id.ends_with("leg") else 0)
			for index in _limb_picker.item_count:
				if _limb_picker.get_item_metadata(index) == id:
					_limb_picker.select(index)
			_grant()
	roster.select(["theron", "atalanta", "pyrrhus", "sibyl"].find(match_config.fighter_ids[0]))
	slots.select(SimLimbs.LIMB_NAMES.find(_grant_slot))


func _read_inputs() -> Array:
	if "--still-preview" in OS.get_cmdline_user_args():
		return [0, 0]
	return super._read_inputs()


func _pick_fighter(index: int) -> void:
	match_config.fighter_ids[0] = ["theron", "atalanta", "pyrrhus", "sibyl"][maxi(0, index)]
	_rebuild_view()


func _pick_model(index: int) -> void:
	_model_id = str(_model_picker.get_item_metadata(index))
	_rebuild_view()


func _rebuild_view() -> void:
	_restart()
	flow.phase = "fight"
	flow.remaining = 0
	_views[0].queue_free()
	var view := FighterView.new()
	view.setup(
		Color(0.7, 0.45, 0.2),
		world.fighters[0].height_mm,
		world.fighters[0].body_width_mm,
		match_config.fighter_ids[0],
		_model_id
	)
	add_child(view)
	_views[0] = view


func _pick_slot(index: int) -> void:
	_grant_slot = SimLimbs.LIMB_NAMES[index]
	_limb_picker.clear()
	for id in world.fighters[0].limbs.catalog:
		var row: Dictionary = world.fighters[0].limbs.catalog[id]
		if _grant_slot.begins_with(row["slot"]):
			_limb_picker.add_item(row["display_name"])
			_limb_picker.set_item_metadata(_limb_picker.item_count - 1, id)
	_describe(0)


func _describe(index: int) -> void:
	var id: String = _limb_picker.get_item_metadata(index)
	var row: Dictionary = world.fighters[0].limbs.catalog[id]
	_tooltip.text = "\n".join(row["tooltip_lines"].values())


func _grant() -> void:
	_restart()
	flow.phase = "fight"
	flow.remaining = 0
	var fighter := world.fighters[0]
	var limb: SimLimb = fighter.limbs.parts[_grant_slot]
	limb.state = "severed"
	limb.integrity = 0
	fighter.limbs.integrity[_grant_slot] = 0
	var id: String = _limb_picker.get_item_metadata(_limb_picker.selected)
	fighter.limbs.regrow(_grant_slot, id)
	_recorder = InputRecorder.new()
	_recorder.initial = world.export_limb_state()
	_recorder.fighter_ids = match_config.fighter_ids.duplicate()
	_describe(_limb_picker.selected)
