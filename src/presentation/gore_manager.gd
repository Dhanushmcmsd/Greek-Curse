class_name GoreManager
extends Node3D
## Bounded cosmetic physics, never queried by the deterministic simulation.

var config: Dictionary
var chunks: Array[Node] = []
var floor_splats: Array[Node] = []
var wall_splats: Array[Node] = []
var particles: Array[Node] = []
var arena_id: String = "mount_olympus"


func _ready() -> void:
	add_to_group("gore_manager")
	config = DataLoader.new().load_json("res://data/art/vfx.json").value
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 2
	floor_body.collision_mask = 2
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12, 0.2, 5)
	collision.shape = shape
	collision.position.y = -0.1
	floor_body.add_child(collision)
	add_child(floor_body)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	for pool in [chunks, floor_splats, wall_splats, particles]:
		for i in range(pool.size() - 1, -1, -1):
			var node: Node = pool[i]
			var remaining := int(node.get_meta("expires", now + 1)) - now
			if node is MeshInstance3D and node.material_override is StandardMaterial3D:
				node.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				node.material_override.albedo_color.a = (
					float(node.get_meta("alpha", 1.0))
					* clampf(
						float(remaining) / minf(1500.0, float(node.get_meta("duration", 1500))),
						0.0,
						1.0
					)
				)
			if node is MeshInstance3D and node.material_override is ShaderMaterial:
				node.material_override.set_shader_parameter(
					"fade", clampf(float(remaining) / 1500.0, 0.0, 1.0)
				)
			if remaining <= 0:
				pool.remove_at(i)
				remove_child(node)
				node.queue_free()


func _register(node: Node, pool: Array, cap: int, seconds: float) -> void:
	while pool.size() >= cap:
		var old: Node = pool.pop_front()
		remove_child(old)
		old.queue_free()
	add_child(node)
	node.set_meta("expires", Time.get_ticks_msec() + int(seconds * 1000))
	node.set_meta("duration", seconds * 1000.0)
	if node is MeshInstance3D and node.material_override is StandardMaterial3D:
		node.set_meta("alpha", node.material_override.albedo_color.a)
	pool.append(node)


func blood_color() -> Color:
	return {"red": Color("a91830"), "green": Color("54b52b"), "golden": Color("edba44")}.get(
		SettingsHooks.get_value("blood_color"), Color("a91830")
	)


func debris(mesh: MeshInstance3D, pose: Transform3D, direction: float) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var body := RigidBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 2
	body.mass = 0.4
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.bounce = 0.35
	var posed := LimbFinish.posed_mesh(mesh)
	var geometry: Mesh = posed if posed != null else mesh.mesh
	if posed != null and mesh.is_inside_tree():
		pose = mesh.global_transform
	var box := geometry.get_aabb()
	var center := box.get_center()

	# Keep visual mesh and collision dimensions consistent:
	# Clamping oversize partitions at the transform/scale level so visual and collider match.
	var max_dim := maxf(box.size.x, maxf(box.size.y, box.size.z))
	var s := 1.0
	if max_dim > 1.5:
		s = 1.5 / max_dim

	var visual := MeshInstance3D.new()
	visual.mesh = geometry
	visual.position = -center * s
	visual.scale = Vector3.ONE * s
	for surface in mesh.mesh.get_surface_count():
		visual.set_surface_override_material(surface, mesh.get_active_material(surface))
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = (box.size * s).max(Vector3.ONE * 0.03)
	collision.shape = shape
	body.add_child(collision)
	_register(body, chunks, int(config["chunk_cap"]), float(config["chunk_lifetime"]))
	body.global_transform = Transform3D(pose.basis.orthonormalized(), pose * center)
	body.linear_velocity = Vector3(direction * 3.8, 4.5, randf_range(-1.2, 1.2))
	body.angular_velocity = Vector3(
		randf_range(3.0, 6.0), randf_range(2.0, 5.0) * direction, randf_range(4.0, 8.0)
	)
	# Arterial spray trailing the debris
	var spray := CPUParticles3D.new()
	spray.emitting = false
	spray.amount = 16
	spray.lifetime = 0.5
	spray.one_shot = false
	spray.explosiveness = 0.0
	spray.direction = Vector3(0, -1, 0)
	spray.spread = 25.0
	spray.initial_velocity_min = 0.3
	spray.initial_velocity_max = 1.0
	spray.gravity = Vector3(0, -6, 0)
	spray.color = blood_color()
	var spray_drop := SphereMesh.new()
	spray_drop.radius = 0.008
	spray_drop.height = 0.016
	var spray_mat := StandardMaterial3D.new()
	spray_mat.albedo_color = blood_color()
	spray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spray_drop.material = spray_mat
	spray.mesh = spray_drop
	body.add_child(spray)
	spray.emitting = true
	get_tree().create_timer(1.5).timeout.connect(func(): spray.emitting = false)


func burst(at: Vector3, blocked: bool, severed: bool = false) -> void:
	impact(at, blocked, severed)
	var off: bool = SettingsHooks.get_value("gore") == "off"
	var level: float = {"off": 0.0, "low": 0.4, "normal": 1.0, "max": 1.6}.get(
		SettingsHooks.get_value("gore"), 1.0
	)
	var effect := CPUParticles3D.new()
	effect.emitting = false
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.amount = 8 if blocked or off else int((28 if severed else 14) * level)
	effect.lifetime = 0.28 if severed else float(config["particle_lifetime"])
	effect.direction = Vector3(0, 1, 0)
	effect.spread = 45.0 if severed else 60.0
	effect.initial_velocity_min = 0.8
	effect.initial_velocity_max = 2.0 if severed else 1.4
	effect.gravity = Vector3(0, -9, 0)
	effect.color = Color("a0ddff") if blocked else Color("e3bd76") if off else blood_color()
	var drop := SphereMesh.new()
	drop.radius = 0.012 if not severed else 0.018
	drop.height = drop.radius * 2
	var material := StandardMaterial3D.new()
	material.albedo_color = effect.color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop.material = material
	effect.mesh = drop
	_register(effect, particles, int(config["particle_cap"]), effect.lifetime + 0.1)
	effect.global_position = at
	effect.emitting = true
	if not blocked and not off:
		splat(Vector3(at.x, 0.006, at.z), false)
		if absf(at.x) > 3.9:
			splat(Vector3(signf(at.x) * 4.6, at.y, at.z), true)


func splat(at: Vector3, wall: bool) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.19, 0.15)
	mesh.mesh = plane
	var stain := ShaderMaterial.new()
	stain.shader = load("res://src/presentation/stain.gdshader")
	stain.set_shader_parameter("blood", blood_color())
	mesh.material_override = stain
	_register(
		mesh,
		wall_splats if wall else floor_splats,
		int(config["wall_cap"] if wall else config["floor_cap"]),
		8.0 if arena_id == "athens_colosseum" else 20.0
	)
	mesh.global_position = at
	if wall:
		mesh.rotation.z = PI / 2


func impact(at: Vector3, blocked: bool, severed: bool = false) -> void:
	var reduced := bool(SettingsHooks.get_value("flash_reduction"))
	var color := Color("81d8ff") if blocked else Color("ffb24f")
	var effect := CPUParticles3D.new()
	effect.emitting = false
	effect.amount = 12 if reduced else (48 if severed else 30)
	effect.lifetime = 0.32 if blocked else 0.42
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.local_coords = false
	effect.direction = Vector3.UP
	effect.spread = 180.0
	effect.initial_velocity_min = 1.1
	effect.initial_velocity_max = 4.4 if severed else 3.1
	effect.gravity = Vector3(0, -3.5, 0)
	effect.angle_min = -180.0
	effect.angle_max = 180.0
	effect.damping_min = 2.0
	effect.damping_max = 4.0
	var streak := QuadMesh.new()
	streak.size = Vector2(0.018, 0.13)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = color * (0.55 if reduced else 1.0)
	mat.no_depth_test = false
	streak.material = mat
	effect.mesh = streak
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	effect.color_ramp = gradient
	_register(effect, particles, int(config["particle_cap"]), 0.55)
	effect.global_position = at
	effect.emitting = true
	var flash := MeshInstance3D.new()
	var disc := QuadMesh.new()
	disc.size = Vector2.ONE * (1.0 if severed else 0.65)
	flash.mesh = disc
	var shader := ShaderMaterial.new()
	shader.shader = load("res://src/presentation/impact.gdshader")
	shader.set_shader_parameter("tint", color)
	shader.set_shader_parameter("strength", 0.35 if reduced else 1.0)
	shader.set_shader_parameter("guard", blocked)
	flash.material_override = shader
	_register(flash, particles, int(config["particle_cap"]), 0.28)
	flash.global_position = at + Vector3(0, 0, 0.08)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * 2.0, 0.24)
	tween.tween_method(
		func(v: float): shader.set_shader_parameter("strength", v),
		0.35 if reduced else 1.0,
		0.0,
		0.24
	)


func ooze(at: Vector3) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var effect := CPUParticles3D.new()
	effect.emitting = false
	effect.amount = 3
	effect.lifetime = 0.65
	effect.one_shot = true
	effect.explosiveness = 0.25
	effect.local_coords = false
	effect.direction = Vector3.DOWN
	effect.spread = 12.0
	effect.initial_velocity_min = 0.1
	effect.initial_velocity_max = 0.3
	effect.gravity = Vector3(0, -5, 0)
	var drop := SphereMesh.new()
	drop.radius = 0.009
	drop.height = 0.032
	var mat := StandardMaterial3D.new()
	mat.albedo_color = blood_color()
	mat.roughness = 0.2
	drop.material = mat
	effect.mesh = drop
	_register(effect, particles, int(config["particle_cap"]), 0.8)
	effect.global_position = at
	effect.emitting = true
	splat(Vector3(at.x, 0.007, at.z), false)


func trail(from: Vector3, to: Vector3) -> void:
	if bool(SettingsHooks.get_value("flash_reduction")) or from.distance_to(to) < 0.025:
		return
	var mesh := MeshInstance3D.new()
	var ribbon := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color = Color(0.9, 0.6, 0.24, 0.3)
	var width := Vector3.UP * 0.035
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in [from - width, from + width, to + width, from - width, to + width, to - width]:
		ribbon.surface_add_vertex(point)
	ribbon.surface_end()
	mesh.mesh = ribbon
	mesh.material_override = mat
	_register(mesh, particles, int(config["particle_cap"]), 0.12)
