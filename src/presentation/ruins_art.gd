class_name RuinsArt
extends RefCounted
## Original ruined-temple dressing using CC0 scanned stone, shared by arena meshes.


static func install(model: Node3D, stage: Node3D) -> void:
	var stone := StandardMaterial3D.new()
	stone.albedo_texture = load("res://assets/environment/ruins/rock_diffuse.jpg")
	stone.normal_enabled = true
	stone.normal_texture = load("res://assets/environment/ruins/rock_normal.jpg")
	stone.normal_scale = 0.35
	stone.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	stone.roughness_texture = null
	stone.roughness = 0.95
	stone.uv1_triplanar = true
	stone.uv1_world_triplanar = true
	stone.uv1_scale = Vector3.ONE * 0.7
	stone.albedo_color = Color(0.12, 0.15, 0.18)
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
	floor_material.set_shader_parameter(
		"stone", load("res://assets/environment/ruins/olympus_flagstones.png")
	)
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
	var rng := RandomNumberGenerator.new()
	rng.seed = 28102026
	for i in 35:
		var rock := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 9
		sphere.rings = 5
		rock.mesh = sphere
		rock.material_override = stone
		stage.add_child(rock)
		var side := -1.0 if i % 2 == 0 else 1.0
		rock.position = Vector3(
			side * rng.randf_range(4.8, 8.0), rng.randf_range(-0.2, 0.1), rng.randf_range(-4.0, 0.5)
		)
		rock.scale = Vector3(
			rng.randf_range(0.4, 1.7), rng.randf_range(0.4, 1.2), rng.randf_range(0.5, 1.4)
		)
		rock.scale *= 0.35
		rock.rotation = Vector3(rng.randf(), rng.randf() * TAU, rng.randf())
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
