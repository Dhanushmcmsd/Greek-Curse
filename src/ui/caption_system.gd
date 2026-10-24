class_name CaptionSystem
extends CanvasLayer
var lines: Dictionary = {}
var label: Label
var remaining: float = 0.0


func _ready() -> void:
	lines = JSON.parse_string(FileAccess.get_file_as_string("res://data/ui/captions_en.json"))
	label = Label.new()
	label.position = Vector2(180, 570)
	label.size = Vector2(920, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	add_child(label)


func consume(events: Array) -> void:
	for event in events:
		var key: String = str(event.payload.get("id", SimEvent.Kind.keys()[event.kind]))
		if lines.has(key):
			label.text = lines[key]
			remaining = 2.5


func _process(delta: float) -> void:
	remaining -= delta
	label.visible = remaining > 0 and bool(SettingsHooks.get_value("subtitles"))
	label.add_theme_font_size_override(
		"font_size", int(20 * float(SettingsHooks.get_value("ui_scale_percent")) / 100.0)
	)
