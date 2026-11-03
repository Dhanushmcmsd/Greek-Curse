class_name ComboListMenu
extends PanelContainer

signal closed

var title_label: Label
var close_btn: Button
var grid: GridContainer
var chains_container: VBoxContainer
var fighter_selector: OptionButton
var _all_moves: Array = []
var selected_fighter: String = ""
const ROSTER = ["theron", "atalanta", "pyrrhus", "sibyl", "dorian"]


func _init() -> void:
	name = "ComboListMenu"
	custom_minimum_size = Vector2(1060, 640)
	size = Vector2(1060, 640)
	_setup_theme()
	_build_ui()


func _setup_theme() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.06, 0.10, 0.97)
	bg.border_width_left = 2
	bg.border_width_top = 2
	bg.border_width_right = 2
	bg.border_width_bottom = 2
	bg.border_color = Color("d4af37")
	bg.corner_radius_top_left = 10
	bg.corner_radius_top_right = 10
	bg.corner_radius_bottom_right = 10
	bg.corner_radius_bottom_left = 10
	bg.content_margin_left = 32
	bg.content_margin_right = 32
	bg.content_margin_top = 24
	bg.content_margin_bottom = 24
	add_theme_stylebox_override("panel", bg)


func _build_ui() -> void:
	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 16)
	add_child(root)

	# Header Row
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	title_label = Label.new()
	title_label.text = "⚡ COMBAT COMMAND & COMBO LIST"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("e4bc6b"))
	header.add_child(title_label)

	close_btn = Button.new()
	close_btn.text = "Close  ✕"
	close_btn.custom_minimum_size = Vector2(120, 36)
	close_btn.pressed.connect(func(): closed.emit())
	header.add_child(close_btn)
	fighter_selector = OptionButton.new()
	for id in ROSTER:
		var row: Dictionary = DataLoader.new().load_json("res://data/fighters/" + id + ".json").value
		fighter_selector.add_item(str(row.display_name))
	fighter_selector.item_selected.connect(func(index: int): populate(_all_moves, ROSTER[index]))
	root.add_child(fighter_selector)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content_box := VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_theme_constant_override("separation", 18)
	scroll.add_child(content_box)

	# === FEATURED COMBO CHAINS ===
	var combo_header := Label.new()
	combo_header.text = "FEATURED COMBO CHAINS"
	combo_header.add_theme_font_size_override("font_size", 18)
	combo_header.add_theme_color_override("font_color", Color("ffb24f"))
	content_box.add_child(combo_header)

	chains_container = VBoxContainer.new()
	chains_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chains_container.add_theme_constant_override("separation", 10)
	content_box.add_child(chains_container)

	_add_combo_chain_entry("PLAYER 1 KEYS: facing right / facing left", _key_command("Forward · Back · Down"), _key_command("Left Punch · Right Punch · Left Kick · Right Kick · Grab · Equipped Super · Equipped Ultimate"))

	# === INDIVIDUAL MOVES TABLE ===
	var moves_header := Label.new()
	moves_header.text = "INDIVIDUAL MOVES & ATTACK METRICS"
	moves_header.add_theme_font_size_override("font_size", 18)
	moves_header.add_theme_color_override("font_color", Color("ffb24f"))
	content_box.add_child(moves_header)

	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(grid)

	for hdr in [
		"Move", "Command", "Damage / hit", "Link window (frames)"
	]:
		var h := Label.new()
		h.text = hdr
		h.add_theme_color_override("font_color", Color("88aacc"))
		h.add_theme_font_size_override("font_size", 14)
		grid.add_child(h)



func _add_combo_chain_entry(title: String, sequence: String, details: String) -> void:
	var entry_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.18, 0.85)
	style.border_width_left = 3
	style.border_color = Color("e4bc6b")
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.content_margin_left = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.content_margin_right = 16
	entry_panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	entry_panel.add_child(v)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color("f0d588"))
	v.add_child(t)

	var s := Label.new()
	s.text = sequence
	s.add_theme_font_size_override("font_size", 15)
	s.add_theme_color_override("font_color", Color.WHITE)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)

	var d := Label.new()
	d.text = details
	d.add_theme_font_size_override("font_size", 13)
	d.add_theme_color_override("font_color", Color("88bbdd"))
	v.add_child(d)

	chains_container.add_child(entry_panel)


func _add_rule_entry(rule: String, sub: String) -> void:
	var entry_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.06, 0.04, 0.85)
	style.border_width_left = 3
	style.border_color = Color("ff6633")
	style.content_margin_left = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.content_margin_right = 16
	entry_panel.add_theme_stylebox_override("panel", style)

	var v := VBoxContainer.new()
	entry_panel.add_child(v)

	var t := Label.new()
	t.text = rule
	t.add_theme_font_size_override("font_size", 14)
	t.add_theme_color_override("font_color", Color("ffaa77"))
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)

	var s := Label.new()
	s.text = sub
	s.add_theme_font_size_override("font_size", 13)
	s.add_theme_color_override("font_color", Color("ccbbaa"))
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)

	chains_container.add_child(entry_panel)


func populate(move_rows: Array, fighter_id: String = "") -> void:
	_all_moves = move_rows
	selected_fighter = fighter_id
	if fighter_id != "":
		fighter_selector.select(ROSTER.find(fighter_id))
		var filtered: Array = []
		for move in move_rows:
			if str(move.id) == "grab" or str(move.get("owner", "")) == fighter_id or (fighter_id == "dorian" and str(move.id).begins_with("dorian_")):
				filtered.append(move)
		move_rows = filtered
	for child in grid.get_children():
		if child.get_meta("data_row", false):
			grid.remove_child(child)
			child.queue_free()

	for child in chains_container.get_children():
		if child.get_meta("live_chain", false):
			chains_container.remove_child(child)
			child.queue_free()
	var by_id := {}
	for move in move_rows:
		by_id[str(move["id"])] = move
	var catalog: Dictionary = DataLoader.new().load_json("res://data/animation/combo_catalog.json").value
	var featured_index := 1
	for combo in catalog.get(fighter_id, []):
		_add_combo_chain_entry(combo.name, " → ".join(combo.inputs.map(func(command): return _key_command(str(command)))), combo.description)
		var entry := chains_container.get_child(-1)
		entry.set_meta("live_chain", true)
		chains_container.move_child(entry, featured_index)
		featured_index += 1
	for move in move_rows:
		if not bool(move.get("can_cancel", false)):
			continue
		for target_id in move.get("cancel_into", []):
			if not by_id.has(target_id):
				continue
			var target: Dictionary = by_id[target_id]
			_add_combo_chain_entry(
				(
					str(move.get("display_name", move["id"]))
					+ " → "
					+ str(target.get("display_name", target_id))
				),
				_format_input(move) + " → " + _format_input(target),
				(
					"Startup %d ticks | Cancel [%d, %d) | Follow-up cost %d stamina"
					% [
						int(move["startup_ticks"]),
						int(move["cancel_start"]),
						int(move["cancel_end"]),
						int(target.get("cost", 0))
					]
				)
			)
			chains_container.get_child(-1).set_meta("live_chain", true)

	for row in move_rows:
		var name_lbl := Label.new()
		name_lbl.text = str(row.get("display_name", row.get("id", "?")))
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.set_meta("data_row", true)

		var input_lbl := Label.new()
		input_lbl.text = _format_input(row)
		input_lbl.add_theme_font_size_override("font_size", 14)
		input_lbl.add_theme_color_override("font_color", Color("ffd27f"))
		input_lbl.set_meta("data_row", true)

		var startup_lbl := Label.new()
		startup_lbl.text = "%d ticks" % int(row.get("startup_ticks", 0))
		startup_lbl.add_theme_font_size_override("font_size", 14)
		startup_lbl.set_meta("data_row", true)

		var cancel_window_lbl := Label.new()
		var can_cancel: bool = bool(row.get("can_cancel", false))
		var c_start: int = int(row.get("cancel_start", 0))
		var c_end: int = int(row.get("cancel_end", 0))
		if can_cancel and c_end > c_start:
			cancel_window_lbl.text = "%d – %d ticks" % [c_start, c_end]
			cancel_window_lbl.add_theme_color_override("font_color", Color("66ee99"))
		else:
			cancel_window_lbl.text = "None"
			cancel_window_lbl.add_theme_color_override("font_color", Color("777777"))
		cancel_window_lbl.add_theme_font_size_override("font_size", 14)
		cancel_window_lbl.set_meta("data_row", true)

		var dmg_lbl := Label.new()
		dmg_lbl.text = str(row.get("damage", "-"))
		dmg_lbl.add_theme_font_size_override("font_size", 14)
		dmg_lbl.set_meta("data_row", true)

		var cancel_ids: Array = row.get("cancel_into", [])
		var cancel_lbl := Label.new()
		cancel_lbl.text = ", ".join(cancel_ids) if not cancel_ids.is_empty() else "—"
		cancel_lbl.set_meta("data_row", true)
		cancel_lbl.add_theme_color_override(
			"font_color", Color("66ee99") if not cancel_ids.is_empty() else Color("555555")
		)
		cancel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cancel_lbl.custom_minimum_size.x = 200

		startup_lbl.free()
		cancel_lbl.free()
		for lbl in [name_lbl, input_lbl, dmg_lbl, cancel_window_lbl]:
			lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl.custom_minimum_size.x = 240 if lbl == name_lbl or lbl == input_lbl else 130
			grid.add_child(lbl)


static func _format_input(row: Dictionary) -> String:
	var text := _semantic_input(row)
	if text == "Combo follow-up":
		text = "Right Punch" if str(row.get("owner", "")) in ["theron", "pyrrhus"] else "Right Kick"
	return _key_command(text)


static func _semantic_input(row: Dictionary) -> String:
	if str(row.get("id", "")) in ["grab", "dorian_throw_forward"]:
		return "Grab"
	if row.has("input_label"):
		return str(row.input_label)
	var commands := {
		"olympian_crusher": "Down + Right Kick",
		"muay_thai_flurry": "Forward + Right Kick",
		"thunder_elbow_strike": "Forward + Right Punch",
		"phantom_flurry": "Back + Left Punch",
		"phantom_ambush": "Back + Right Punch",
		"spartan_flurry": "Down + Left Punch",
		"divine_uppercut": "Down + Right Punch",
		"ghost_sweep_chain": "Forward + Left Kick",
		"hoplite_sweep_chain": "Down + Left Kick",
		"olympian_heel_chain": "Back + Left Kick",
		"lightning_jab_chain": "Forward + Left Punch",
		"titan_combo_kick": "Back + Right Kick"
	}
	var id := str(row.get("id", ""))
	if commands.has(id):
		return commands[id]
	match str(row.get("category", "")):
		"superpower":
			return "Equipped Super"
		"ultimate":
			return "Equipped Ultimate"
		_:
			return (
				("Right Kick" if str(row.get("limb_side", "")).ends_with("r") else "Left Kick") if str(row.get("limb_side", "")).begins_with("leg") else ("Right Punch" if str(row.get("limb_side", "")).ends_with("r") else "Left Punch")
			)


static func bound_key(action: String, player: int = 0) -> String:
	var id := "p%d_%s" % [player + 1, action]
	if InputMap.has_action(id):
		for event in InputMap.action_get_events(id):
			if event is InputEventKey:
				return OS.get_keycode_string(event.physical_keycode)
	var defaults: Dictionary = DataLoader.new().load_json("res://data/ui/default_bindings.json").value
	return str(defaults.get(id, {}).get("key", "—"))


static func _key_command(command: String) -> String:
	var actions := {"Left Punch": "light", "Right Punch": "heavy", "Left Kick": "kick", "Right Kick": "kick_right", "Equipped Super": "super", "Equipped Ultimate": "ultimate", "Down": "down", "Grab": "grab"}
	for word in actions:
		command = command.replace(word, "[" + bound_key(actions[word]) + "]")
	command = command.replace("Forward", "[" + bound_key("right") + "/" + bound_key("left") + "]")
	command = command.replace("Back", "[" + bound_key("left") + "/" + bound_key("right") + "]")
	return command.replace("Kick", "[" + bound_key("kick") + "/" + bound_key("kick_right") + "]").replace(" (string follow-up)", "")
