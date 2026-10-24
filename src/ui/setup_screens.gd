class_name SetupScreens
extends RefCounted


static func build(host: MenuHost, state: String) -> void:
	if state == "match_banner":
		host.label(
			{
				"career": "CAREER — limb loss is permanent",
				"fresh_body": "FRESH BODY — no permanent limb loss",
				"versus": "LOCAL VERSUS",
				"practice": "PRACTICE"
			}[Router.config.mode],
			36
		)
		host.label(
			(
				"%s versus %s / %s"
				% [
					Router.config.fighter_ids[0],
					Router.config.fighter_ids[1],
					Router.config.arena_id
				]
			)
		)
		host.label(
			(
				"A/D move • J light • K heavy • L kick • Forward + J/K and Down + "
				+ "L select slot B • J+L grab • Shift block • Space dodge • U "
				+ "superpower • I ultimate • Esc pause"
			)
		)
		host.button("Begin fight", func(): Router.transition("match"))
		host.button("Back", Router.back)
		return
	if state == "loadout":
		_loadout(host)
		return
	var roster := ["theron", "atalanta", "pyrrhus", "sibyl"]
	var row := HBoxContainer.new()
	host.body.add_child(row)
	for index in 2:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		host.label("PLAYER " + str(index + 1), 22, column)
		host.choice(
			roster,
			roster.find(Router.config.fighter_ids[index]),
			func(selected: int):
				Router.config.fighter_ids[index] = roster[selected]
				host._show(Router.state),
			column
		)
		var data: Dictionary = (
			DataLoader
			. new()
			. load_json("res://data/fighters/%s.json" % Router.config.fighter_ids[index])
			. value
		)
		var preview := ModelPreview.new()
		column.add_child(preview)
		preview.setup(Router.config.fighter_ids[index], Router.config.resolved_palettes()[index])
		host.label(
			(
				"Reach %d  Speed %d  Power %d\nToughness %d  Target %d"
				% [
					data["reach"],
					data["speed"],
					data["power"],
					data["limb_toughness"],
					data["target_size"]
				]
			),
			18,
			column
		)
		var palettes := ["default", "ivory", "night"]
		host.choice(
			palettes,
			palettes.find(Router.config.palettes[index]),
			func(selected: int):
				Router.config.palettes[index] = palettes[selected]
				host._show(Router.state),
			column
		)
		var controllers := [
			"human_kb1",
			"human_kb2",
			"human_pad0",
			"human_pad1",
			"ai_easy",
			"ai_normal",
			"ai_hard",
			"dummy_idle",
			"dummy_block_always"
		]
		host.choice(
			controllers,
			controllers.find(Router.config.controllers[index]),
			func(selected: int): Router.config.controllers[index] = controllers[selected],
			column
		)
	var arenas := ["mount_olympus", "athens_colosseum", "tartarus_pits"]
	host.choice(
		arenas,
		arenas.find(Router.config.arena_id),
		func(index: int):
			Router.config.arena_id = arenas[index]
			host._show(Router.state)
	)
	var arena_preview := ModelPreview.new()
	host.body.add_child(arena_preview)
	arena_preview.setup(Router.config.arena_id, "default", false, true)
	arena_preview.custom_minimum_size.y = 150
	var hazard := CheckButton.new()
	hazard.text = "Arena hazards (Athens always hazard-free)"
	hazard.button_pressed = bool(Router.config.rules.get("hazards", true))
	hazard.toggled.connect(func(enabled: bool): Router.config.rules["hazards"] = enabled)
	host.body.add_child(hazard)
	host.button(
		"Choose abilities",
		func():
			Router.loadout_origin = Router.state
			Router.transition("loadout")
	)
	host.button(
		"Continue",
		func():
			var error := Router.config.validate()
			if error == "":
				Router.transition("match_banner")
			else:
				host.message.text = error
	)
	host.button("Back", func(): Router.transition("main_menu"))


static func _loadout(host: MenuHost) -> void:
	var career := Router.loadout_origin == "career_hub"
	if not career:
		host.choice(
			["Player 1", "Player 2"],
			Router.loadout_player,
			func(index: int):
				Router.loadout_player = index
				host._show("loadout")
		)
	var unlocked: Array = (
		Router.career.data["fighter"]["unlocked_abilities"]
		if career
		else Router.career.catalog.keys()
	)
	var slots: Dictionary = (
		Router.career.data["fighter"]["loadout"].duplicate(true)
		if career
		else (
			Router.config.loadouts[Router.loadout_player].duplicate(true)
			if not Router.config.loadouts.is_empty()
			else Loadout.full(Router.loadout_player)
		)
	)
	for kind in Loadout.COUNTS:
		host.label(kind.to_upper(), 22)
		var options: Array = [""]
		for id in unlocked:
			if Router.career.catalog[id]["type"] == kind:
				options.append(id)
		for index in int(Loadout.COUNTS[kind]):
			var current: Array = slots.get(kind, [])
			var selected := options.find(current[index]) if index < current.size() else 0
			host.choice(
				options,
				selected,
				func(chosen: int):
					var values: Array = slots.get(kind, []).duplicate()
					while values.size() <= index:
						values.append("")
					values[index] = options[chosen]
					slots[kind] = values
			)
	host.button(
		"Save loadout",
		func():
			var normalized := {}
			for kind in slots:
				normalized[kind] = slots[kind].filter(func(id): return id != "")
			var error := Loadout.validate(normalized, unlocked, Router.career.catalog)
			if error != "":
				host.message.text = error
				return
			if career:
				Router.career.data["fighter"]["loadout"] = normalized
				if Router.career.save.save_data(Router.career.data) != OK:
					host.message.text = "Save failed"
					return
			else:
				if Router.config.loadouts.is_empty():
					Router.config.loadouts = [Loadout.full(0), Loadout.full(1)]
				Router.config.loadouts[Router.loadout_player] = normalized
			Router.transition(Router.loadout_origin)
	)
	host.button("Back", func(): Router.transition(Router.loadout_origin))
