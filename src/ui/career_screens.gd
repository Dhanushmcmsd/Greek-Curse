class_name CareerScreens
extends RefCounted


static func build(host: MenuHost, state: String) -> void:
	var fighter: Dictionary = Router.career.data.get("fighter", {})
	match state:
		"career_hub":
			if fighter.is_empty():
				host.label(
					"No living Career fighter. Create one to begin the six-match local ladder."
				)
				host.button("Create fighter", func(): Router.transition("fighter_create"))
			else:
				host.label(
					(
						"%s  /  %d wins — %d losses"
						% [fighter["name"], fighter["win_count"], fighter["loss_count"]]
					),
					26
				)
				_body(host, fighter)
				for slot in fighter["limbs"]:
					var limb: Dictionary = fighter["limbs"][slot]
					host.label(
						(
							"%s: %s (%d) %s"
							% [slot, limb["state"], limb["integrity"], limb["regrown_id"]]
						),
						18
					)
				if not fighter["offers_state"].is_empty():
					host.button("Choose earned ability", func(): Router.transition("offer"))
				else:
					host.button(
						(
							"Fight next trial"
							if int(fighter["ladder_index"]) < 6
							else "Ladder complete — exhibition trial"
						),
						Router.prepare_career
					)
				host.button(
					"Loadout",
					func():
						Router.loadout_origin = "career_hub"
						Router.transition("loadout")
				)
				if fighter["limbs"].values().all(func(limb): return limb["state"] == "severed"):
					(
						host
						. label(
							"You can still fight using body attacks. Visit Obol for a replacement, or retire when ready."
						)
					)
				host.button("Visit Obol", func(): Router.transition("obol"))
				host.button("Chronicle", func(): Router.transition("chronicle"))
				host.button("Retire fighter", func(): Router.transition("retire"))
			host.button("Main menu", func(): Router.transition("main_menu"))
		"fighter_create":
			_create(host)
		"offer":
			host.label("Choose one earned ability. These offers remain the same after restarting.")
			for id in fighter["offers_state"]:
				host.label(Router.career.catalog[id]["description"], 18)
				host.button(
					Router.career.catalog[id]["name"],
					func():
						if Router.career.pick_offer(id):
							Router.transition("career_hub")
						else:
							host.message.text = "Could not save the selected ability."
				)
			host.button("Choose later", func(): Router.transition("career_hub"))
		"obol":
			_obol(host, fighter)
		"chronicle":
			host.label("Longest combo: %d" % Router.career.data["chronicle"]["longest_combo"])
			host.label(
				(
					"Limbs lost: %d / Limbs taken: %d"
					% [
						Router.career.data["chronicle"]["limbs_lost"].size(),
						Router.career.data["chronicle"]["limbs_taken"].size()
					]
				)
			)
			for record in Router.career.data["chronicle"]["matches"]:
				host.label(
					(
						"%s — %s versus %s — rounds %s"
						% [
							record["date"],
							"Win" if record["won"] else "Loss",
							record["opponent"],
							record["rounds"]
						]
					)
				)
			host.button("Back", func(): Router.transition("career_hub"))
		"retire":
			host.label(
				(
					(
						"Retire %s permanently? This archives the fighter and their "
						+ "Chronicle, ending this Career. You can then create a new fighter. "
						+ "There is no undo."
					)
					% fighter["name"]
				)
			)
			host.button(
				"Confirm retirement",
				func():
					if Router.career.retire():
						Router.transition("career_hub")
					else:
						host.message.text = "Retirement could not be saved."
			)
			host.button("Cancel", func(): Router.transition("career_hub"))


static func _create(host: MenuHost) -> void:
	var selection := {"id": "theron", "palette": "default"}
	var roster := ["theron", "atalanta", "pyrrhus", "sibyl"]
	host.choice(roster, 0, func(index: int): selection["id"] = roster[index])
	var name := LineEdit.new()
	name.placeholder_text = "Name your fighter (2–24 characters)"
	name.max_length = 24
	host.body.add_child(name)
	var palettes := ["default", "ivory", "night"]
	host.choice(palettes, 0, func(index: int): selection["palette"] = palettes[index])
	host.button(
		"Create Career",
		func():
			var error := Router.career.create(
				selection["id"],
				name.text,
				selection["palette"],
				Time.get_datetime_string_from_system()
			)
			if error == "":
				Router.transition("career_hub")
			else:
				host.message.text = error
	)
	host.button("Back", func(): Router.transition("career_hub"))


static func _obol(host: MenuHost, fighter: Dictionary) -> void:
	_body(host, fighter)
	var portrait := ModelPreview.new()
	host.body.add_child(portrait)
	portrait.setup("obol", "default", true)
	host.label(
		"OBOL: " + str(DataLoader.new().load_json("res://data/ui/captions_en.json").value["obol"])
	)
	var missing: Array = fighter["limbs"].keys().filter(
		func(slot): return fighter["limbs"][slot]["state"] == "severed"
	)
	var tradable: Array = fighter["unlocked_abilities"].filter(
		func(id): return id not in Loadout.STARTER
	)
	if missing.is_empty() or tradable.is_empty():
		host.label(
			(
				"A trade requires a missing limb and an earned, non-starter "
				+ "ability. Starter abilities can never be traded."
			)
		)
		host.button("Back", func(): Router.transition("career_hub"))
		return
	var selected := {"slot": missing[0], "ability": tradable[0]}
	host.choice(missing, 0, func(index: int): selected["slot"] = missing[index])
	host.choice(tradable, 0, func(index: int): selected["ability"] = tradable[index])
	var options := VBoxContainer.new()
	host.body.add_child(options)
	host.button(
		"Show fitting limbs",
		func():
			for child in options.get_children():
				options.remove_child(child)
				child.queue_free()
			var slot: String = selected["slot"]
			var ability: String = selected["ability"]
			for id in ObolTrade.options(
				fighter,
				slot,
				ability,
				Router.career.limbs,
				int(Router.career.data["rng_seed_counter"])
			):
				var card := LimbCard.new()
				options.add_child(card)
				card.setup(id, Router.career.limbs[id]["display_name"], fighter["id"], slot)
				host.label(
					"\n".join(Router.career.limbs[id]["tooltip_lines"].values()), 18, options
				)
				card.pressed.connect(func(): _confirm_trade(host, fighter, slot, ability, id))
	)
	host.button("Decline / Back", func(): Router.transition("career_hub"))


static func _confirm_trade(
	host: MenuHost, fighter: Dictionary, slot: String, ability: String, id: String
) -> void:
	var confirm := ConfirmationDialog.new()
	confirm.dialog_text = (
		"Give up %s for %s? The ability will be removed from your loadout."
		% [ability.replace("_", " "), Router.career.limbs[id]["display_name"]]
	)
	host.add_child(confirm)
	confirm.canceled.connect(confirm.queue_free)
	confirm.confirmed.connect(
		func():
			var config := MatchConfig.new()
			config.fighter_ids = [fighter["id"], "atalanta"]
			var after: Dictionary = fighter["loadout"].duplicate(true)
			for category in after:
				after[category].erase(ability)
			config.loadouts = [after, Loadout.starter()]
			var normal := MatchLauncher.make_world(config).fighters[0].limbs.max_integrity
			var prior := Router.career.data.duplicate(true)
			if ObolTrade.accept(
				fighter,
				slot,
				ability,
				id,
				Router.career.limbs,
				normal,
				int(Router.career.data["rng_seed_counter"])
			):
				Router.career.data["rng_seed_counter"] += 1
				if Router.career.save.save_data(Router.career.data) == OK:
					Router.transition("career_hub")
				else:
					Router.career.data = prior
					host.message.text = "Could not save trade; no ability was spent."
			confirm.queue_free()
	)
	confirm.popup_centered(Vector2i(640, 220))


static func _body(host: MenuHost, fighter: Dictionary) -> void:
	var diagram := BodyDiagram.new()
	host.body.add_child(diagram)
	diagram.limbs = fighter["limbs"].duplicate(true)
	diagram.queue_redraw()
