class_name ModelLoader
extends RefCounted

static var _source_scenes: Dictionary = {}


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


static func instantiate_scene(path: String, force_source: bool = false) -> Node3D:
	# An editor that was open during git pull can retain a .scn built from the
	# previous GLB. ResourceLoader.CACHE_MODE_IGNORE still loads that stale .scn.
	# Compare the import's recorded source hash and use the actual GLB if needed.
	if (
		not path.ends_with(".glb")
		or not FileAccess.file_exists(path)
		or (not force_source and _import_matches_source(path))
	):
		var packed := load(path) as PackedScene
		return packed.instantiate() as Node3D if packed != null else null
	var digest := FileAccess.get_md5(path)
	if _source_scenes.has(path) and _source_scenes[path]["digest"] == digest:
		return (_source_scenes[path]["scene"] as PackedScene).instantiate() as Node3D
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if document.append_from_file(path, state) != OK:
		push_error("Cannot read current model source: " + path)
		return null
	var generated := document.generate_scene(state) as Node3D
	if generated == null:
		return null
	var packed := PackedScene.new()
	if packed.pack(generated) != OK:
		generated.free()
		return null
	generated.free()
	_source_scenes[path] = {"digest": digest, "scene": packed}
	return packed.instantiate() as Node3D


static func _import_matches_source(path: String) -> bool:
	var config := ConfigFile.new()
	if config.load(path + ".import") != OK:
		return false
	var imported_path: String = config.get_value("remap", "path", "")
	var metadata_path := imported_path.get_basename() + ".md5"
	if not FileAccess.file_exists(metadata_path):
		return false
	var metadata := FileAccess.get_file_as_string(metadata_path)
	var marker := 'source_md5="'
	if not metadata.contains(marker):
		return false
	var imported_digest := metadata.get_slice(marker, 1).get_slice('"', 0)
	return imported_digest == FileAccess.get_md5(path)


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
