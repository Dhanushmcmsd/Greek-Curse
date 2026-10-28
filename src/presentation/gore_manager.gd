class_name GoreManager
extends Node3D
## Bounded cosmetic physics, never queried by the deterministic simulation.

const STREAK_TEXTURE = preload("res://assets/vfx/impact_streak.png")

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
	# Enhanced debris velocity — MK-style explosive separation
	body.linear_velocity = Vector3(direction * 4.8, 5.5, randf_range(-1.8, 1.8))
	body.angular_velocity = Vector3(
		randf_range(4.0, 8.0), randf_range(3.0, 7.0) * direction, randf_range(5.0, 12.0)
	)
	# Arterial spray trailing the debris
	var spray := CPUParticles3D.new()
	spray.emitting = false
	spray.amount = 20
	spray.lifetime = 0.6
	spray.one_shot = false
	spray.explosiveness = 0.0
	spray.direction = Vector3(0, -1, 0)
	spray.spread = 30.0
	spray.initial_velocity_min = 0.4
	spray.initial_velocity_max = 1.4
	spray.gravity = Vector3(0, -8, 0)
	spray.color = blood_color()
	var spray_drop := SphereMesh.new()
	spray_drop.radius = 0.01
	spray_drop.height = 0.02
	var spray_mat := StandardMaterial3D.new()
	spray_mat.albedo_color = blood_color()
	spray_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spray_drop.material = spray_mat
	spray.mesh = spray_drop
	body.add_child(spray)
	spray.emitting = true
	get_tree().create_timer(2.0).timeout.connect(func(): spray.emitting = false)


func burst(at: Vector3, blocked: bool, severed: bool = false, combo_tier: int = 0) -> void:
	impact(at, blocked, severed, combo_tier)
	var off: bool = SettingsHooks.get_value("gore") == "off"
	var level: float = {"off": 0.0, "low": 0.4, "normal": 1.0, "max": 1.6}.get(
		SettingsHooks.get_value("gore"), 1.0
	)
	var effect := CPUParticles3D.new()
	effect.emitting = false
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.amount = 8 if blocked or off else int((28 if severed else 18) * level)
	effect.lifetime = 0.35 if severed else float(config["particle_lifetime"])
	effect.direction = Vector3(0, 1, 0)
	effect.spread = 45.0 if severed else 60.0
	effect.initial_velocity_min = 1.0
	effect.initial_velocity_max = 2.0 if severed else 1.8
	effect.gravity = Vector3(0, -9, 0)
	effect.color = Color("a0ddff") if blocked else Color("e3bd76") if off else blood_color()
	var drop := SphereMesh.new()
	drop.radius = 0.014 if not severed else 0.018
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
	# For sever: extra secondary burst ring
	if severed and not off and not bool(SettingsHooks.get_value("flash_reduction")):
		_sever_ring(at)


## Secondary expanding ring VFX for amputation events — Tekken-style dramatic pop
func _sever_ring(at: Vector3) -> void:
	var ring := CPUParticles3D.new()
	ring.emitting = false
	ring.one_shot = true
	ring.explosiveness = 1.0
	ring.amount = 16
	ring.lifetime = 0.55
	ring.direction = Vector3(0, 1, 0)
	ring.spread = 180.0
	ring.initial_velocity_min = 2.0
	ring.initial_velocity_max = 4.5
	ring.gravity = Vector3(0, -4, 0)
	ring.damping_min = 3.0
	ring.damping_max = 6.0
	var streak := QuadMesh.new()
	streak.size = Vector2(0.022, 0.18)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.55, 0.1)
	mat.albedo_texture = STREAK_TEXTURE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	streak.material = mat
	ring.mesh = streak
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.9, 0.3, 1))
	gradient.set_color(1, Color(1, 0.4, 0.0, 0))
	ring.color_ramp = gradient
	_register(ring, particles, int(config["particle_cap"]), 0.7)
	ring.global_position = at
	ring.emitting = true

	# Smoke trail cloud
	var smoke := CPUParticles3D.new()
	smoke.emitting = false
	smoke.one_shot = true
	smoke.explosiveness = 0.6
	smoke.amount = 12
	smoke.lifetime = 1.2
	smoke.direction = Vector3(0, 1, 0)
	smoke.spread = 60.0
	smoke.initial_velocity_min = 0.4
	smoke.initial_velocity_max = 1.2
	smoke.gravity = Vector3(0, 0.5, 0)
	var sph := QuadMesh.new()
	sph.size = Vector2(0.18, 0.18)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.albedo_color = Color(0.22, 0.24, 0.26, 0.18)
	smoke_mat.albedo_texture = load("res://assets/vfx/soft_flame.png")
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	smoke_mat.billboard_keep_scale = true
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sph.material = smoke_mat
	smoke.mesh = sph
	_register(smoke, particles, int(config["particle_cap"]), 1.4)
	smoke.global_position = at
	smoke.emitting = true


## Wall-splat burst: spawn energy hit lines radiating out from wall contact point
func wall_splat_burst(at: Vector3) -> void:
	if bool(SettingsHooks.get_value("flash_reduction")):
		return
	var burst_fx := CPUParticles3D.new()
	burst_fx.emitting = false
	burst_fx.one_shot = true
	burst_fx.explosiveness = 1.0
	burst_fx.amount = 20
	burst_fx.lifetime = 0.4
	burst_fx.direction = Vector3(0, 0, -1)
	burst_fx.spread = 75.0
	burst_fx.initial_velocity_min = 1.5
	burst_fx.initial_velocity_max = 3.5
	burst_fx.gravity = Vector3(0, -6, 0)
	var streak := QuadMesh.new()
	streak.size = Vector2(0.016, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = Color(1.0, 0.85, 0.2)
	streak.material = mat
	burst_fx.mesh = streak
	_register(burst_fx, particles, int(config["particle_cap"]), 0.5)
	burst_fx.global_position = at
	burst_fx.emitting = true
	# Wall crack decal (flat quad)
	splat(Vector3(signf(at.x) * 4.6, at.y, at.z), true)
	splat(Vector3(signf(at.x) * 4.6, at.y + 0.2, at.z), true)


func splat(at: Vector3, wall: bool) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.22, 0.18)
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


## Main impact VFX — supports combo tier escalation (0-3) for Tekken-8-style color shifts
func impact(at: Vector3, blocked: bool, severed: bool = false, combo_tier: int = 0) -> void:
	var reduced := bool(SettingsHooks.get_value("flash_reduction"))
	# Combo tier color escalation: base→orange→magenta/purple→cyan
	var color: Color
	if blocked:
		color = Color("81d8ff")
	elif severed:
		color = Color("ff5500")
	elif combo_tier >= 3:
		color = Color(0.3, 0.92, 1.0)  # Electric cyan at max combo
	elif combo_tier == 2:
		color = Color(0.88, 0.28, 0.95)  # Violet at 10+ hits
	elif combo_tier == 1:
		color = Color(1.0, 0.52, 0.12)  # Orange at 6+ hits
	else:
		color = Color("ffb24f")  # Default gold
	var effect := CPUParticles3D.new()
	effect.emitting = false
	var base_count := 48 if severed else (32 + combo_tier * 8)
	effect.amount = 12 if reduced else base_count
	effect.lifetime = 0.24 if blocked else 0.34
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.local_coords = false
	effect.direction = Vector3.UP
	effect.spread = 180.0
	effect.initial_velocity_min = 0.7
	effect.initial_velocity_max = 5.5 if severed else (3.8 + float(combo_tier) * 0.6)
	effect.gravity = Vector3(0, -3.5, 0)
	effect.angle_min = -180.0
	effect.angle_max = 180.0
	effect.damping_min = 2.0
	effect.damping_max = 4.5
	var streak := QuadMesh.new()
	streak.size = Vector2(0.009, 0.09 + float(combo_tier) * 0.012)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.vertex_color_use_as_albedo = true
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_color = color * (0.55 if reduced else 1.0)
	mat.albedo_texture = STREAK_TEXTURE
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	streak.material = mat
	effect.mesh = streak
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 0.95, 0.8, 1))
	gradient.add_point(0.25, Color(1, 0.65, 0.24, 0.8))
	gradient.set_color(1, Color(1, 1, 1, 0))
	effect.color_ramp = gradient
	_register(effect, particles, int(config["particle_cap"]), 0.65)
	effect.global_position = at
	effect.emitting = true
	# Flash disc — scale based on hit severity and combo tier
	var disc_base_size := 0.65 if severed else (0.35 + float(combo_tier) * 0.06)
	var flash := MeshInstance3D.new()
	var disc := QuadMesh.new()
	disc.size = Vector2.ONE * disc_base_size
	flash.mesh = disc
	var shader := ShaderMaterial.new()
	shader.shader = load("res://src/presentation/impact.gdshader")
	shader.set_shader_parameter("tint", color)
	var base_strength := 0.35 if reduced else (1.4 if severed else (1.0 + float(combo_tier) * 0.12))
	shader.set_shader_parameter("strength", base_strength)
	shader.set_shader_parameter("guard", blocked)
	shader.set_shader_parameter("combo_tier", combo_tier)
	shader.set_shader_parameter("sparkle", load("res://assets/vfx/exported/spark_trail.png"))
	flash.material_override = shader
	_register(flash, particles, int(config["particle_cap"]), 0.36)
	flash.global_position = at + Vector3(0, 0, 0.08)
	var expand_scale := 2.5 if severed else (2.0 + float(combo_tier) * 0.22)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * expand_scale, 0.16)
	tween.tween_method(
		func(v: float): shader.set_shader_parameter("strength", v), base_strength, 0.0, 0.16
	)
	if not reduced and not blocked:
		var haze := MeshInstance3D.new()
		var cloud := QuadMesh.new()
		cloud.size = Vector2(0.55, 0.42)
		haze.mesh = cloud
		var mist := ShaderMaterial.new()
		mist.shader = load("res://assets/shaders/impact_dust.gdshader")
		mist.set_shader_parameter(
			"smoke_atlas", load("res://assets/vfx/exported/smoke_flipbook.png")
		)
		haze.material_override = mist
		_register(haze, particles, int(config["particle_cap"]), 0.35)
		haze.global_position = at + Vector3(0, 0, 0.06)
		var dissolve := create_tween().set_parallel(true)
		dissolve.tween_property(haze, "scale", Vector3.ONE * 1.8, 0.3)
		dissolve.tween_method(func(v: float): mist.set_shader_parameter("age", v), 0.08, 0.99, 0.3)
		dissolve.tween_method(
			func(v: float): mist.set_shader_parameter("opacity", v), 0.24, 0.0, 0.3
		)
	# A brief local light binds the impact to the character materials.
	if not reduced:
		var light := OmniLight3D.new()
		light.light_color = color
		light.light_energy = 1.4 + float(combo_tier) * 0.25
		light.omni_range = 1.2
		_register(light, particles, int(config["particle_cap"]), 0.12)
		light.global_position = at + Vector3(0, 0, 0.25)
		create_tween().tween_property(light, "light_energy", 0.0, 0.1)


## Energy shockwave ring for heavy hits — Tekken-style impact emphasis
func _shockwave_ring(at: Vector3, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.01
	torus.outer_radius = 0.04
	torus.rings = 16
	torus.ring_segments = 8
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	ring.position = at + Vector3(0, 0, 0.05)
	ring.rotation.x = PI / 2
	add_child(ring)
	var ring_tween := create_tween().set_parallel(true)
	ring_tween.tween_property(ring, "scale", Vector3.ONE * 4.5, 0.22)
	ring_tween.tween_method(
		func(v: float): mat.albedo_color = Color(color.r, color.g, color.b, v), 0.7, 0.0, 0.22
	)
	ring_tween.tween_callback(ring.queue_free).set_delay(0.25)


## Escalating combo energy burst — purple/cyan plasma rings at 10+ and 15+ hit combos
func _combo_energy_burst(at: Vector3, color: Color, tier: int) -> void:
	var ring_count := 1 if tier == 2 else 2
	for i in ring_count:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.015 + float(i) * 0.01
		torus.outer_radius = 0.06 + float(i) * 0.02
		torus.rings = 20
		torus.ring_segments = 10
		ring.mesh = torus
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring.material_override = mat
		ring.position = at + Vector3(0, float(i) * 0.12, 0.04 + float(i) * 0.02)
		ring.rotation.x = PI / 2
		add_child(ring)
		var delay := float(i) * 0.06
		var ring_tween := create_tween().set_parallel(true)
		(
			ring_tween
			. tween_property(ring, "scale", Vector3.ONE * (5.5 + float(tier) * 0.8), 0.28)
			. set_delay(delay)
		)
		(
			ring_tween
			. tween_method(
				func(v: float): mat.albedo_color = Color(color.r, color.g, color.b, v),
				0.8,
				0.0,
				0.28
			)
			. set_delay(delay)
		)
		ring_tween.tween_callback(ring.queue_free).set_delay(delay + 0.32)

	# Combo label flash pulse — concentric double-ring pop
	if tier >= 3 and not bool(SettingsHooks.get_value("flash_reduction")):
		var outer := CPUParticles3D.new()
		outer.emitting = false
		outer.one_shot = true
		outer.explosiveness = 1.0
		outer.amount = 24
		outer.lifetime = 0.5
		outer.direction = Vector3.ZERO
		outer.spread = 180.0
		outer.initial_velocity_min = 3.5
		outer.initial_velocity_max = 7.0
		outer.gravity = Vector3(0, -2, 0)
		outer.damping_min = 4.0
		outer.damping_max = 8.0
		var streak := QuadMesh.new()
		streak.size = Vector2(0.018, 0.22)
		var mat2 := StandardMaterial3D.new()
		mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat2.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		mat2.albedo_color = color
		streak.material = mat2
		outer.mesh = streak
		_register(outer, particles, int(config["particle_cap"]), 0.6)
		outer.global_position = at
		outer.emitting = true


func ooze(at: Vector3) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var effect := CPUParticles3D.new()
	effect.emitting = false
	effect.amount = 4
	effect.lifetime = 0.75
	effect.one_shot = true
	effect.explosiveness = 0.25
	effect.local_coords = false
	effect.direction = Vector3.DOWN
	effect.spread = 12.0
	effect.initial_velocity_min = 0.1
	effect.initial_velocity_max = 0.35
	effect.gravity = Vector3(0, -5, 0)
	var drop := SphereMesh.new()
	drop.radius = 0.01
	drop.height = 0.035
	var mat := StandardMaterial3D.new()
	mat.albedo_color = blood_color()
	mat.roughness = 0.2
	drop.material = mat
	effect.mesh = drop
	_register(effect, particles, int(config["particle_cap"]), 0.9)
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
	# Warmer, more vivid orange-amber trail for a Tekken-style energy look
	mat.albedo_color = Color(1.0, 0.65, 0.15, 0.42)
	mat.albedo_texture = load("res://assets/vfx/exported/smoke_trail.png")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var width := Vector3.UP * 0.035
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [from - width, from + width, to + width, from - width, to + width, to - width]
	var uvs := [
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)
	]
	for index in points.size():
		ribbon.surface_set_uv(uvs[index])
		ribbon.surface_add_vertex(points[index])
	ribbon.surface_end()
	mesh.mesh = ribbon
	mesh.material_override = mat
	_register(mesh, particles, int(config["particle_cap"]), 0.14)


func detached_limb(pieces: Array, joint: Vector3, direction: float) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var body := RigidBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 2
	body.mass = 2.5
	body.linear_damp = 0.7
	body.angular_damp = 1.2
	body.physics_material_override = PhysicsMaterial.new()
	body.physics_material_override.bounce = 0.15
	body.physics_material_override.friction = 0.85
	var bounds := AABB()
	var first := true
	for source: MeshInstance3D in pieces:
		if str(source.name).begins_with("SEAM_"):
			continue
		var posed := LimbFinish.posed_mesh(source)
		var visual := MeshInstance3D.new()
		visual.mesh = posed if posed != null else source.mesh
		visual.transform = Transform3D(Basis.IDENTITY, -joint) * source.global_transform
		body.add_child(visual)
		for surface in visual.mesh.get_surface_count():
			visual.set_surface_override_material(surface, source.get_active_material(surface))
		var box := visual.transform * visual.mesh.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	if first:
		body.free()
		return
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = bounds.size.max(Vector3.ONE * 0.04)
	collision.shape = shape
	collision.position = bounds.get_center()
	body.add_child(collision)
	_register(body, chunks, int(config["chunk_cap"]), 12.0)
	body.global_position = joint
	body.linear_velocity = Vector3(direction * 1.6, 2.4, 0.35)
	body.angular_velocity = Vector3(1.8, 0.6, direction * 3.2)
	# A short outward spray stays at the exposed joint while the limb falls.
	var spray := CPUParticles3D.new()
	spray.amount = 36
	spray.one_shot = true
	spray.explosiveness = 0.7
	spray.lifetime = 0.65
	spray.direction = Vector3(direction, 0.3, 0.1)
	spray.spread = 18
	spray.initial_velocity_min = 1.2
	spray.initial_velocity_max = 2.5
	spray.gravity = Vector3(0, -6, 0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.065)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = load("res://assets/vfx/blood_drop.png")
	mat.albedo_color = blood_color()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	quad.material = mat
	spray.mesh = quad
	_register(spray, particles, int(config["particle_cap"]), 0.9)
	spray.global_position = joint
	spray.emitting = true
