extends Node
signal changed(key: String, value: Variant)
var values: Dictionary = {}
var defaults: Dictionary = {}
var path: String = "user://settings.cfg"


func _ready() -> void:
	defaults = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/ui/settings_defaults.json")
	)
	var args := OS.get_cmdline_user_args()
	var index := args.find("--user-profile")
	if index >= 0 and index + 1 < args.size():
		var directory := ProjectSettings.globalize_path(args[index + 1])
		DirAccess.make_dir_recursive_absolute(directory)
		path = directory.path_join("settings.cfg")
	load_settings()
	apply_display()


func validate(key: String, value: Variant) -> Variant:
	var fallback: Variant = defaults.get(key)
	if not defaults.has(key):
		return null
	if key.ends_with("volume") or key.ends_with("percent"):
		return _number(key, value, fallback)
	if fallback is bool:
		return value if value is bool and key != "patterns" else fallback
	var choices := {
		"gore": ["off", "low", "normal", "max"],
		"blood_color": ["red", "green", "golden"],
		"resolution": ["1280x720", "1600x900", "1920x1080"]
	}
	if choices.has(key):
		return value if value in choices[key] else fallback
	if key == "bindings":
		if not value is Dictionary:
			value = {}
		var bindings := InputBindings.new()
		return value if bindings.import_bindings(value) == "" else {}
	return fallback


func set_value(key: String, value: Variant, persist: bool = true) -> void:
	var checked: Variant = validate(key, value)
	if checked == null:
		return
	values[key] = checked
	SettingsHooks.values[key] = checked
	changed.emit(key, checked)
	if persist:
		save_settings()


func load_settings() -> void:
	values = defaults.duplicate(true)
	var config := ConfigFile.new()
	var code := config.load(path)
	if code != OK and code != ERR_FILE_NOT_FOUND:
		DirAccess.copy_absolute(path, path + ".bad")
		Log.warn("settings", "Unreadable settings backed up; defaults restored")
	if code == OK:
		for key in defaults:
			values[key] = validate(key, config.get_value("settings", key, defaults[key]))
	SettingsHooks.values = values.duplicate(true)


func save_settings() -> Error:
	var config := ConfigFile.new()
	config.set_value("meta", "version", 1)
	for key in values:
		config.set_value("settings", key, values[key])
	return config.save(path)


func migrate(source: Dictionary, _from_version: int) -> Dictionary:
	return source.duplicate(true)


func _number(key: String, value: Variant, fallback: Variant) -> Variant:
	if not (value is float or value is int):
		return fallback
	if key == "ui_scale_percent":
		return int(value) if int(value) in [100, 125, 150, 200] else 100
	return clampi(int(value), 0, 100)


func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if values["fullscreen"]
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
	)
	var dimensions := str(values["resolution"]).split("x")
	if not values["fullscreen"]:
		DisplayServer.window_set_size(Vector2i(int(dimensions[0]), int(dimensions[1])))
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if values["vsync"] else DisplayServer.VSYNC_DISABLED
	)
