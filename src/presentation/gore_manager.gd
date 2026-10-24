class_name GoreManager
extends Node3D
## Bounded cosmetic physics, never queried by the deterministic simulation.

var config: Dictionary
var chunks: Array[Node] = []
var floor_splats: Array[Node] = []
var wall_splats: Array[Node] = []
var particles: Array[Node] = []
var chunk_models: Array[Node3D] = []
var arena_id: String = "mount_olympus"


func _ready() -> void:
	add_to_group("gore_manager")
	config = DataLoader.new().load_json("res://data/art/vfx.json").value
	for index in 15:
		var loaded := (
			ModelLoader.load_model("res://assets/generated/models/gore_%02d.glb" % index).root
		)
		loaded.hide()
		add_child(loaded)
		chunk_models.append(loaded)
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
			if node is MeshInstance3D and node.material_override != null:
				node.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				node.material_override.albedo_color.a = clampf(float(remaining) / 1500.0, 0.0, 1.0)
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
	var box := mesh.mesh.get_aabb()
	var center := box.get_center()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh.mesh
	visual.position = -center
	for surface in mesh.mesh.get_surface_count():
		visual.set_surface_override_material(surface, mesh.get_active_material(surface))
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size.max(Vector3.ONE * 0.03)
	collision.shape = shape
	body.add_child(collision)
	_register(body, chunks, int(config["chunk_cap"]), float(config["chunk_lifetime"]))
	body.global_transform = Transform3D(pose.basis.orthonormalized(), pose * center)
	body.linear_velocity = Vector3(direction * 2.8, 3.4, 0.9)
	body.angular_velocity = Vector3(4.0, 2.0 * direction, 5.0)


func burst(at: Vector3, blocked: bool, severed: bool = false) -> void:
	var off: bool = SettingsHooks.get_value("gore") == "off"
	var level: float = {"off": 0.0, "low": 0.4, "normal": 1.0, "max": 1.6}.get(
		SettingsHooks.get_value("gore"), 1.0
	)
	var effect := CPUParticles3D.new()
	effect.one_shot = true
	effect.explosiveness = 1.0
	effect.amount = 12 if blocked or off else int((70 if severed else 18) * level)
	effect.lifetime = float(config["particle_lifetime"])
	effect.direction = Vector3(0, 1, 0)
	effect.spread = 75
	effect.initial_velocity_min = 1.0
	effect.initial_velocity_max = 4.0 if severed else 2.0
	effect.gravity = Vector3(0, -9, 0)
	effect.color = Color("a0ddff") if blocked else Color("e3bd76") if off else blood_color()
	var drop := SphereMesh.new()
	drop.radius = 0.016 if not severed else 0.025
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
	if severed and not off:
		for index in int(5 * level):
			var model := chunk_models[index % chunk_models.size()]
			var piece := (
				model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
			)
			debris(piece, Transform3D(Basis.IDENTITY, at), -1.0 if index % 2 else 1.0)
	if severed or blocked:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.16
		torus.outer_radius = 0.19
		ring.mesh = torus
		ring.material_override = material
		ring.rotation.x = PI / 2
		_register(ring, particles, int(config["particle_cap"]), 0.3)
		ring.global_position = at
		create_tween().tween_property(ring, "scale", Vector3.ONE * (4.5 if severed else 2.2), 0.25)


func splat(at: Vector3, wall: bool) -> void:
	if SettingsHooks.get_value("gore") == "off":
		return
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.38, 0.3)
	mesh.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = blood_color()
	material.roughness = 0.55
	mesh.material_override = material
	_register(
		mesh,
		wall_splats if wall else floor_splats,
		int(config["wall_cap"] if wall else config["floor_cap"]),
		8.0 if arena_id == "athens_colosseum" else 20.0
	)
	mesh.global_position = at
	if wall:
		mesh.rotation.z = PI / 2
