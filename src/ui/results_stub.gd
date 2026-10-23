class_name ResultsStub
extends CanvasLayer

signal new_match_requested
signal limbs_requested
var summary: Label


func _ready() -> void:
	layer = 10
	var panel := ColorRect.new()
	panel.position = Vector2(360, 250)
	panel.size = Vector2(600, 300)
	panel.color = Color(0.06, 0.08, 0.12, 0.94)
	add_child(panel)
	summary = Label.new()
	summary.position = Vector2(400, 270)
	summary.add_theme_font_size_override("font_size", 24)
	add_child(summary)
	for index in 2:
		var button := Button.new()
		button.text = "New match" if index == 0 else "Replacement limbs"
		button.position = Vector2(400 + index * 250, 505)
		button.size = Vector2(230, 36)
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
	summary.text += "\nR: rematch | 1/2/3: controller mode"
