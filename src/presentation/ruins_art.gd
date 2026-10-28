class_name RuinsArt
extends RefCounted
## Original ruined-temple dressing using CC0 scanned stone, shared by arena meshes.


static func install(model: Node3D, stage: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://assets/environment/ruins/olympus_flagstones.png")
	stone.normal_enabled = true
	stone.normal_texture = load("res://assets/environment/ruins/rock_normal.jpg")
	stone.normal_scale = 0.35
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	stone.roughness_texture = null
	stone.roughness = 0.95
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE * 0.35
	stone.albedo_color = Color(0.42, 0.44, 0.46)
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color(0.25, 0.16, 0.065)
	bronze.metallic = 0.75
	bronze.roughness = 0.48
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.hide()
	var floor_mesh := MeshInstance3D.new()
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(32, 22)
	floor_mesh.mesh = floor_plane
	var floor_material := ShaderMaterial.new()
	floor_material.shader = load("res://assets/shaders/ruins_floor.gdshader")
	floor_material.set_shader_parameter("stone", stone.albedo_texture)
	floor_material.set_shader_parameter("stone_normal", stone.normal_texture)
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	floor_mesh.position = Vector3(0, -0.015, -4)
	var backdrop := MeshInstance3D.new()
	var plane := QuadMesh.new()
	plane.size = Vector2(40, 22.5)
	backdrop.mesh = plane
	var matte := ShaderMaterial.new()
	matte.shader = load("res://assets/shaders/arena_backdrop.gdshader")
	matte.set_shader_parameter(
		"backdrop", load("res://assets/environment/ruins/olympus_backdrop.png")
	)
	backdrop.material_override = matte
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stage.add_child(backdrop)
	backdrop.position = Vector3(0, 3.4, -10)
	# Architectural silhouettes ground the arena in front of the distant matte.
	for side in [-1.0, 1.0]:
		for depth in [-3.0, -6.5]:
			var column := Node3D.new()
			stage.add_child(column)
			column.position = Vector3(side * (5.1 if depth == -3.0 else 6.3), 0, depth)
			_stone_part(column, stone, Vector3(0, 0.12, 0), Vector3(0.95, 0.24, 0.95))
			_stone_part(column, stone, Vector3(0, 2.75, 0), Vector3(0.9, 0.22, 0.9))
			var shaft := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.26
			cylinder.bottom_radius = 0.33
			cylinder.height = 2.45
			cylinder.radial_segments = 20
			shaft.mesh = cylinder
			shaft.material_override = stone
			column.add_child(shaft)
			shaft.position.y = 1.45
			for ring_height in [0.3, 0.42, 2.53, 2.64]:
				_stone_part(column, stone, Vector3(0, ring_height, 0), Vector3(0.73, 0.09, 0.73))
	_install_pillar_mist(stage)
	for x in [-4.3, 4.3]:
		_stone_part(stage, stone, Vector3(x, 0.35, -0.15), Vector3(0.36, 0.7, 0.36))
		var bowl := MeshInstance3D.new()
		var basin := CylinderMesh.new()
		basin.top_radius = 0.3
		basin.bottom_radius = 0.14
		basin.height = 0.18
		basin.radial_segments = 24
		bowl.mesh = basin
		bowl.material_override = bronze
		stage.add_child(bowl)
		bowl.position = Vector3(x, 0.79, -0.15)
	for x in [-4.3, 4.3]:
		var fire := OmniLight3D.new()
		fire.position = Vector3(x, 1.3, 0.2)
		fire.light_color = Color(1, 0.37, 0.12)
		fire.light_energy = 1.2
		fire.omni_range = 4.0
		stage.add_child(fire)
		var flame := CPUParticles3D.new()
		flame.amount = 22
		flame.lifetime = 0.8
		flame.direction = Vector3.UP
		flame.spread = 12
		flame.initial_velocity_min = 0.3
		flame.initial_velocity_max = 0.8
		flame.gravity = Vector3(0, 0.4, 0)
		flame.scale_amount_min = 0.08
		flame.scale_amount_max = 0.22
		var quad := QuadMesh.new()
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.billboard_keep_scale = true
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mat.albedo_texture = load("res://assets/vfx/soft_flame.png")
		mat.vertex_color_use_as_albedo = true
		quad.material = mat
		flame.mesh = quad
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 0.8, 0.25, 0.7))
		ramp.set_color(1, Color(0.8, 0.08, 0.01, 0))
		flame.color_ramp = ramp
		stage.add_child(flame)
		flame.position = Vector3(x, 0.95, -0.15)


static func _stone_part(parent: Node3D, material: Material, at: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	parent.add_child(mesh)
	mesh.position = at


static func _install_pillar_mist(stage: Node3D) -> void:
	var atlas := load("res://assets/vfx/exported/smoke_flipbook.png")
	var shader := load("res://assets/shaders/pillar_mist.gdshader")
	for side in [-1.0, 1.0]:
		for layer in 3:
			var plume := MeshInstance3D.new()
			plume.name = "PillarMist"
			var quad := QuadMesh.new()
			quad.size = Vector2(2.4 + layer * 0.25, 1.4)
			plume.mesh = quad
			plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var material := ShaderMaterial.new()
			material.shader = shader
			material.set_shader_parameter("smoke_atlas", atlas)
			material.set_shader_parameter(
				"phase", float(layer) * 0.31 + (0.15 if side < 0 else 0.0)
			)
			plume.material_override = material
			stage.add_child(plume)
			plume.position = Vector3(
				side * (4.9 + layer * 0.15), 0.45 + layer * 0.22, -1.8 + layer * 0.18
			)
