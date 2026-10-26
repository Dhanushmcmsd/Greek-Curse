extends "res://src/debug/severing_lab.gd"


func _ready() -> void:
	super._ready()
	var picker := OptionButton.new()
	picker.position = Vector2(24, 270)
	for mask in 16:
		picker.add_item("P1 missing limbs mask %d" % mask)
	_hud.add_child(picker)
	picker.item_selected.connect(_set_mask)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mask="):
			_set_mask(int(arg.substr(7)))


func _set_mask(mask: int) -> void:
	_restart()
	SimBodyState.apply_mask(world.fighters[0], mask)
	_recorder.initial = world.export_limb_state()
	var info := SimBodyState.derive(world.fighters[0].limbs)
	_lab_text.text = "P1 %s | A/D move J/K fists L/O feet B body" % info["profile"]
