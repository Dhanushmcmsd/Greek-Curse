extends MatchController
## Playable models plus explicit, deterministic limb-rule controls.

var _selected_slot: String = "arm_l"
var _lab_text: Label


func _ready() -> void:
	super._ready()
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 170)
	_hud.add_child(panel)
	_lab_text = Label.new()
	_lab_text.text = "SEVERING LAB | P2 target | F2 limb / F3 bruise / F4 crack / F5 chain"
	panel.add_child(_lab_text)
	for title in ["Cycle target limb", "Bruise 50%", "Crack 25%", "Three-hit sever", "Reset match"]:
		var button := Button.new()
		button.text = title
		panel.add_child(button)
		button.pressed.connect(_action.bind(title))
	var arena_picker := OptionButton.new()
	for title in ["Mount Olympus", "Athens Colosseum", "Tartarus Pits"]:
		arena_picker.add_item(title)
	panel.add_child(arena_picker)
	arena_picker.item_selected.connect(_select_arena)
	var fighter_picker := OptionButton.new()
	for title in ["Theron", "Atalanta", "Pyrrhus", "Sibyl"]:
		fighter_picker.add_item(title)
	panel.add_child(fighter_picker)
	fighter_picker.item_selected.connect(_select_model)
	for arg in OS.get_cmdline_user_args():
		if arg == "--demo-sever":
			_action("Three-hit sever")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var actions := {
			KEY_F2: "Cycle target limb",
			KEY_F3: "Bruise 50%",
			KEY_F4: "Crack 25%",
			KEY_F5: "Three-hit sever"
		}
		if actions.has(event.keycode):
			_action(actions[event.keycode])


func _action(title: String) -> void:
	var limbs := world.fighters[1].limbs
	var limb: SimLimb = limbs.parts[_selected_slot]
	if title == "Cycle target limb":
		_selected_slot = SimLimbs.LIMB_NAMES[(SimLimbs.LIMB_NAMES.find(_selected_slot) + 1) % 4]
	elif title == "Reset match":
		_restart()
	elif title == "Three-hit sever":
		var events: Array = []
		for hit in 3:
			SimSeverance.hit(world, 1, 0, _selected_slot, limb.max_integrity / 3 + 1, events)
		for entry in events:
			print("LAB_EVENT ", SimEvent.Kind.keys()[entry.kind], " ", entry.payload)
	elif limb.state != "severed":
		limb.integrity = limb.max_integrity * (50 if title == "Bruise 50%" else 25) / 100
		limbs.integrity[_selected_slot] = limb.integrity
		limb.refresh(world.limb_rules)
	_lab_text.text = "SEVERING LAB | P2: " + _selected_slot + " | F2/F3/F4/F5"


func _select_arena(index: int) -> void:
	for child in get_children():
		if child is ArenaGreybox:
			remove_child(child)
			child.queue_free()
	var arena := ArenaGreybox.new()
	arena.arena_id = ["mount_olympus", "athens_colosseum", "tartarus_pits"][index]
	add_child(arena)


func _select_model(index: int) -> void:
	var id: String = ["theron", "atalanta", "pyrrhus", "sibyl"][index]
	_views[1].queue_free()
	var view := FighterView.new()
	view.setup(Color.WHITE, 1750, 430, id)
	add_child(view)
	_views[1] = view
