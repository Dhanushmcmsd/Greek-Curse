class_name CombatHud
extends HudPrototype

var diagrams: Array[BodyDiagram] = []
var credit_text: String = ""
var _resources: Array[Label] = []
var _attack_timing: Array[Label] = []
var _combos: Array[Label] = []
var _credit: Label
var _meters: Array = []
var _ghosts: Array[ColorRect] = []
var _ghost_health: Array = [300.0, 300.0]
var _edges: Array[ColorRect] = []
var _power_bars: Array[ColorRect] = []
var _power_glows: Array[Panel] = []
var _power_labels: Array[Label] = []
var _combo_until: Array[int] = [0, 0]
var _combo_tweens: Array = [null, null]
var _fighter_names: Array[Label] = []
var _limb_status: Array[Label] = []
var _ultimate_labels: Array[Label] = []
var _ultimate_bars: Array[ColorRect] = []
var _round_score: Label


func _ready() -> void:
	super._ready()
	for i in 2:
		var ghost := ColorRect.new()
		ghost.position = Vector2(40 if i == 0 else 760, 28)
		ghost.size = Vector2(400, 28)
		ghost.color = Color(0.9, 0.8, 0.5)
		get_child(0).add_child(ghost)
		get_child(0).move_child(ghost, 0)
		_ghosts.append(ghost)
		var bars: Array = []
		for bar_index in 2:
			var back := ColorRect.new()
			back.position = Vector2(40 if i == 0 else 760, 60 + bar_index * 10)
			back.size = Vector2(400, 6)
			back.color = Color(0.12, 0.14, 0.17)
			add_child(back)
			var meter := ColorRect.new()
			meter.size = Vector2(400, 6)
			meter.color = Color(0.3, 0.65, 0.8) if bar_index == 0 else Color(0.8, 0.65, 0.2)
			back.add_child(meter)
			bars.append(meter)
		_meters.append(bars)
		var base := Vector2(40 if i == 0 else 1000, 145)
		var diagram := BodyDiagram.new()
		diagram.position = base
		add_child(diagram)
		diagrams.append(diagram)
		var label := Label.new()
		label.position = Vector2(40 if i == 0 else 760, 115)
		add_child(label)
		_resources.append(label)
		var timing := Label.new()
		timing.position = Vector2(40 if i == 0 else 760, 595)
		timing.add_theme_font_size_override("font_size", 16)
		add_child(timing)
		_attack_timing.append(timing)
		var combo := Label.new()
		combo.position = Vector2(48 if i == 0 else 975, 285)
		combo.add_theme_font_size_override("font_size", 42)
		combo.add_theme_color_override("font_color", Color("ffd57c"))
		combo.add_theme_color_override("font_outline_color", Color("131923"))
		combo.add_theme_constant_override("outline_size", 8)
		combo.visible = false
		add_child(combo)
		_combos.append(combo)
		var power_back := ColorRect.new()
		power_back.position = Vector2(40 if i == 0 else 840, 565)
		power_back.size = Vector2(400, 18)
		power_back.color = Color("17232d")
		add_child(power_back)
		var glow := Panel.new()
		glow.size = power_back.size
		var glow_style := StyleBoxFlat.new()
		glow_style.bg_color = Color(0.1, 0.8, 1, 0.12)
		glow_style.shadow_color = Color(0.25, 0.85, 1, 0.65)
		glow_style.shadow_size = 9
		glow.add_theme_stylebox_override("panel", glow_style)
		power_back.add_child(glow)
		_power_glows.append(glow)
		var fill := ColorRect.new()
		fill.size.y = 18
		fill.color = Color("55cce9")
		power_back.add_child(fill)
		_power_bars.append(fill)
		var power_label := Label.new()
		power_label.position = power_back.position - Vector2(0, 27)
		power_label.size = Vector2(400, 26)
		power_label.add_theme_font_size_override("font_size", 15)
		power_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(power_label)
		_power_labels.append(power_label)
	_credit = Label.new()
	for side in 2:
		var edge := ColorRect.new()
		edge.position = Vector2(0 if side == 0 else 1268, 0)
		edge.size = Vector2(12, 720)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(edge)
		_edges.append(edge)
	_credit.position = Vector2(350, 530)
	add_child(_credit)
	_hint.text = (
		"A/D move | J/K fists | L/O feet | G grab | B body | Shift block | Space dodge | Esc pause"
		+ " | U super / I ultimate"
	)
	_hint.add_theme_font_size_override("font_size", 16)
	var theme := GameTheme.build()
	theme.default_font_size = int(SettingsHooks.scale_amount(18.0, "ui_scale_percent"))
	for child in get_children():
		if child is Control:
			child.theme = theme
	_polish_layout()


func _panel(parent: Node, at: Vector2, dimensions: Vector2, accent: Color) -> Panel:
	var panel := Panel.new()
	panel.position = at
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.065, 0.93)
	style.set_border_width_all(0)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	parent.move_child(panel, 0)
	var ornament := NinePatchRect.new()
	ornament.texture = GameTheme.BORDER
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ornament.patch_margin_left = 12
	ornament.patch_margin_right = 12
	ornament.patch_margin_top = 12
	ornament.patch_margin_bottom = 12
	ornament.draw_center = false
	ornament.modulate = accent.lerp(GameTheme.GOLD, 0.65)
	ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ornament)
	return panel


func _small_label(at: Vector2, width: float, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.size = Vector2(width, 24)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _polish_layout() -> void:
	var base := get_child(0)
	for child in base.get_children():
		if child is ColorRect:
			if child.size.y == 180:
				child.hide()
			elif child.size == Vector2(400, 28):
				child.position = Vector2(40 if child.position.x < 600 else 840, 66)
				child.size.y = 14
	_pips.hide()
	_timer.position = Vector2(568, 32)
	_timer.size = Vector2(144, 50)
	_timer.add_theme_font_size_override("font_size", 36)
	_panel(base, Vector2(568, 24), Vector2(144, 92), Color("d9b879"))
	_round_score = _small_label(Vector2(568, 84), 144, 14, Color("d9b879"))
	_round_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.position.y = 150
	_banner.add_theme_font_size_override("font_size", 22)
	_hint.text = "A D  MOVE    J K  PUNCH    L O  KICK    G  GRAB    SHIFT  GUARD    SPACE  DODGE    F2  COMBOS    ESC  PAUSE"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.modulate = Color("b4c2d3")
	_credit.position = Vector2(460, 500)
	_credit.size.x = 360
	_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_credit.add_theme_font_size_override("font_size", 16)
	for i in 2:
		var x := 40.0 if i == 0 else 840.0
		var tint := Color("6ce1db") if i == 0 else Color("e7b980")
		_panel(base, Vector2(x - 16, 24), Vector2(432, 91), tint)
		_panel(base, Vector2(x - 16, 544), Vector2(432, 82), tint)
		var label := _small_label(Vector2(x, 31), 400, 22, Color("f3eee3"))
		_fighter_names.append(label)
		var limb := _small_label(Vector2(x, 121), 400, 13, Color("b4c2d3"))
		_limb_status.append(limb)
		diagrams[i].hide()
		_resources[i].position = Vector2(x, 88)
		_resources[i].add_theme_font_size_override("font_size", 12)
		_resources[i].modulate = Color("a8b8cb")
		_ghosts[i].position = Vector2(x, 66)
		_ghosts[i].size.y = 14
		_meters[i][0].get_parent().position = Vector2(x, 83)
		_meters[i][0].get_parent().size.y = 2
		_meters[i][0].size.y = 2
		_meters[i][1].get_parent().hide()
		_attack_timing[i].position = Vector2(x, 518)
		_power_bars[i].get_parent().position = Vector2(x, 578)
		_power_bars[i].get_parent().size.y = 7
		_power_bars[i].size.y = 7
		_power_glows[i].size.y = 7
		_power_labels[i].position = Vector2(x, 552)
		_power_labels[i].add_theme_font_size_override("font_size", 14)
		var ultimate := _small_label(Vector2(x, 590), 400, 14, Color("f4cf82"))
		_ultimate_labels.append(ultimate)
		var back := ColorRect.new()
		back.position = Vector2(x, 615)
		back.size = Vector2(400, 4)
		back.color = Color("342c24")
		add_child(back)
		var fill := ColorRect.new()
		fill.size = Vector2(0, 4)
		fill.color = Color("f4cf82")
		back.add_child(fill)
		_ultimate_bars.append(fill)
	_left_fill.color = Color("56c7bd")
	_right_fill.color = Color("dbac70")


func show_match(world: SimWorld, banner: String) -> void:
	super.show_match(world, banner)
	_left_fill.size.y = 14
	_right_fill.size.y = 14
	_right_fill.position.x = 1240.0 - _right_fill.size.x
	_banner.visible = banner.begins_with("Round") or banner in ["FIGHT", "KO"]
	_round_score.text = "%d   •   %d" % [world.wins[0], world.wins[1]]
	for i in 2:
		var fighter := world.fighters[i]
		_fighter_names[i].text = fighter.display_name.replace(" Stub", "")
		var limb_parts: Array[String] = []
		for slot in SimLimbs.LIMB_NAMES:
			var state: String = fighter.limbs.parts[slot].state
			limb_parts.append(({"arm_l": "L ARM", "arm_r": "R ARM", "leg_l": "L LEG", "leg_r": "R LEG"}[slot]) + " " + str({"healthy": "OK", "bruised": "HURT", "cracked": "BROKEN", "severed": "LOST"}.get(state, state.to_upper())))
		_limb_status[i].text = "   ·   ".join(limb_parts)
		var ultimate_id := SimAbilities.ultimate_id(fighter)
		var ultimate_ready := SimAbilities.ready(world, fighter, ultimate_id)
		_ultimate_labels[i].text = "[%s] ULTIMATE   %s" % [ComboListMenu.bound_key("ultimate", i), "READY — " + str(world.abilities[ultimate_id].name) if ultimate_ready else str(fighter.meter) + "%"]
		_ultimate_bars[i].size.x = 400.0 * fighter.meter / float(world.combat.meter_max)
		_ultimate_labels[i].modulate.a = 0.8 + sin(float(world.tick) * 0.06) * 0.2 if ultimate_ready else 0.85
		var timing := "READY"
		var tint := Color("8db6b0")
		if fighter.attack_rearm_ticks > 0:
			timing = "RESET  %.2fs" % (float(fighter.attack_rearm_ticks) / 60.0)
		elif fighter.move_id > 0:
			var remaining := (
				fighter.startup_ticks
				+ fighter.active_ticks
				+ fighter.recovery_ticks
				- fighter.move_age
			)
			timing = (
				"%s  %.2fs"
				% [
					SimFighter.STATE_NAMES[fighter.state].to_upper(),
					float(maxi(0, remaining)) / 60.0
				]
			)
			var open := (
				fighter.landed_hit
				and fighter.hits_done >= fighter.attack_hit_count
				and fighter.attack_can_cancel
			)
			if (
				open
				and fighter.move_age >= fighter.cancel_start
				and fighter.move_age < fighter.cancel_end
			):
				timing = "COMBO NOW  %.2fs" % (float(fighter.cancel_end - fighter.move_age) / 60.0)
				tint = Color("f1c76d")
			elif fighter.attack_can_cancel and fighter.move_age < fighter.cancel_start:
				timing += (
					"  |  LINK IN %.2fs" % (float(fighter.cancel_start - fighter.move_age) / 60.0)
				)
		_attack_timing[i].text = timing
		_attack_timing[i].modulate = tint
		@warning_ignore("integer_division") # Intentional fixed-point/tick truncation.
		_edges[i].color = Color(
			0.7,
			0.05,
			0.04,
			(
				0.3
				if (
					fighter.health < world.max_health / 4
					and not bool(SettingsHooks.get_value("flash_reduction"))
				)
				else 0.0
			)
		)
		_ghost_health[i] = move_toward(_ghost_health[i], float(fighter.health), 0.7)
		_ghosts[i].size.x = 400.0 * _ghost_health[i] / world.max_health
		if i == 1:
			_ghosts[i].position.x = 1240.0 - _ghosts[i].size.x
		_meters[i][0].size.x = 400.0 * fighter.stamina / fighter.stamina_max
		_meters[i][1].size.x = 400.0 * fighter.meter / int(world.combat["meter_max"])
		var power_id := SimAbilities.super_id(fighter)
		var power_ready := SimAbilities.ready(world, fighter, power_id)
		_power_bars[i].size.x = 4.0 * fighter.super_charge
		_power_glows[i].visible = power_ready
		_power_glows[i].modulate.a = 0.65 if bool(SettingsHooks.get_value("flash_reduction")) else 0.65 + sin(float(world.tick) * 0.06) * 0.25
		var key := ComboListMenu.bound_key("super", i)
		var power_name := str(world.abilities.get(power_id, {}).get("name", power_id))
		var cooldown := maxi(0, int(fighter.ability_cooldowns.get(power_id, 0)) - world.tick)
		_power_labels[i].text = "%s  %d%%  [%s] %s" % [power_name, fighter.super_charge, key, "READY" if power_ready else "%.1fs" % (float(cooldown) / 60.0) if cooldown > 0 else "LOW STAMINA" if fighter.super_charge >= 100 else ""]
		diagrams[i].update_limbs(fighter)
		_resources[i].text = (
			"STA %d/%d   ULT %d%%   %s"
			% [
				fighter.stamina,
				fighter.stamina_max,
				fighter.meter,
				"FURY" if SimModifier.percent_for(fighter, world.tick) > 100 else ""
			]
		)
		_combos[i].visible = world.tick < _combo_until[i] and fighter.confirmed_hits > 0
		_combos[i].text = "%d HIT%s" % [fighter.confirmed_hits, "" if fighter.confirmed_hits == 1 else "S"]
	_credit.text = credit_text


func consume(events: Array, world: SimWorld) -> void:
	for event in events:
		if event.kind == SimEvent.Kind.ROUND_START:
			_combo_until.assign([0, 0])
		if event.kind in [SimEvent.Kind.HIT, SimEvent.Kind.GRAB] and event.actor in [0, 1]:
			var index: int = event.actor
			_combo_until[index] = world.tick + 100
			var label: Label = _combos[index]
			if _combo_tweens[index] != null:
				_combo_tweens[index].kill()
			label.scale = Vector2.ONE * (1.0 if bool(SettingsHooks.get_value("flash_reduction")) else 1.22)
			_combo_tweens[index] = label.create_tween()
			_combo_tweens[index].tween_property(label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if event.kind == SimEvent.Kind.LIMB_QUIRK:
			credit_text = str(event.payload.get("quirk", "")).to_upper()
		if event.kind == SimEvent.Kind.LIMB_SEVERED:
			var credit: Dictionary = event.payload["credit"]
			credit_text = (
				"%s takes %s"
				% [world.fighters[int(credit["attacker"])].display_name, credit["limb"]]
			)
