class_name ResultsStub
extends CanvasLayer

signal new_match_requested
signal limbs_requested
var summary: Label


func _ready() -> void:
	call_deferred("_apply_theme")
	for child in get_children():
		if child is Control:
			child.theme = GameTheme.build()
	layer = 10
	var panel := ColorRect.new()
	panel.size = Vector2(1280, 720)
	panel.color = Color("101722")
	add_child(panel)
	var title := Label.new()
	title.text = "TRIAL COMPLETE"
	title.position = Vector2(120, 50)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("e4bc6b"))
	add_child(title)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(120, 125)
	scroll.size = Vector2(1040, 440)
	add_child(scroll)
	summary = Label.new()
	summary.add_theme_font_size_override("font_size", 24)
	scroll.add_child(summary)
	for index in 2:
		var button := Button.new()
		button.text = "New match" if index == 0 else "Choose replacement limbs"
		button.position = Vector2(120 + index * 460, 610)
		button.size = Vector2(420, 55)
		button.pressed.connect(
			func():
				if index == 0:
					new_match_requested.emit()
				else:
					limbs_requested.emit()
		)
		add_child(button)
	visible = false


func show_results(world: SimWorld, damage: Array, longest: Array) -> void:
	visible = true
	var winner := 0 if world.wins[0] > world.wins[1] else 1
	summary.text = (
		"%s WINS\nRounds %d : %d\nDamage %d : %d\nLongest combo %d : %d\n"
		% [
			world.fighters[winner].display_name,
			world.wins[0],
			world.wins[1],
			damage[0],
			damage[1],
			longest[0],
			longest[1]
		]
	)
	for record in world.amputations:
		summary.text += (
			"%s -> %s\n" % [world.fighters[record["attacker"]].display_name, record["limb"]]
		)


func _apply_theme() -> void:
	for child in get_children():
		if child is Control:
			child.theme = GameTheme.build()
