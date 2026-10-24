extends MatchController


func _ready() -> void:
	super._ready()
	var controls := HBoxContainer.new()
	controls.position = Vector2(350, 590)
	_match_tools.add_child(controls)
	for id in ["mount_olympus", "athens_colosseum", "tartarus_pits"]:
		var button := Button.new()
		button.text = id
		button.pressed.connect(
			func():
				match_config.arena_id = id
				for child in get_children():
					if child is ArenaBuilder:
						remove_child(child)
						child.queue_free()
				var arena := ArenaBuilder.new()
				arena.arena_id = id
				add_child(arena)
				_restart()
		)
		controls.add_child(button)
	var stress := Button.new()
	stress.text = "Gore stress"
	stress.pressed.connect(
		func():
			var gore := get_tree().get_first_node_in_group("gore_manager") as GoreManager
			for i in 100:
				gore.burst(Vector3(float(i % 9) - 4, 1, 0), false, true)
	)
	controls.add_child(stress)
