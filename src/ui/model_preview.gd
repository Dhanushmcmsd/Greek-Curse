class_name ModelPreview
extends TextureRect
var view: FighterView
var fighter: SimFighter
var _pose_accumulator: float = 0.0


func setup(id: String, palette: String = "default", npc: bool = false, arena: bool = false) -> void:
	# Re-selection replaces the old viewport instead of leaving invisible rigs rendering.
	for child in get_children():
		remove_child(child)
		child.queue_free()
	view = null
	fighter = null
	custom_minimum_size = Vector2(220, 250)
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var viewport := SubViewport.new()
	viewport.size = Vector2i(300, 340)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	if arena:
		viewport.add_child(
			ModelLoader.load_model("res://assets/generated/models/arena_%s.glb" % id).root
		)
	elif npc:
		viewport.add_child(
			ModelLoader.load_model("res://assets/generated/models/npc_obol.glb").root
		)
	else:
		var config := MatchConfig.new()
		config.fighter_ids = [id, "atalanta"]
		fighter = MatchLauncher.make_world(config).fighters[0]
		fighter.x = 0
		view = FighterView.new()
		view.setup(Color.WHITE, fighter.height_mm, fighter.body_width_mm, id)
		viewport.add_child(view)
		view.rig.apply_palette(palette)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(3, 1.5, 4)
	camera.look_at(Vector3(0, 0.8 if npc else 1.0, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.8 if npc else 2.6
	if arena:
		camera.position = Vector3(6, 5, 9)
		camera.look_at(Vector3(0, 1, 0))
		camera.size = 12
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-30, -35, 0)
	key.light_energy = 1.2
	viewport.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1, 1, 2)
	fill.light_energy = .7
	viewport.add_child(fill)
	texture = viewport.get_texture()


func _process(delta: float) -> void:
	_pose_accumulator = minf(_pose_accumulator + delta, 4.0 / 60.0)
	while view != null and _pose_accumulator >= 1.0 / 60.0:
		view.show_fighter(fighter)
		_pose_accumulator -= 1.0 / 60.0
