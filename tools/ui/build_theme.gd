extends SceneTree


func _initialize() -> void:
	var theme := GameTheme.build()
	quit(ResourceSaver.save(theme, "res://assets/ui/stone_bronze.tres"))
