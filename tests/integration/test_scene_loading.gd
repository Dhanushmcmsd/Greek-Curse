extends TestBase


func test_every_scene_instantiates() -> void:
	var paths: Array = []
	_find("res://scenes", paths)
	for path in paths:
		var resource := load(path) as PackedScene
		assert_true(resource != null, "loads " + path)
		if resource != null:
			var scene := resource.instantiate()
			assert_true(scene != null, "instantiates " + path)
			scene.free()


func _find(directory: String, paths: Array) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".tscn"):
			paths.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_find(directory.path_join(child), paths)
