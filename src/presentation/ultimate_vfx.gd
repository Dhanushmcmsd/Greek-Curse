extends Node3D
## Bounded, event-driven artwork. Geometry is built once; no per-frame mesh rebuilds.

const BOLT = preload("res://assets/shaders/ultimate_lightning.gdshader")
const SIGIL = preload("res://assets/shaders/ultimate_sigil.gdshader")
const ART = preload("res://assets/shaders/combat_art.gdshader")
const FLARE = preload("res://assets/vfx/exported/impact_flare.png")
const RING = preload("res://assets/vfx/exported/impact_ring.png")
var elapsed: float = 0.0
var lifetime: float = 1.15
var materials: Array[ShaderMaterial] = []
var ring_nodes: Array[Node3D] = []
var light: OmniLight3D
var charge: bool = false


func configure(fighter_id: String, charging: bool = false, blocked: bool = false) -> void:
	charge = charging
	lifetime = 0.8 if charge else 1.15
	add_to_group("ultimate_vfx")
	var active := get_tree().get_nodes_in_group("ultimate_vfx").filter(func(node: Node) -> bool: return not node.is_queued_for_deletion())
	if active.size() > 6:
		active[0].queue_free()
	var color := GoreManager.palette(fighter_id)
	var style: Array = {
		"theron": [3, 0.35, 4.0], "atalanta": [1, 0.22, 7.0],
		"pyrrhus": [5, 0.65, 3.0], "sibyl": [2, 0.5, 8.0], "dorian": [3, 0.22, 5.0]
	}.get(fighter_id, [3, 0.35, 6.0])
	var reduced := bool(SettingsHooks.get_value("flash_reduction"))
	var strength := 0.28 if reduced else 0.8
	if blocked:
		strength *= 0.45
	var sigil := ShaderMaterial.new()
	sigil.shader = SIGIL
	sigil.set_shader_parameter("tint", color)
	sigil.set_shader_parameter("sides", style[2])
	sigil.set_shader_parameter("intensity", strength)
	var floor_ring := _quad(Vector2.ONE * (2.6 if charge else 3.6), sigil, Vector3(0, 0.045, 0))
	floor_ring.rotation.x = -PI / 2.0
	ring_nodes.append(floor_ring)
	if charge:
		return
	var ribbon := ImmediateMesh.new()
	ribbon.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(fighter_id)
	for strand in int(style[0]):
		var points: Array[Vector3] = []
		for step in 25:
			var t := float(step) / 24.0
			var spread := float(style[1]) * (0.3 + sin(t * PI))
			var fan := (float(strand) - float(style[0] - 1) * 0.5) * (1.0 - t) * 0.65
			points.append(Vector3(rng.randf_range(-spread, spread) + fan, 7.5 * (1.0 - t), 0.03 * strand))
		points[-1] = Vector3.ZERO
		for segment in points.size() - 1:
			_ribbon(ribbon, points[segment], points[segment + 1], 0.20 if strand == 0 else 0.10)
			if segment % 5 == 2:
				var tip := points[segment] + Vector3(rng.randf_range(-1.1, 1.1), -0.6, 0)
				var bend := points[segment].lerp(tip, 0.5) + Vector3(0.1, 0.12, 0)
				_ribbon(ribbon, points[segment], bend, 0.04)
				_ribbon(ribbon, bend, tip, 0.025)
	# Radial crackle and airborne filaments share the bolt's single draw call.
	for spark in 24:
		var angle := rng.randf_range(0, TAU)
		var start := Vector3(cos(angle), absf(sin(angle)) * 0.7, sin(angle) * 0.25) * rng.randf_range(0.2, 0.8)
		_ribbon(ribbon, start, start * rng.randf_range(1.4, 2.1), 0.025)
	ribbon.surface_end()
	var bolt := MeshInstance3D.new()
	bolt.mesh = ribbon
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bolt_mat := ShaderMaterial.new()
	bolt_mat.shader = BOLT
	bolt_mat.set_shader_parameter("tint", color)
	bolt_mat.set_shader_parameter("intensity", strength)
	bolt.material_override = bolt_mat
	materials.append(bolt_mat)
	add_child(bolt)
	for layer in 2:
		var art := ShaderMaterial.new()
		art.shader = ART
		art.set_shader_parameter("artwork", FLARE if layer == 0 else RING)
		art.set_shader_parameter("layer", layer)
		art.set_shader_parameter("tint", color)
		art.set_shader_parameter("opacity", strength * 0.7)
		var node := _quad(Vector2.ONE * (1.6 if layer == 0 else 2.5), art, Vector3(0, 0.9, 0.15))
		var camera := get_viewport().get_camera_3d()
		if camera != null:
			node.global_basis = camera.global_basis
		ring_nodes.append(node)
	if not reduced:
		light = OmniLight3D.new()
		light.light_color = color
		light.omni_range = 4.0
		light.light_energy = 2.0
		light.shadow_enabled = false
		light.position.y = 1.2
		add_child(light)


func _quad(size: Vector2, material: ShaderMaterial, at: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = at
	add_child(node)
	materials.append(material)
	return node


func _ribbon(mesh: ImmediateMesh, a: Vector3, b: Vector3, width: float) -> void:
	var tangent := (b - a).normalized()
	var side := Vector3(tangent.y, -tangent.x, 0) * width
	var points := [a - side, a + side, b + side, a - side, b + side, b - side]
	var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]
	for i in 6:
		mesh.surface_set_uv(uv[i])
		mesh.surface_add_vertex(points[i])


func _process(delta: float) -> void:
	elapsed += delta
	var age := clampf(elapsed / lifetime, 0.0, 1.0)
	for material in materials:
		material.set_shader_parameter("age", age)
	for node in ring_nodes:
		node.scale = Vector3.ONE * (lerpf(0.6, 1.0, age) if charge else lerpf(0.75, 1.5, sqrt(age)))
	if light != null:
		light.light_energy = 2.0 * exp(-elapsed * 12.0)
	if elapsed >= lifetime:
		queue_free()
