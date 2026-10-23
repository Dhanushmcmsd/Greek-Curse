class_name ArenaGreybox
extends Node3D
## Floor, two walls, and a flat light. No gameplay.


func _ready() -> void:
	_box(Vector3(0.0, -0.1, 0.0), Vector3(10.0, 0.2, 4.0), Color(0.45, 0.42, 0.38))
	_box(Vector3(-4.7, 1.0, 0.0), Vector3(0.3, 2.0, 4.0), Color(0.32, 0.34, 0.38))
	_box(Vector3(4.7, 1.0, 0.0), Vector3(0.3, 2.0, 4.0), Color(0.32, 0.34, 0.38))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48.0, 30.0, 0.0)
	add_child(light)
	var sky := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.7, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.75, 0.75)
	environment.ambient_light_energy = 1.0
	sky.environment = environment
	add_child(sky)


func _box(at: Vector3, size: Vector3, color: Color) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	add_child(mesh)
