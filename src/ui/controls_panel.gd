class_name ControlsPanel

extends VBoxContainer

var bindings := InputBindings.new()

var waiting: String = ""

var status: Label


func _ready() -> void:
	bindings.reset_defaults()

	if not Settings.values["bindings"].is_empty():
		bindings.import_bindings(Settings.values["bindings"])

	status = Label.new()

	status.text = "Select an action, then press a key or gamepad button. Escape cancels."

	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	add_child(status)

	for action in bindings.bindings:
		var button := Button.new()

		button.text = action + " — " + str(bindings.bindings[action])

		button.pressed.connect(
			func():
				waiting = action
				status.text = "Press a key/button for " + action
		)

		add_child(button)

	var reset := Button.new()

	reset.text = "Reset controls"

	reset.pressed.connect(
		func():
			bindings.reset_defaults()
			_save()
	)

	add_child(reset)


func _unhandled_input(event: InputEvent) -> void:
	if waiting == "":
		return

	var entry: Dictionary = bindings.bindings[waiting].duplicate()

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			waiting = ""

			return

		entry["key"] = OS.get_keycode_string(event.physical_keycode)

	elif event is InputEventJoypadButton and event.pressed:
		entry["button"] = event.button_index

		entry["device"] = event.device

	else:
		return

	var error := bindings.rebind(waiting, entry)

	status.text = error if error != "" else "Bound " + waiting

	if error == "":
		_save()

		waiting = ""

	get_viewport().set_input_as_handled()


func _save() -> void:
	Settings.set_value("bindings", bindings.export_bindings())

	bindings.install()
