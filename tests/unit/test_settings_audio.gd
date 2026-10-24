extends TestBase


func test_settings_clamp_roundtrip_and_corrupt_recovery() -> void:
	var script = load("res://src/persistence/settings_service.gd")
	var service = script.new()
	service.defaults = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/ui/settings_defaults.json")
	)
	service.path = "user://settings_test.cfg"
	service.values = service.defaults.duplicate(true)
	service.set_value("master_volume", 400, false)
	service.set_value("gore", "invalid", false)
	assert_eq(service.values["master_volume"], 100, "volume clamped")
	assert_eq(service.values["gore"], "normal", "invalid enum defaults")
	assert_eq(service.save_settings(), OK, "save")
	service.load_settings()
	assert_eq(service.values["master_volume"], 100, "round trip")
	var file := FileAccess.open(service.path, FileAccess.WRITE)
	file.store_string("[broken")
	file.close()
	service.load_settings()
	assert_true(FileAccess.file_exists(service.path + ".bad"), "corrupt backup")
	assert_eq(service.values["master_volume"], 80, "defaults recovered")
	SettingsHooks.values = Settings.values.duplicate(true)
	service.free()


func test_audio_event_map_complete() -> void:
	for name in SimEvent.Kind.keys():
		assert_true(Audio.mapping.has(name), "audio for " + name)


func test_caption_severance_event() -> void:
	var captions := CaptionSystem.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(captions)
	captions.consume([SimEvent.make(SimEvent.Kind.LIMB_SEVERED, 0, 1, 0, 1, -1)])
	assert_true(captions.label.text.contains("Fates"), "amputation caption")
	captions.free()
