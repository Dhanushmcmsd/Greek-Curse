class_name MenuHost

extends Control

var panel: PanelContainer

var body: VBoxContainer

var battle: MatchController

var message: Label


func _ready() -> void:
	Router.changed.connect(_show)

	Settings.changed.connect(_settings_changed)

	var args := OS.get_cmdline_user_args()

	if "--autoplay" in args or "--ai-demo" in args or "--results-demo" in args:
		battle = MatchController.new()

		add_child(battle)

		return

	Router.start()

	if "--autoplay-smoke" in args or "--autoplay-career" in args:
		call_deferred("_smoke", "--autoplay-career" in args)


func _show(state: String) -> void:
	if panel != null:
		remove_child(panel)

		panel.queue_free()

		panel = null

	if state == "match":
		_launch_match()

		return

	if battle != null:
		remove_child(battle)

		battle.queue_free()

		battle = null

	panel = PanelContainer.new()

	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	panel.theme = GameTheme.build()

	add_child(panel)

	var margin := MarginContainer.new()

	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 36)

	panel.add_child(margin)

	var scroll := ScrollContainer.new()

	margin.add_child(scroll)

	body = VBoxContainer.new()

	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	body.add_theme_constant_override("separation", 14)

	scroll.add_child(body)

	var header := label("SEVERED  /  " + state.replace("_", " ").to_upper(), 28)

	header.add_theme_color_override("font_color", Color("f1cb7b"))

	message = label("", 18)

	match state:
		"age_gate":
			label(
				(
					"This game contains graphic fantasy violence and dismemberment. "
					+ "Are you 18 or older? This is a self-declaration, not age "
					+ "verification."
				)
			)

			button(
				"I am 18 or older",
				func():
					Settings.set_value("age_gate_accepted", true)
					Router.transition("content_warning")
			)

			button("Decline and quit", func(): get_tree().quit())

		"content_warning":
			label(
				(
					"Limbs can break and be severed. Career limb loss persists between "
					+ "matches. Fresh Body, Versus and Practice do not permanently "
					+ "change your Career body. Gore, blood colour, shake, hit-stop and "
					+ "flashes can be adjusted in Settings."
				)
			)

			button(
				"Continue",
				func():
					Settings.set_value("content_warning_seen", true)
					Router.transition("main_menu")
			)

		"main_menu":
			Audio.switch_music("menu")

			label("TRIALS OF OLYMPUS — local fighting game", 24)

			if Router.career.save.recovery != "":
				label(Router.career.save.recovery)

			button(
				(
					"Career — "
					+ (
						"New fighter"
						if Router.career.data.get("fighter", {}).is_empty()
						else "Continue"
					)
				),
				func(): Router.transition("career_hub")
			)

			for mode in ["fresh_body", "versus", "practice"]:
				button(mode.replace("_", " ").capitalize(), func(): Router.setup_mode(mode))

			button("Settings", func(): Router.transition("settings"))

			button("Credits and licences", func(): Router.transition("credits"))

			button("Quit", func(): get_tree().quit())

		"fresh_body_setup", "versus_setup", "practice_setup", "match_banner", "loadout":
			SetupScreens.build(self, state)

		"career_hub", "fighter_create", "obol", "chronicle", "retire", "offer":
			CareerScreens.build(self, state)

		"settings":
			var settings := SettingsPanel.new()

			body.add_child(settings)

			button("Controls and remapping", func(): Router.transition("controls"))

			button("Content warning", func(): Router.transition("content_warning"))

			button("Back", func(): Router.transition("main_menu"))

		"controls":
			var controls := ControlsPanel.new()

			body.add_child(controls)

			button("Back", func(): Router.transition("settings"))

		"results":
			label("VICTORY" if Router.result["won"] else "DEFEAT", 36)

			label(
				(
					"Rounds %s   Damage %s   Longest combo %d"
					% [Router.result["rounds"], Router.result["damage"], Router.result["combo"]]
				)
			)

			for credit in Router.result["amputations"]:
				label(
					(
						"Player %d took Player %d's %s"
						% [int(credit["attacker"]) + 1, int(credit["victim"]) + 1, credit["limb"]]
					)
				)

			button("Continue", Router.result_continue)

			if Router.config.mode != "career":
				button("Rematch", func(): Router.transition("match_banner"))

		"credits":
			var credits: Dictionary = JSON.parse_string(
				FileAccess.get_file_as_string("res://data/ui/credits.json")
			)

			label(credits["text"])

			button("Back", func(): Router.transition("main_menu"))

		"error":
			var details := TextEdit.new()

			details.text = Router.error_message

			details.custom_minimum_size.y = 250

			body.add_child(details)

			button("Return to menu", func(): Router.transition("main_menu"))

	_focus_first.call_deferred()


func label(text: String, size: int = 20, parent: Node = null) -> Label:
	var item := Label.new()

	item.text = text

	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	item.add_theme_font_size_override(
		"font_size", int(SettingsHooks.scale_amount(size, "ui_scale_percent"))
	)

	(parent if parent != null else body).add_child(item)

	return item


func button(text: String, action: Callable, parent: Node = null) -> Button:
	var item := Button.new()

	item.text = text

	item.custom_minimum_size.y = 46

	item.pressed.connect(
		func():
			Audio.play_sound("ui_click", true)
			action.call()
	)

	(parent if parent != null else body).add_child(item)

	return item


func choice(items: Array, selected: int, action: Callable, parent: Node = null) -> OptionButton:
	var item := OptionButton.new()

	for value in items:
		item.add_item(str(value).replace("_", " ").capitalize())

	item.select(maxi(0, selected))

	item.item_selected.connect(action)

	(parent if parent != null else body).add_child(item)

	return item


func _focus_first() -> void:
	if panel == null:
		return

	for child in panel.find_children("*", "BaseButton", true, false):
		if not child.disabled:
			child.grab_focus()

			break


func _settings_changed(key: String, _value: Variant) -> void:
	if key in ["ui_scale_percent", "high_contrast"] and panel != null:
		_show.call_deferred(Router.state)


func _launch_match() -> void:
	if Router.config.validate() != "":
		Router.fail(Router.config.validate())

		return

	battle = MatchController.new()

	battle.match_config = Router.config

	battle.managed = true

	battle.match_completed.connect(func(summary: Dictionary): Router.finish.call_deferred(summary))

	battle.menu_requested.connect(_quit_match)

	add_child(battle)


func _quit_match() -> void:
	if Router.config.mode == "career":
		var confirm := ConfirmationDialog.new()

		confirm.dialog_text = (
			"Leave this Career fight? Damage and results from this unfinished "
			+ "match will not be saved."
		)

		add_child(confirm)

		confirm.confirmed.connect(
			func():
				Router.transition("career_hub")
				confirm.queue_free()
		)

		confirm.canceled.connect(confirm.queue_free)

		confirm.popup_centered(Vector2i(620, 200))

	else:
		Router.transition("main_menu")


func _smoke(career_mode: bool) -> void:
	await FlowAutoplay.run(self, career_mode)


func _unhandled_input(event: InputEvent) -> void:
	if (
		event.is_action_pressed("ui_cancel")
		and Router.state not in ["main_menu", "age_gate", "boot", "match"]
	):
		if Router.state == "results":
			Router.result_continue()
		else:
			Router.back()
		get_viewport().set_input_as_handled()
