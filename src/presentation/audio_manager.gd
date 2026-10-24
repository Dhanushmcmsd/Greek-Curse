extends Node
var mapping: Dictionary = {}
var dispatched: int = 0
var pool: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var presentation_rng := RandomNumberGenerator.new()


func _ready() -> void:
	presentation_rng.seed = 1907
	mapping = JSON.parse_string(FileAccess.get_file_as_string("res://data/audio/event_map.json"))
	for bus in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	for index in 12:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		pool.append(player)
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	add_child(music)
	Settings.changed.connect(func(_key: String, _value: Variant): apply_volumes())
	apply_volumes()


func apply_volumes() -> void:
	for bus in ["Master", "Music", "SFX", "UI"]:
		var value := float(Settings.values.get(bus.to_lower() + "_volume", 80)) / 100.0
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bus), linear_to_db(maxf(.0001, value))
		)


func play_sound(id: String, ui: bool = false) -> void:
	dispatched += 1
	if DisplayServer.get_name() == "headless":
		return
	var path := "res://assets/audio/sfx/%s.wav" % id
	if not ResourceLoader.exists(path):
		return
	for player in pool:
		if not player.playing:
			player.bus = "UI" if ui else "SFX"
			player.stream = load(path)
			player.pitch_scale = presentation_rng.randf_range(.94, 1.06)
			player.play()
			return


func consume(events: Array) -> void:
	for event in events:
		var key: String = SimEvent.Kind.keys()[event.kind]
		var id: String = mapping.get(key, "whoosh")
		if key == "HIT":
			var material: String = event.payload.get(
				"material", "bone" if event.payload.has("limb") else "flesh"
			)
			id = ("heavy_" if event.amount >= 25 else "light_") + material
		if key == "ABILITY" and str(event.payload.get("id", "")).begins_with("zeus"):
			id = "lightning"
		if key == "HAZARD":
			id = "lava" if event.payload.get("type", "") == "lava" else "lightning"
		play_sound(id)


func switch_music(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path := "res://assets/audio/music/%s.wav" % id
	if not ResourceLoader.exists(path):
		return
	var old := music
	music = AudioStreamPlayer.new()
	music.bus = "Music"
	music.stream = load(path).duplicate()
	if music.stream is AudioStreamWAV:
		music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music.stream.loop_end = music.stream.data.size() / 2
	music.volume_db = -40
	add_child(music)
	music.play()
	create_tween().tween_property(music, "volume_db", 0.0, .6)
	var fade := create_tween()
	fade.tween_property(old, "volume_db", -50.0, .6)
	fade.tween_callback(old.queue_free)


func shutdown() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null


func _exit_tree() -> void:
	shutdown()
