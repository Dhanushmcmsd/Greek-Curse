extends Control


func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var panel := SettingsPanel.new()
	panel.theme = GameTheme.build()
	scroll.add_child(panel)
