class_name PauseMenu
extends CanvasLayer

signal resume_requested
signal restart_requested
signal quit_requested

var panel: PanelContainer


func _ready() -> void:
	layer = 20
	panel = PanelContainer.new()
	panel.position = Vector2(430, 220)
	panel.custom_minimum_size = Vector2(420, 300)
	add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	for title in ["Resume", "Restart match", "Controls", "Quit to launcher"]:
		var button := Button.new()
		button.text = title
		box.add_child(button)
		button.pressed.connect(_pressed.bind(title))
	panel.visible = false


func show_menu(shown: bool) -> void:
	panel.visible = shown
	if shown:
		panel.get_child(0).get_child(0).grab_focus()


func _pressed(title: String) -> void:
	match title:
		"Resume":
			resume_requested.emit()
		"Restart match":
			restart_requested.emit()
		"Quit to launcher":
			quit_requested.emit()
		"Controls":
			var dialog := AcceptDialog.new()
			dialog.dialog_text = (
				"P1: A/D, J/K/L, Shift, Space, U/I"
				+ "\nP2: arrows, keypad 1/2/3, keypad 0/dot"
				+ "\nForward+punch: right arm. Down+kick: right leg. J+L: grab."
				+ "\nGamepad: stick, X/Y/A, RB/B, LT, RT+LT."
			)
			add_child(dialog)
			dialog.popup_centered()
