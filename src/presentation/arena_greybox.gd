class_name ArenaGreybox
extends Node3D
## Floor, two walls, and a flat light. No gameplay.
var arena_id: String = "mount_olympus"


func _ready() -> void:
	var path := "res://assets/generated/models/arena_%s.glb" % arena_id
	add_child((load(path) as PackedScene).instantiate())
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
