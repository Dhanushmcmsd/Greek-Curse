class_name ComboListMenu
extends PanelContainer

signal closed

var title_label: Label
var close_btn: Button
var grid: GridContainer
var chains_container: VBoxContainer


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

	# --- Titan Rush Chain ---
	_add_combo_chain_entry(
		"⚔ Titan Rush Chain",
		"[Punch] + [Punch] + [Kick]  →  Titan Knee Rush  →  Olympian Thunder Elbow",
		"Startup: 14 ticks | Cancel Window: 24–32 ticks | Wall Splat Finisher | Damage: ~86"
	)
	# --- Ghost Ambush Chain ---
	_add_combo_chain_entry(
		"👻 Ghost Ambush Chain",
		"[Forward] + [Kick]  →  Ghost Sweep Chain  →  Phantom Flurry  →  Phantom Ambush",
		"Startup: 8 ticks | Cancel Window: 14–20 ticks | High Stun Finisher | Damage: ~64"
	)
	# --- Spartan Blitz ---
	_add_combo_chain_entry(
		"🛡 Spartan Blitz",
		"[Punch] + [Punch] + [Punch]  →  Spartan Flurry  →  Divine Uppercut  →  Thunder Elbow",
		"Startup: 6 ticks | 3-stage escalation | Launcher + Wall Bounce | Damage: ~96"
	)
	# --- Lightning Assault ---
	_add_combo_chain_entry(
		"⚡ Lightning Assault",
		"[Punch]×4 (Lightning Jab Chain)  →  Spartan Flurry  →  Muay Thai Flurry",
		"Startup: 3 ticks | Ultra-fast 7-hit starter | Best cancel potential | Damage: ~72"
	)
	# --- Titan Combo Kick Loop ---
	_add_combo_chain_entry(
		"🦵 Titan Kick Loop",
		"[Kick] + [Forward]  →  Titan Combo Kick  →  Muay Thai Flurry  →  Thunder Elbow",
		"Startup: 12 ticks | Aerial juggle pressure | Leg-zone targeting | Damage: ~84"
	)
	# --- Divine Crusher ---
	_add_combo_chain_entry(
		"🌩 Divine Crusher (Super)",
		"[Punch] (Heavy) + [Forward]  →  Divine Uppercut  →  Olympian Crusher",
		"Startup: 10 ticks | Costs 25 meter | 2-Armor hits | Slowest but highest damage | Damage: ~72"
	)

	# === INDIVIDUAL MOVES TABLE ===
	var moves_header := Label.new()
	moves_header.text = "INDIVIDUAL MOVES & ATTACK METRICS"
	moves_header.add_theme_font_size_override("font_size", 18)
	moves_header.add_theme_color_override("font_color", Color("ffb24f"))
	content_box.add_child(moves_header)

	grid = GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.add_child(grid)

	for hdr in [
		"Move Name", "Input Command", "Startup (Ticks)", "Cancel Window", "Damage", "Cancels Into"
	]:
		var h := Label.new()
		h.text = hdr
		h.add_theme_color_override("font_color", Color("88aacc"))
		h.add_theme_font_size_override("font_size", 14)
		grid.add_child(h)

	# === AMPUTATION RULES ===
	var amp_header := Label.new()
	amp_header.text = "AMPUTATION SYSTEM"
	amp_header.add_theme_font_size_override("font_size", 18)
	amp_header.add_theme_color_override("font_color", Color("ff7744"))
	content_box.add_child(amp_header)

	_add_rule_entry(
		"1 Amputation per match — triggered in round 2 when accumulated limb damage reaches 65+",
		"• Leg loss: –25% movement speed  •  Arm loss: disables 2-handed cancel moves"
	)
	_add_rule_entry(
		"Rage Compensation — amputated fighter gains +15% damage on all remaining attacks",
		"• Full meter top-up on sever  •  20-tick wakeup invulnerability window"
	)


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


func populate(move_rows: Array) -> void:
	for child in grid.get_children():
		if child.get_meta("data_row", false):
			grid.remove_child(child)
			child.queue_free()

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

		for lbl in [name_lbl, input_lbl, startup_lbl, cancel_window_lbl, dmg_lbl, cancel_lbl]:
			grid.add_child(lbl)


static func _format_input(row: Dictionary) -> String:
	var cat: String = str(row.get("category", ""))
	match row.get("id", ""):
		"muay_thai_flurry":
			return "[Kick] + [Forward]"
		"thunder_elbow_strike":
			return "[Punch] (Heavy)"
		"phantom_flurry":
			return "[Punch] + [Kick]"
		"phantom_ambush":
			return "[Forward] + [Punch]"
		"spartan_flurry":
			return "[Punch] × 3"
		"divine_uppercut":
			return "[Punch] (Heavy) ↑"
		"ghost_sweep_chain":
			return "[Forward] + [Kick] (Low)"
		"olympian_crusher":
			return "[Punch] + [Kick] (Super)"
		"lightning_jab_chain":
			return "[Punch] × 4 (Fast)"
		"titan_combo_kick":
			return "[Kick] + [Forward] ×3"
		"jab_of_hermes":
			return "[Punch] (Light)"
		"spartan_cross":
			return "[Punch] + [Forward]"
		"cyclops_smash":
			return "[Punch] (Heavy)"
		"pegasus_kick":
			return "[Kick] (Forward)"
		"sweeping_hydra":
			return "[Kick] (Sweep)"
		"satyr_dropkick":
			return "[Kick] (Down)"
		"olympian_barrage":
			return "[Punch] × 5"
		_:
			match cat:
				"light":
					return "[Punch] (Light)"
				"heavy":
					return "[Punch] (Heavy)"
				"kick":
					return "[Kick]"
				"special":
					return "[Punch] + [Kick]"
				"combo_special":
					return "[Kick] + [Forward]"
				"superpower":
					return "[Super]"
				"ultimate":
					return "[Ultimate]"
				_:
					return "[Punch] / [Kick]"
