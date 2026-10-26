class_name LimbCard
extends Button

var limb_id: String
var preview: SubViewport


func setup(id: String, title: String, fighter_id: String = "theron", slot: String = "") -> void:
	limb_id = id
	text = title
	custom_minimum_size = Vector2(260, 230)
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	expand_icon = true
	preview = SubViewport.new()
	preview.size = Vector2i(256, 180)
	preview.transparent_bg = true
	preview.own_world_3d = true
	preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(preview)
	if slot.is_empty():
		var data: Dictionary = DataLoader.new().load_json("res://data/limbs/%s.json" % id).value
		slot = str(data["slot"]) + "_l"
	var path := "res://assets/limbs_elemental/elemental_%s_%s.glb" % [fighter_id, slot]
	var model := ModelLoader.instantiate_scene(path)
	if model == null:
		return
	ModelLoader.prepare_materials(model)
	preview.add_child(model)
	var camera := Camera3D.new()
	preview.add_child(camera)
	var bounds := AABB()
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = mesh.global_transform * mesh.get_aabb()
		bounds = bounds.merge(box) if bounds.has_volume() else box
	var center := bounds.get_center()
	camera.position = center + Vector3(0.4, 0.1, 2.0)
	camera.look_at(center)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(bounds.size.y, bounds.size.x) * 1.4
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -35, 0)
	light.light_energy = 1.8
	preview.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1, 0, 1)
	fill.light_energy = 0.9
	preview.add_child(fill)
	icon = preview.get_texture()
