extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene = load("res://scenes/menus/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await scene._smoke(true)
