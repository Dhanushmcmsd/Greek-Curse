extends SceneTree


func _initialize() -> void:
	var scene := load("res://assets/generated/models/fighter_theron.glb") as PackedScene
	var model := scene.instantiate()
	root.add_child(model)
	model.print_tree_pretty()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mat: StandardMaterial3D = node.mesh.surface_get_material(0)
		print(node.name, " parent=", node.get_parent().name, " vcol=", mat.vertex_color_use_as_albedo,
			" color=", mat.albedo_color, " arrays=", node.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size())
	model.free()
	quit()
