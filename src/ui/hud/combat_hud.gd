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
		combo.position = Vector2(260 if i == 0 else 740, 150)
		add_child(combo)
		_combos.append(combo)
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
		"A/D move | J/K fists | L/O feet | B body | Shift block | Space dodge | Esc pause"
		+ " | U super / I ultimate"
	)
	_hint.add_theme_font_size_override("font_size", 16)
	var theme := GameTheme.build()
	theme.default_font_size = int(SettingsHooks.scale_amount(18.0, "ui_scale_percent"))
	for child in get_children():
		if child is Control:
			child.theme = theme


func show_match(world: SimWorld, banner: String) -> void:
	super.show_match(world, banner)
	for i in 2:
		var fighter := world.fighters[i]
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
		_meters[i][0].size.x = 400.0 * fighter.stamina / fighter.stamina_max
		_meters[i][1].size.x = 400.0 * fighter.meter / int(world.combat["meter_max"])
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
		if not fighter.loadout.get("superpower", []).is_empty():
			var id: String = fighter.loadout["superpower"][0]
			var remaining := maxi(0, int(fighter.ability_cooldowns.get(id, 0)) - world.tick)
			_resources[i].text += (
				"  U: " + ("READY" if remaining == 0 else str((remaining + 59) / 60) + "s")
			)
		var chain := world.fighters[1 - i].chain
		_combos[i].text = (
			"%d HITS%s"
			% [
				chain.combo_hits,
				"\nCHAIN ACTIVE" if chain.is_live(world.tick, world.limb_rules) else ""
			]
		)
	_credit.text = credit_text


func consume(events: Array, world: SimWorld) -> void:
	for event in events:
		if event.kind == SimEvent.Kind.LIMB_QUIRK:
			credit_text = str(event.payload.get("quirk", "")).to_upper()
		if event.kind == SimEvent.Kind.LIMB_SEVERED:
			var credit: Dictionary = event.payload["credit"]
			credit_text = (
				"%s takes %s"
				% [world.fighters[int(credit["attacker"])].display_name, credit["limb"]]
			)
