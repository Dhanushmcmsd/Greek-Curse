class_name LimbCard
extends Button

var limb_id: String
var preview: SubViewport


func setup(id: String, title: String) -> void:
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
	var model := ModelLoader.load_model("res://assets/generated/models/limb_%s.glb" % id).root
	preview.add_child(model)
	var camera := Camera3D.new()
	preview.add_child(camera)
	camera.position = Vector3(1.1, -0.15, 1.9)
	camera.look_at(Vector3(0, -0.4, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.2
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -35, 0)
	light.light_energy = 1.8
	preview.add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(-1, 0, 1)
	fill.light_energy = 0.9
	preview.add_child(fill)
	icon = preview.get_texture()
