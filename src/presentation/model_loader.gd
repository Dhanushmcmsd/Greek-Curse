class_name ModelLoader
extends RefCounted


class ModelInfo:
	extends RefCounted
	var root: Node3D
	var nodes: Dictionary = {}


static func load_model(path: String) -> ModelInfo:
	var info := ModelInfo.new()
	var scene := load(path) as PackedScene
	if scene == null:
		return info
	info.root = scene.instantiate()
	prepare_materials(info.root)
	_collect(info.root, info.nodes)
	return info


static func prepare_materials(root: Node) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null:
				material = material.duplicate()
				material.vertex_color_use_as_albedo = true
				mesh.set_surface_override_material(surface, material)


static func _collect(node: Node, nodes: Dictionary) -> void:
	nodes[str(node.name)] = node
	for child in node.get_children():
		_collect(child, nodes)
