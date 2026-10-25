extends SceneTree

func _init():
	var glb = load("res://assets/fighters_mixamo/fighter_theron.glb")
	var inst = glb.instantiate()
	print("ALL DESCENDANTS OF fighter_theron.glb:")
	_print_tree(inst, "")
	quit(0)

func _print_tree(node: Node, indent: String):
	var extra := ""
	if node is MeshInstance3D:
		extra = " mesh=" + str(node.mesh.get_class() if node.mesh else "null") + " visible=" + str(node.visible)
		if node.mesh:
			extra += " aabb=" + str(node.mesh.get_aabb())
	print(indent, "- ", node.name, " (", node.get_class(), ")", extra)
	for c in node.get_children():
		_print_tree(c, indent + "  ")
