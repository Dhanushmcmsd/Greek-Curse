class_name SettingsPanel
extends VBoxContainer
var display_before: Dictionary = {}
var display_timer: Timer
var display_notice: Label
var restoring: bool = false


func _ready() -> void:
	display_timer = Timer.new()
	display_timer.one_shot = true
	display_timer.wait_time = 10
	display_timer.timeout.connect(_revert_display)
	add_child(display_timer)
	display_notice = Label.new()
	display_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(display_notice)
	var keep := Button.new()
	keep.text = "Keep display changes"
	keep.pressed.connect(
		func():
			display_before.clear()
			display_timer.stop()
			display_notice.text = "Display settings kept."
	)
	add_child(keep)
	var sample := Button.new()
	sample.text = "Play sample sound"
	sample.pressed.connect(func(): Audio.play_sound("block"))
	add_child(sample)
	Settings.changed.connect(_display_changed)

	for key in Settings.defaults:
		if key in ["bindings", "age_gate_accepted", "content_warning_seen", "patterns"]:
			continue
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = key.replace("_", " ").capitalize()
		label.custom_minimum_size.x = 320
		row.add_child(label)
		var value: Variant = Settings.values[key]
		if value is bool:
			var toggle := CheckButton.new()
			toggle.button_pressed = value
			toggle.toggled.connect(func(enabled: bool): Settings.set_value(key, enabled))
			row.add_child(toggle)
		elif key == "ui_scale_percent":
			var scales := [100, 125, 150, 200]
			var options := OptionButton.new()
			for amount in scales:
				options.add_item(str(amount) + "%")
			options.select(scales.find(int(value)))
			options.item_selected.connect(func(index: int): Settings.set_value(key, scales[index]))
			row.add_child(options)
		elif value is int or value is float:
			var slider := HSlider.new()
			slider.min_value = 100 if key == "ui_scale_percent" else 0
			slider.max_value = 200 if key == "ui_scale_percent" else 100
			slider.step = 25 if key == "ui_scale_percent" else 5
			slider.value = value
			slider.custom_minimum_size.x = 300
			var number := Label.new()
			number.text = str(int(value)) + "%"
			slider.value_changed.connect(
				func(amount: float):
					Settings.set_value(key, int(amount))
					number.text = str(int(amount)) + "%"
			)
			row.add_child(number)
			row.add_child(slider)
		else:
			var options := OptionButton.new()
			var choices: Array = {
				"gore": ["off", "low", "normal", "max"],
				"blood_color": ["red", "green", "golden"],
				"resolution": ["1280x720", "1600x900", "1920x1080"]
			}[key]
			for item in choices:
				options.add_item(item)
			options.select(choices.find(value))
			options.item_selected.connect(func(index: int): Settings.set_value(key, choices[index]))
			row.add_child(options)
		add_child(row)


func _display_changed(key: String, _value: Variant) -> void:
	if restoring or key not in ["fullscreen", "resolution", "vsync"]:
		return
	if display_before.is_empty():
		var size := DisplayServer.window_get_size()
		display_before = {
			"fullscreen": DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
			"resolution": "%dx%d" % [size.x, size.y],
			"vsync": DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
		}
	_apply_display()
	display_timer.start()
	display_notice.text = "Display changed. Choose Keep within 10 seconds, or it will revert."


func _apply_display() -> void:
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if Settings.values["fullscreen"]
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)
	var dimensions: PackedStringArray = str(Settings.values["resolution"]).split("x")
	if not Settings.values["fullscreen"]:
		DisplayServer.window_set_size(Vector2i(int(dimensions[0]), int(dimensions[1])))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if Settings.values["vsync"] else DisplayServer.VSYNC_DISABLED
	)


func _revert_display() -> void:
	if display_before.is_empty():
		return
	restoring = true
	for key in display_before:
		Settings.set_value(key, display_before[key])
	_apply_display()
	display_before.clear()
	restoring = false
	display_notice.text = "Previous display settings restored."


func _exit_tree() -> void:
	_revert_display()
